package Lugh::Optimizer::SGD;

use strict;
use warnings;

our $VERSION = '0.12';

# XS methods are loaded via Lugh.xs
# This module provides documentation only

1;

__END__

=head1 NAME

Lugh::Optimizer::SGD - Stochastic Gradient Descent optimizer

=head1 SYNOPSIS

    use Lugh;
    use Lugh::Autograd;

    # Create context and parameter tensor
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    my $weights = Lugh::Autograd::Tensor->new($ctx, 'f32', 10, {
        requires_grad => 1,
    });
    $weights->set_data((0.5) x 10);

    # Create SGD optimizer
    my $optimizer = Lugh::Optimizer::SGD->new(
        lr       => 0.01,
        momentum => 0.9,
    );

    # Register parameters
    $optimizer->add_param($weights);

    # Training loop
    for my $epoch (1..100) {
        $optimizer->zero_grad();

        # Forward pass (compute loss)
        my $loss = compute_loss($weights, $data);

        # Backward pass
        $loss->backward();

        # Update parameters
        $optimizer->step();
    }

=head1 DESCRIPTION

C<Lugh::Optimizer::SGD> implements Stochastic Gradient Descent with optional
momentum and Nesterov acceleration. It is the most basic and widely used
optimizer for training neural networks.

The update rule with momentum is:

    v_t = momentum * v_{t-1} + gradient
    param = param - lr * v_t

With Nesterov momentum:

    v_t = momentum * v_{t-1} + gradient
    param = param - lr * (momentum * v_t + gradient)

=head1 CONSTRUCTOR

=head2 new

    my $optimizer = Lugh::Optimizer::SGD->new(%options);

Creates a new SGD optimizer.

B<Options:>

=over 4

=item C<lr> (default: 0.001)

Learning rate. Controls the step size for parameter updates.

=item C<momentum> (default: 0)

Momentum factor. Set to 0.9 or 0.99 for faster convergence.

=item C<weight_decay> (default: 0)

L2 regularization coefficient. Adds a penalty proportional to the
squared magnitude of parameters.

=item C<nesterov> (default: 0)

If true, use Nesterov momentum instead of classical momentum.
Nesterov momentum often provides better convergence.

=back

B<Examples:>

    # Basic SGD
    my $sgd = Lugh::Optimizer::SGD->new(lr => 0.01);

    # SGD with momentum
    my $sgd = Lugh::Optimizer::SGD->new(
        lr       => 0.01,
        momentum => 0.9,
    );

    # SGD with Nesterov momentum and weight decay
    my $sgd = Lugh::Optimizer::SGD->new(
        lr           => 0.01,
        momentum     => 0.9,
        nesterov     => 1,
        weight_decay => 0.0001,
    );

=head1 METHODS

=head2 add_param

    $optimizer->add_param($tensor);

Registers a tensor as a parameter to be optimized. Only tensors with
C<requires_grad =E<gt> 1> should be added.

B<Parameters:>

=over 4

=item C<$tensor>

A L<Lugh::Autograd::Tensor> object with C<requires_grad> enabled.

=back

B<Example:>

    my $w1 = Lugh::Autograd::Tensor->new($ctx, 'f32', 10, 10, {
        requires_grad => 1,
    });
    my $w2 = Lugh::Autograd::Tensor->new($ctx, 'f32', 10, {
        requires_grad => 1,
    });

    $optimizer->add_param($w1);
    $optimizer->add_param($w2);

=head2 zero_grad

    $optimizer->zero_grad();

Zeros the gradients of all registered parameters. This should be called
at the beginning of each training iteration to prevent gradient accumulation.

B<Example:>

    for my $batch (@batches) {
        $optimizer->zero_grad();  # Clear gradients

        my $loss = compute_loss($batch);
        $loss->backward();
        $optimizer->step();
    }

=head2 step

    $optimizer->step();

Performs a single optimization step, updating all registered parameters
based on their gradients.

B<Note:> This should be called after C<backward()> has been called to
compute gradients.

=head2 get_lr

    my $current_lr = $optimizer->get_lr();

Returns the current learning rate.

=head2 set_lr

    $optimizer->set_lr($new_lr);

Sets a new learning rate. Useful for implementing custom learning rate
schedules or manual adjustment during training.

B<Example:>

    # Manual learning rate decay
    if ($epoch % 30 == 0) {
        my $current_lr = $optimizer->get_lr();
        $optimizer->set_lr($current_lr * 0.1);
    }

=head1 HYPERPARAMETER GUIDELINES

=head2 Learning Rate

=over 4

=item * Start with 0.01 or 0.001

=item * If loss oscillates, reduce by 10x

=item * If loss decreases too slowly, increase by 2-10x

=back

=head2 Momentum

=over 4

=item * Use 0.9 as a default for most cases

=item * Try 0.99 for very smooth optimization landscapes

=item * Set to 0 if momentum causes instability

=back

=head2 Weight Decay

=over 4

=item * Use 1e-4 to 1e-5 for regularization

=item * Higher values (1e-2) for strong regularization

=item * Set to 0 if overfitting is not a concern

=back

=head1 COMPARISON WITH ADAMW

SGD is simpler and has fewer hyperparameters than AdamW, but may
require more tuning of the learning rate schedule. AdamW often works
"out of the box" for transformer models, while SGD can achieve
better generalization with proper tuning.

=head1 SEE ALSO

L<Lugh::Optimizer::AdamW> - Adam optimizer with weight decay

L<Lugh::Optimizer::LRScheduler> - Learning rate scheduling

L<Lugh::Optimizer> - Gradient clipping utilities

L<Lugh::Autograd> - Automatic differentiation

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
