package Lugh::Train;

use 5.030;
use strict;
use warnings;
use Carp qw(croak);
use Lugh;

our $VERSION = '0.12';

=head1 NAME

Lugh::Train - High-level training API for Lugh

=head1 SYNOPSIS

    use Lugh;
    use Lugh::Train;
    use Lugh::Autograd;

    # Create a training context
    my $ctx = Lugh::Context->new(mem_size => 256 * 1024 * 1024);

    # Compute cross-entropy loss
    my $logits = Lugh::Autograd::Tensor->new($ctx, 'f32', 5, { requires_grad => 1 });
    $logits->set_data(1.0, 2.0, 3.0, 4.0, 5.0);
    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, [4]);  # target class 4

    # Backward pass
    $loss->backward();

    # Get gradients
    my $grad = $logits->grad();  # Returns array reference

    # MSE loss for regression
    my $predictions = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $predictions->set_data(1.0, 2.0, 3.0);
    my $targets = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 0 });
    $targets->set_data(1.1, 1.9, 3.2);
    my $mse = Lugh::Train->mse_loss($ctx, $predictions, $targets);
    $mse->backward();

=head1 DESCRIPTION

Lugh::Train provides high-level training utilities for neural network training:

=over 4

=item * Loss functions (cross-entropy, MSE)

=item * Training-aware forward pass with gradient support

=item * Data loading and batching

=item * Training loop helpers

=back

All methods are implemented in XS for performance and are automatically loaded
when C<use Lugh;> is called.

=head1 FORWARD PASS

=head2 forward

    my $logits = Lugh::Train->forward(
        inference  => $inference,
        context    => $ctx,
        tokens     => \@tokens,
        lora       => $lora,       # Optional: LoRA adapter
        train_lora => 1,           # Default 1: compute LoRA gradients
        train_full => 0,           # Enable full model gradient computation
    );

Performs a training-aware forward pass that stores intermediate activations
for gradient computation. Returns logits as a L<Lugh::Autograd::Tensor>
suitable for loss computation and backpropagation.

B<Arguments:>

=over 4

=item C<inference> - L<Lugh::Inference> object (or C<model> as alias)

=item C<context> - L<Lugh::Context> object (or C<ctx> as alias)

=item C<tokens> - Array reference of input token IDs

=item C<lora> - Optional L<Lugh::LoRA> adapter for LoRA training

=item C<train_lora> - Boolean, compute gradients for LoRA weights (default: 1)

=item C<train_full> - Boolean, compute gradients for full model weights (default: 0)

=back

B<Returns:> L<Lugh::Autograd::Tensor> containing logits of shape [vocab_size, n_tokens].

B<Example:>

    my $model = Lugh::Model->new(model => 'model.gguf');
    my $inference = Lugh::Inference->new(model => $model);
    my $ctx = Lugh::Context->new(mem_size => 32 * 1024 * 1024);

    my @tokens = (1, 72, 101, 108, 108, 111);  # "Hello"
    my @target = @tokens[1..$#tokens];         # Shifted targets
    my @input = @tokens[0..$#tokens-1];

    my $logits = Lugh::Train->forward(
        inference => $inference,
        context   => $ctx,
        tokens    => \@input,
    );

    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, \@target);
    $loss->backward();

=head2 register_weight_tensors

    Lugh::Train->register_weight_tensors($logits, \@weights);

Registers weight tensors with the training cache for gradient computation.
This connects trainable weights (from a model or LoRA adapter) to the
forward pass output, enabling gradients to flow to these weights during
backpropagation.

B<Arguments:>

=over 4

=item C<$logits> - The logits tensor returned from C<forward()>

=item C<\@weights> - Array reference of L<Lugh::Autograd::Tensor> weight tensors

=back

B<Example:>

    # Get trainable weights from model
    my $weights_hash = $model->get_trainable_weights($ctx);
    my @weights = values %$weights_hash;

    my $logits = Lugh::Train->forward(
        inference  => $inference,
        context    => $ctx,
        tokens     => \@tokens,
        train_full => 1,
    );

    # Register weights for gradient computation
    Lugh::Train->register_weight_tensors($logits, \@weights);

    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, \@targets);
    $loss->backward();

    # Weights now have gradients
    for my $w (@weights) {
        my $grad = $w->grad();
        # ... use gradients for optimization
    }

