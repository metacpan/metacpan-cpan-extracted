package Lugh::Optimizer::AdamW;

use strict;
use warnings;

our $VERSION = '0.12';

# XS methods are loaded via Lugh.xs
# This module provides documentation only

1;

__END__

=head1 NAME

Lugh::Optimizer::AdamW - Adam optimizer with decoupled weight decay

=head1 SYNOPSIS

    use Lugh;
    use Lugh::Autograd;

    # Create context and parameter tensors
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    my $weights = Lugh::Autograd::Tensor->new($ctx, 'f32', 768, 768, {
        requires_grad => 1,
    });

    # Create AdamW optimizer (recommended for transformers)
    my $optimizer = Lugh::Optimizer::AdamW->new(
        lr           => 1e-4,
        weight_decay => 0.01,
    );

    # Register parameters
    $optimizer->add_param($weights);

    # Training loop
    for my $step (1..10000) {
        $optimizer->zero_grad();

        my $loss = compute_loss($weights, $batch);
        $loss->backward();

        $optimizer->step();
    }

=head1 DESCRIPTION

C<Lugh::Optimizer::AdamW> implements the Adam optimizer with decoupled
weight decay regularization, as described in "Decoupled Weight Decay
Regularization" (Loshchilov & Hutter, 2017).

AdamW is the recommended optimizer for training transformer models
including LLaMA, GPT, and BERT variants. It maintains per-parameter
adaptive learning rates using first and second moment estimates.

The update rule is:

    m_t = beta1 * m_{t-1} + (1 - beta1) * gradient
    v_t = beta2 * v_{t-1} + (1 - beta2) * gradient^2

    m_hat = m_t / (1 - beta1^t)  # Bias correction
    v_hat = v_t / (1 - beta2^t)

    param = param - lr * (m_hat / (sqrt(v_hat) + eps) + weight_decay * param)

=head1 CONSTRUCTOR

=head2 new

    my $optimizer = Lugh::Optimizer::AdamW->new(%options);

Creates a new AdamW optimizer.

B<Options:>

=over 4

=item C<lr> (default: 0.001)

Learning rate. For transformers, typical values are 1e-4 to 5e-5.

=item C<beta1> (default: 0.9)

Exponential decay rate for the first moment estimates.

=item C<beta2> (default: 0.999)

Exponential decay rate for the second moment estimates.

=item C<eps> (default: 1e-8)

Small constant for numerical stability. Prevents division by zero.

=item C<weight_decay> (default: 0.01)

Decoupled weight decay coefficient. Applied directly to parameters,
not to gradients.

=back

B<Examples:>

    # Default AdamW for transformers
    my $adamw = Lugh::Optimizer::AdamW->new(
        lr           => 1e-4,
        weight_decay => 0.01,
    );

    # Fine-tuning with lower learning rate
    my $adamw = Lugh::Optimizer::AdamW->new(
        lr           => 2e-5,
        weight_decay => 0.01,
        beta1        => 0.9,
        beta2        => 0.999,
    );

    # For stable training with larger batches
    my $adamw = Lugh::Optimizer::AdamW->new(
        lr           => 5e-4,
        weight_decay => 0.1,
        beta2        => 0.95,  # Lower for larger batches
    );

=head1 METHODS

=head2 add_param

    $optimizer->add_param($tensor);

Registers a tensor as a parameter to be optimized. The optimizer will
maintain first and second moment estimates for this parameter.

B<Parameters:>

=over 4

=item C<$tensor>

A L<Lugh::Autograd::Tensor> object with C<requires_grad> enabled.

=back

B<Example:>

    # Register all model parameters
    for my $layer (@layers) {
        $optimizer->add_param($layer->{weights});
        $optimizer->add_param($layer->{bias}) if $layer->{bias};
    }

=head2 zero_grad

    $optimizer->zero_grad();

Zeros the gradients of all registered parameters. Must be called at the
start of each training iteration.

=head2 step

    $optimizer->step();

Performs a single optimization step, updating all registered parameters
based on their gradients and the optimizer state (moment estimates).

=head2 get_lr

    my $current_lr = $optimizer->get_lr();

Returns the current learning rate.

=head2 set_lr

    $optimizer->set_lr($new_lr);

Sets a new learning rate. Useful when implementing learning rate schedules.

=head2 get_step_count

    my $steps = $optimizer->get_step_count();

Returns the number of optimization steps taken. Used internally for
bias correction.

=head1 TRAINING TIPS

=head2 Learning Rate

=over 4

=item * Start with 1e-4 for pre-training

=item * Use 2e-5 to 5e-5 for fine-tuning

=item * Scale with batch size: lr_scaled = lr_base * sqrt(batch_size / 32)

=back

=head2 Weight Decay

=over 4

=item * Use 0.01 for most cases

=item * Increase to 0.1 for regularization

=item * Set to 0 for bias terms and layer norms (not currently supported
per-parameter)

=back

=head2 Warmup

AdamW benefits from learning rate warmup, especially for larger models:

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'linear',
        warmup_steps => 1000,
        total_steps  => 100000,
    );

=head1 ADAMW VS ADAM

AdamW differs from the original Adam in how weight decay is applied:

=over 4

=item * B<Adam:> Weight decay is added to the gradient before computing
moment estimates, which couples it with the adaptive learning rate.

=item * B<AdamW:> Weight decay is applied directly to parameters after
the gradient update, decoupling it from the adaptive learning rate.

=back

AdamW generally provides better generalization, especially for
transformer models.

=head1 MEMORY USAGE

AdamW maintains two additional tensors per parameter (first and second
moment estimates), tripling the memory required compared to SGD. For
large models, this can be significant:

    Model Params    Parameter Memory    AdamW Memory
    1B              4 GB                12 GB
    7B              28 GB               84 GB

=head1 SEE ALSO

L<Lugh::Optimizer::SGD> - Basic SGD optimizer

L<Lugh::Optimizer::LRScheduler> - Learning rate scheduling

L<Lugh::Optimizer> - Gradient clipping utilities

L<Lugh::Autograd> - Automatic differentiation

=head1 REFERENCES

Loshchilov, I., & Hutter, F. (2017). "Decoupled Weight Decay Regularization"
L<https://arxiv.org/abs/1711.05101>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
