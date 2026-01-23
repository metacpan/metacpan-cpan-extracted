package Lugh::Optimizer::LRScheduler;

use strict;
use warnings;

our $VERSION = '0.12';

# XS methods are loaded via Lugh.xs
# This module provides documentation only

1;

__END__

=head1 NAME

Lugh::Optimizer::LRScheduler - Learning rate scheduling for optimizers

=head1 SYNOPSIS

    use Lugh;
    use Lugh::Autograd;

    # Create optimizer
    my $optimizer = Lugh::Optimizer::AdamW->new(lr => 1e-4);

    # Create cosine annealing scheduler with warmup
    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'cosine',
        warmup_steps => 1000,
        total_steps  => 100000,
        min_lr       => 1e-6,
    );

    # Training loop
    for my $step (1..100000) {
        $optimizer->zero_grad();

        my $loss = compute_loss();
        $loss->backward();

        $optimizer->step();
        $scheduler->step();  # Update learning rate

        if ($step % 1000 == 0) {
            printf "Step %d, LR: %.2e\n", $step, $scheduler->get_lr();
        }
    }

=head1 DESCRIPTION

C<Lugh::Optimizer::LRScheduler> provides learning rate scheduling for
optimizer objects. Learning rate schedules adjust the learning rate
during training, which is crucial for achieving good convergence,
especially in transformer models.

The scheduler wraps an optimizer and adjusts its learning rate based
on the current step count and the chosen schedule.

=head1 CONSTRUCTOR

=head2 new

    my $scheduler = Lugh::Optimizer::LRScheduler->new($optimizer, %options);

Creates a new learning rate scheduler.

B<Parameters:>

=over 4

=item C<$optimizer>

The optimizer to schedule. Must have C<get_lr()> and C<set_lr()> methods.
Typically a L<Lugh::Optimizer::SGD> or L<Lugh::Optimizer::AdamW>.

=back

B<Options:>

=over 4

=item C<schedule> or C<type> (default: 'constant')

The schedule type. Available schedules:

=over 4

=item * C<'constant'> - No change to learning rate

=item * C<'linear'> - Linear decay from initial to min_lr

=item * C<'cosine'> - Cosine annealing

=item * C<'exponential'> - Exponential decay

=item * C<'step'> - Step decay at milestones

=item * C<'warmup'> - Linear warmup only, then constant

=back

=item C<warmup_steps> (default: 0)

Number of warmup steps. During warmup, the learning rate increases
linearly from 0 to the initial learning rate.

=item C<total_steps> (default: 1000)

Total number of training steps. Used for calculating decay rates.

=item C<min_lr> (default: 0)

Minimum learning rate. The scheduler will not reduce the learning
rate below this value.

=item C<decay_rate> or C<gamma> (default: 0.1)

Decay factor for exponential and step schedules.

=item C<milestones> (for step schedule)

Array reference of step numbers at which to apply decay.

=back

=head1 SCHEDULE TYPES

=head2 constant

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule => 'constant',
    );

Learning rate remains unchanged throughout training.

=head2 linear

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'linear',
        warmup_steps => 1000,
        total_steps  => 100000,
        min_lr       => 1e-6,
    );

Linear decay from initial learning rate to C<min_lr>:

    if step <= warmup_steps:
        lr = initial_lr * (step / warmup_steps)
    else:
        progress = (step - warmup_steps) / (total_steps - warmup_steps)
        lr = initial_lr + (min_lr - initial_lr) * progress

=head2 cosine

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'cosine',
        warmup_steps => 1000,
        total_steps  => 100000,
        min_lr       => 1e-6,
    );

Cosine annealing, which provides smooth decay:

    if step <= warmup_steps:
        lr = initial_lr * (step / warmup_steps)
    else:
        progress = (step - warmup_steps) / (total_steps - warmup_steps)
        lr = min_lr + 0.5 * (initial_lr - min_lr) * (1 + cos(pi * progress))

Cosine annealing is the most commonly used schedule for transformer
training.

=head2 exponential

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule   => 'exponential',
        decay_rate => 0.99,
        min_lr     => 1e-6,
    );

Exponential decay:

    lr = initial_lr * decay_rate^step
    lr = max(lr, min_lr)

=head2 step

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule   => 'step',
        milestones => [30000, 60000, 90000],
        decay_rate => 0.1,
    );

Step decay at specified milestones:

    lr = initial_lr * decay_rate^(number of milestones passed)

Common in computer vision (e.g., ImageNet training).

=head2 warmup

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'warmup',
        warmup_steps => 1000,
    );

Linear warmup followed by constant learning rate:

    if step <= warmup_steps:
        lr = initial_lr * (step / warmup_steps)
    else:
        lr = initial_lr

=head1 METHODS

=head2 step

    $scheduler->step();

Advances the scheduler by one step and updates the optimizer's learning
rate. Should be called once per training iteration, typically after
C<$optimizer-E<gt>step()>.

=head2 get_lr

    my $current_lr = $scheduler->get_lr();

Returns the current learning rate from the underlying optimizer.

=head2 get_step

    my $current_step = $scheduler->get_step();

Returns the current step count of the scheduler.

=head1 USAGE PATTERNS

=head2 Pre-training

For pre-training large language models:

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'cosine',
        warmup_steps => 2000,
        total_steps  => 300000,
        min_lr       => 1e-5,
    );

=head2 Fine-tuning

For fine-tuning on downstream tasks:

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'linear',
        warmup_steps => 100,
        total_steps  => 3000,
        min_lr       => 0,
    );

=head2 Few-shot Learning

For quick adaptation:

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'warmup',
        warmup_steps => 10,
    );

=head1 EXAMPLE: COMPLETE TRAINING LOOP

    use Lugh;
    use Lugh::Autograd;

    # Setup
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    my $params = create_model_params($ctx);

    my $optimizer = Lugh::Optimizer::AdamW->new(
        lr           => 1e-4,
        weight_decay => 0.01,
    );

    for my $p (@$params) {
        $optimizer->add_param($p);
    }

    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'cosine',
        warmup_steps => 1000,
        total_steps  => 50000,
        min_lr       => 1e-6,
    );

    # Training
    for my $step (1..50000) {
        my ($inputs, $targets) = get_batch();

        $optimizer->zero_grad();

        my $loss = forward_pass($params, $inputs, $targets);
        $loss->backward();

        # Gradient clipping (optional)
        Lugh::Optimizer->clip_grad_norm(1.0, @$params);

        $optimizer->step();
        $scheduler->step();

        if ($step % 100 == 0) {
            printf "Step %d: loss=%.4f, lr=%.2e\n",
                   $step, $loss->get_data()->[0], $scheduler->get_lr();
        }
    }

=head1 SEE ALSO

L<Lugh::Optimizer::AdamW> - Recommended optimizer for transformers

L<Lugh::Optimizer::SGD> - Basic SGD optimizer

L<Lugh::Optimizer> - Gradient clipping utilities

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