=head1 LOSS FUNCTIONS

=head2 cross_entropy_loss

    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, \@targets);

Computes cross-entropy loss between logits and target class indices.

B<Arguments:>

=over 4

=item C<$ctx> - Lugh::Context object

=item C<$logits> - Lugh::Autograd::Tensor of shape [vocab_size, batch_size] or [vocab_size]

=item C<\@targets> - Array reference of target class indices (integers)

=back

B<Returns:> Scalar loss tensor with C<requires_grad> if logits requires grad.

The loss is computed as the negative log-likelihood of the target class after
applying log-softmax to the logits. This is numerically stable and equivalent to:

    loss = -log(softmax(logits)[target_class])

=head2 mse_loss

    my $loss = Lugh::Train->mse_loss($ctx, $predictions, $targets);

Computes Mean Squared Error loss between predictions and targets.

B<Arguments:>

=over 4

=item C<$ctx> - Lugh::Context object  

=item C<$predictions> - Lugh::Autograd::Tensor

=item C<$targets> - Lugh::Autograd::Tensor (same shape as predictions)

=back

B<Returns:> Scalar loss tensor with C<requires_grad> if predictions requires grad.

The loss is computed as:

    loss = mean((predictions - targets)^2)

=head1 DATA UTILITIES

=head2 batch_data

    my @batches = Lugh::Train->batch_data(\@data, batch_size => 32, shuffle => 1);

Split data into batches for training.

B<Arguments:>

=over 4

=item C<\@data> - Array reference of training examples

=item C<batch_size> - Number of examples per batch (default: 32)

=item C<shuffle> - Whether to shuffle before batching (default: 0)

=back

B<Returns:> List of array references, each containing batch_size examples.

=head2 tokenize_batch

    my ($input_ids, $targets) = Lugh::Train->tokenize_batch($tokenizer, \@texts, max_length => 512);

Tokenize a batch of texts for language model training.

B<Arguments:>

=over 4

=item C<$tokenizer> - Lugh::Tokenizer object

=item C<\@texts> - Array reference of text strings

=item C<max_length> - Maximum sequence length (default: 512)

=back

B<Returns:> Two array refs: input token IDs and target token IDs (shifted by 1).

=head1 TRAINING HELPERS

=head2 training_step

    my $loss = Lugh::Train->training_step($model, $optimizer, $inputs, $targets, %opts);

Perform a single training step: forward pass, loss computation, backward pass,
and optimizer update.

B<Arguments:>

=over 4

=item C<$model> - Model with forward() method

=item C<$optimizer> - Optimizer (Lugh::Optimizer::SGD or Adam)

=item C<$inputs> - Input tensor or batch

=item C<$targets> - Target tensor or batch

=item C<%opts> - Options including C<loss_fn> (default: 'cross_entropy'), C<ctx> (required)

=back

B<Returns:> Scalar loss value.

=head2 zero_grad

    Lugh::Train->zero_grad(@tensors);

Zero out gradients for all given tensors. This is a convenience method that
calls C<zero_grad()> on each tensor that supports it.

B<Arguments:>

=over 4

=item C<@tensors> - List of L<Lugh::Autograd::Tensor> objects to zero gradients

=back

B<Example:>

    # Zero gradients before each training iteration
    Lugh::Train->zero_grad($weight1, $weight2, $bias);

=head1 EXAMPLE: TRAINING LOOP

