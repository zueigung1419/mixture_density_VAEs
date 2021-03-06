using MNIST

include("utils/optimizers.jl")
include("models/gaussMMVAE.jl")

function elbo(params, x, prior)
  # prop through autoencoder
  x_recon, posterior, z = fprop(params, x)

  # likelihood term
  expected_nll = sum(-x .* log(x_recon) - (1-x) .* log(1-x_recon), 2)

  # kl divergence term
  kld = computeKLD(prior, posterior, z)

  return mean(expected_nll + kld)
end

function trainVAE(data, params, hyperParams)
  N,d = size(data)
  nBatches = div(N,hyperParams["batchSize"])

  for epoch_idx in 1:hyperParams["nEpochs"]
    elbo_tracker = 0.
    for batch_idx in 1:nBatches

      # get minibatch
      x = data[(batch_idx-1)*hyperParams["batchSize"]+1:batch_idx*hyperParams["batchSize"],:]

      # compute elbo
      elbo_tracker += elbo(params, x, hyperParams["prior"])

      # get elbo gradients
      #grads = elbo_grad(params, x, hyperParams["prior"])

      # perform AdaM update
      #params = adamUpdate(params, grads, hyperParams["adamParams"])

    end
    @printf "Epoch %d. Neg. ELBO: %.3f \n" epoch_idx elbo_tracker/nBatches
  end

  return params
end

function main()
  # load MNIST (values in [0,255])
  data = transpose(traindata()[1])

  # shuffle, normalized, and reduce dataset
  shuffle(vec(data))
  data /= 255
  data = data[1:50000,:]

  # set architecture parameters
  hidden_size = 500
  latent_size = 25
  n_components = 2
  vae_params = init_params(size(data,2), hidden_size, latent_size, n_components)

  # set hyperparams
  adamParams = Dict("lr"=>0.0001, "m"=>init_params(size(data,2), hidden_size, latent_size, n_components, 0.),
                    "v"=>init_params(size(data,2), hidden_size, latent_size, n_components, 0.), "t"=>0)
  hyperParams = Dict("adamParams"=>adamParams, "prior"=>Dict("weights"=>transpose([.5, .5]), "mu"=>[-2., 2.], "sigma"=>[1., 1.]), "nEpochs"=>50, "batchSize"=>100)

  final_vae_params = trainVAE(data, vae_params, hyperParams)
end

main()
