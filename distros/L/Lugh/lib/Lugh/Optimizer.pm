package Lugh::Optimizer;

use 5.030;
use strict;
use warnings;
use Lugh;

our $VERSION = '0.12';

# All optimizer implementations are in XS (Lugh.xs):
# - Lugh::Optimizer::SGD
# - Lugh::Optimizer::AdamW
# - Lugh::Optimizer::LRScheduler
# - Lugh::Optimizer (clip_grad_norm, clip_grad_value)

=head1 NAME

Lugh::Optimizer - Optimization algorithms for Lugh training

=head1 SYNOPSIS

    use Lugh;
    use Lugh::Optimizer;
    use Lugh::Autograd;

    # Create a context and tensor
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    my $weights = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, { requires_grad => 1 });
    $weights->set_data(0.5, 0.5);
    
    # SGD optimizer
    my $sgd = Lugh::Optimizer::SGD->new(
        lr       => 0.01,
        momentum => 0.9,
    );
    $sgd->add_param($weights);
    
    # Training loop
    for my $i (1..100) {
        $sgd->zero_grad();
        
        # ... compute loss and backward ...
        
        $sgd->step();
    }
    
    # AdamW optimizer (recommended for transformers)
    my $adamw = Lugh::Optimizer::AdamW->new(
        lr           => 1e-4,
        weight_decay => 0.01,
    );
    
    # Learning rate scheduler
    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $adamw,
        schedule     => 'cosine',
        warmup_steps => 100,
        total_steps  => 1000,
    );

=head1 DESCRIPTION

Lugh::Optimizer provides optimization algorithms for training neural networks.
All implementations are in XS for maximum performance.

=head1 OPTIMIZERS

=head2 Lugh::Optimizer::SGD

Stochastic Gradient Descent with momentum and optional Nesterov acceleration.

    my $sgd = Lugh::Optimizer::SGD->new(
        lr           => 0.01,     # Learning rate (default: 0.001)
        momentum     => 0.9,      # Momentum factor (default: 0)
        weight_decay => 0.0001,   # L2 regularization (default: 0)
        nesterov     => 1,        # Use Nesterov momentum (default: 0)
    );

=head3 Methods

=over 4

=item C<add_param($tensor)>

Add a tensor to be optimized.

=item C<step()>

Perform a single optimization step, updating all parameters.

=item C<zero_grad()>

Zero out gradients for all parameters.

=item C<get_lr()>

Get the current learning rate.

=item C<set_lr($new_lr)>

Set a new learning rate.

=back

=head2 Lugh::Optimizer::AdamW

Adam optimizer with decoupled weight decay (AdamW). Recommended for transformer models.

    my $adamw = Lugh::Optimizer::AdamW->new(
        lr           => 1e-4,    # Learning rate (default: 0.001)
        beta1        => 0.9,     # First moment decay (default: 0.9)
        beta2        => 0.999,   # Second moment decay (default: 0.999)
        eps          => 1e-8,    # Numerical stability (default: 1e-8)
        weight_decay => 0.01,    # Decoupled weight decay (default: 0.01)
    );

=head3 Methods

Same as SGD, plus:

=over 4

=item C<get_step_count()>

Get the current optimization step count (for bias correction).

=back

=head3 AdamW vs Adam

AdamW applies weight decay directly to the weights (decoupled), rather than
adding L2 regularization to the gradient. This leads to better generalization
for large language models.

=head1 LEARNING RATE SCHEDULERS

=head2 Lugh::Optimizer::LRScheduler

Adjusts learning rate during training according to a schedule.

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'cosine',   # Schedule type
        warmup_steps => 100,        # Warmup period
        total_steps  => 1000,       # Total training steps
        min_lr       => 0,          # Minimum learning rate
    );

=head3 Schedule Types

=over 4

=item C<constant>

Learning rate stays constant throughout training.

=item C<linear>

Linear warmup then linear decay to min_lr.

=item C<cosine>

Linear warmup then cosine annealing to min_lr. Popular for LLM training.

=item C<exponential>

Exponential decay: C<lr = initial_lr * decay_rate^step>

=item C<step>

Decay at specific milestones:

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule   => 'step',
        milestones => [30, 60, 90],  # Decay at these steps
        decay_rate => 0.1,           # Multiply by this at each milestone
    );

=item C<warmup>

Linear warmup then constant.

=back

=head3 Methods

=over 4

=item C<step()>

Update the learning rate. Call once per training step.

=item C<get_lr()>

Get the current learning rate.

=item C<get_step()>

Get the current step count.

=back

=head1 GRADIENT CLIPPING

=head2 clip_grad_norm

Clip gradients by total norm.

    my $total_norm = Lugh::Optimizer->clip_grad_norm(1.0, @tensors);

Scales all gradients so the total L2 norm does not exceed C<max_norm>.
Returns the original total norm before clipping.

=head2 clip_grad_value

Clip gradients by value.

    Lugh::Optimizer->clip_grad_value(1.0, @tensors);

Clamps all gradient values to C<[-max_value, max_value]>.

=head1 EXAMPLE: COMPLETE TRAINING LOOP

    use Lugh;
    use Lugh::Train;
    use Lugh::Optimizer;

    # Load model and create inference engine
    my $model = Lugh::Model->new(model => 'model.gguf');
    my $inference = Lugh::Inference->new(model => $model);

    # Create trainable LoRA adapter
    my $lora = Lugh::LoRA->create(
        model   => $model,
        rank    => 8,
        alpha   => 16.0,
        targets => [qw(attn_q attn_v)],
    );

    # Get LoRA weight tensors
    my @params;
    for my $name ($lora->weight_names) {
        push @params, $lora->get_weight_tensor($name, 'a');
        push @params, $lora->get_weight_tensor($name, 'b');
    }

    # Create optimizer
    my $optimizer = Lugh::Optimizer::AdamW->new(
        lr           => 1e-4,
        weight_decay => 0.01,
    );
    $optimizer->add_param($_) for @params;

    # Create scheduler
    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'cosine',
        warmup_steps => 100,
        total_steps  => 1000,
        min_lr       => 1e-6,
    );

    # Training loop
    for my $step (1..1000) {
        my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
        $optimizer->zero_grad();

        # Forward pass with LoRA
        my $logits = Lugh::Train->forward(
            inference  => $inference,
            context    => $ctx,
            tokens     => \@input_tokens,
            lora       => $lora,
            train_lora => 1,
        );

        my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, \@targets);

        # Backward pass
        $loss->backward();

        # Gradient clipping (prevent exploding gradients)
        my $grad_norm = Lugh::Optimizer->clip_grad_norm(1.0, @params);

        # Optimizer step
        $optimizer->step();

        # Learning rate schedule
        $scheduler->step();

        # Log progress
        if ($step % 100 == 0) {
            my $lr = $scheduler->get_lr();
            my ($loss_val) = $loss->get_data();
            printf "Step %d: loss=%.4f, lr=%.2e, grad_norm=%.2f\n",
                   $step, $loss_val, $lr, $grad_norm;
        }
    }

    # Save trained adapter
    $lora->save('trained_adapter.gguf');

=head1 SEE ALSO

=over 4

=item * L<Lugh::Train> - Training API with loss functions

=item * L<Lugh::Autograd> - Automatic differentiation

=item * L<Lugh::Autograd::Tensor> - Tensors with gradient tracking

=item * L<Lugh::LoRA> - Low-Rank Adaptation for efficient fine-tuning

=back

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