Here's a complete example of training a model from scratch to memorize
simple patterns:

    use Lugh;
    use Lugh::Train;
    use Lugh::Optimizer;

    # Load or create model
    my $model = Lugh::Model->new(model => 'model.gguf');
    my $inference = Lugh::Inference->new(model => $model);

    # Get trainable weights
    my $weight_ctx = Lugh::Context->new(mem_size => 512 * 1024 * 1024);
    my $weights_hash = $model->get_trainable_weights($weight_ctx);
    delete $weights_hash->{_n_tensors};
    delete $weights_hash->{_model_id};
    my @weights = values %$weights_hash;

    # Create optimizer
    my $optimizer = Lugh::Optimizer::AdamW->new(lr => 0.01, weight_decay => 0.0);
    $optimizer->add_param($_) for @weights;

    # Training data
    my @texts = ("Hello", "World", "Test");

    # Tokenization helper
    sub tokenize { return (1, map { ord($_) } split //, $_[0]) }

    # Training loop
    for my $epoch (1..1000) {
        for my $text (@texts) {
            my @tokens = tokenize($text);
            my @input = @tokens[0..$#tokens-1];
            my @target = @tokens[1..$#tokens];

            my $ctx = Lugh::Context->new(mem_size => 32 * 1024 * 1024);
            $optimizer->zero_grad();

            # Forward pass
            my $logits = Lugh::Train->forward(
                inference  => $inference,
                context    => $ctx,
                tokens     => \@input,
                train_lora => 0,
                train_full => 1,
            );

            # Register weights for gradient computation
            Lugh::Train->register_weight_tensors($logits, \@weights);

            # Compute loss
            my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, \@target);
            my ($loss_val) = $loss->get_data();

            # Backward pass and optimization
            $loss->backward();
            $optimizer->step();

            if ($epoch % 100 == 0) {
                printf "Epoch %d: loss=%.4f\n", $epoch, $loss_val;
            }
        }
    }

=head1 EXAMPLE: LORA TRAINING

Training with LoRA (Low-Rank Adaptation) for efficient fine-tuning:

    use Lugh;
    use Lugh::Train;
    use Lugh::Optimizer;

    # Load base model
    my $model = Lugh::Model->new(model => 'base-model.gguf');
    my $inference = Lugh::Inference->new(model => $model);

    # Create trainable LoRA adapter
    my $lora = Lugh::LoRA->create(
        model   => $model,
        rank    => 8,
        alpha   => 16.0,
        targets => [qw(attn_q attn_v)],
    );

    # Get LoRA weight tensors
    my @weight_names = $lora->weight_names;
    my @weights;
    for my $name (@weight_names) {
        push @weights, $lora->get_weight_tensor($name, 'a');
        push @weights, $lora->get_weight_tensor($name, 'b');
    }

    # Create optimizer
    my $optimizer = Lugh::Optimizer::AdamW->new(lr => 0.001);
    $optimizer->add_param($_) for @weights;

    # Training loop
    for my $epoch (1..100) {
        my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
        $optimizer->zero_grad();

        my $logits = Lugh::Train->forward(
            inference  => $inference,
            context    => $ctx,
            tokens     => \@input_tokens,
            lora       => $lora,
            train_lora => 1,
        );

        my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, \@targets);
        $loss->backward();
        $optimizer->step();
    }

    # Save trained adapter
    $lora->save('my-trained-lora.gguf');

=head1 SEE ALSO

=over 4

=item * L<Lugh::Autograd> - Automatic differentiation

=item * L<Lugh::Autograd::Tensor> - Tensors with gradient tracking

=item * L<Lugh::Autograd::Ops> - Differentiable operations

=item * L<Lugh::LoRA> - Low-Rank Adaptation for efficient fine-tuning

=item * L<Lugh::Optimizer> - Optimization algorithms (AdamW, SGD)

=item * L<Lugh::Model> - Model loading and weight access

=item * L<Lugh::Inference> - Forward pass for inference

=back

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
