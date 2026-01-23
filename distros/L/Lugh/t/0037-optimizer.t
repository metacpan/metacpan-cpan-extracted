#!/usr/bin/env perl
# t/0037-optimizer.t - Tests for Lugh::Optimizer modules
#
# Tests SGD, AdamW, and LRScheduler functionality.

use strict;
use warnings;
use Test::More;
use FindBin;
use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

plan tests => 7;

# ============================================================================
# Setup: Create context and tensors
# ============================================================================

my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
ok($ctx, 'Context created');

# Create a tensor with gradient tracking
my $weights = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
ok($weights, 'Tensor created');
$weights->set_data(0.5, 0.5, 0.5, 0.5);

my @data = $weights->get_data();
is(scalar(@data), 4, 'Tensor has 4 elements');

# ============================================================================
# Test SGD Optimizer
# ============================================================================

subtest 'SGD Optimizer' => sub {
    plan tests => 10;

    # Test 1: Create basic SGD
    my $sgd = Lugh::Optimizer::SGD->new(lr => 0.01);
    ok($sgd, 'SGD created with default options');

    # Test 2: Create SGD with all options
    my $sgd_full = Lugh::Optimizer::SGD->new(
        lr           => 0.01,
        momentum     => 0.9,
        weight_decay => 0.0001,
        nesterov     => 1,
    );
    ok($sgd_full, 'SGD created with all options');

    # Test 3: Get learning rate
    my $lr = $sgd->get_lr();
    ok(abs($lr - 0.01) < 1e-6, "get_lr returns correct value: $lr");

    # Test 4: Set learning rate
    $sgd->set_lr(0.001);
    $lr = $sgd->get_lr();
    ok(abs($lr - 0.001) < 1e-6, "set_lr updates correctly: $lr");

    # Test 5: Add parameter
    my $ctx2 = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    my $param = Lugh::Autograd::Tensor->new($ctx2, 'f32', 4, { requires_grad => 1 });
    $param->set_data(1.0, 2.0, 3.0, 4.0);

    eval { $sgd->add_param($param); };
    ok(!$@, 'add_param succeeded');

    # Test 6: Zero gradients
    eval { $sgd->zero_grad(); };
    ok(!$@, 'zero_grad succeeded');

    # Test 7: Step (without gradients, should be safe)
    eval { $sgd->step(); };
    ok(!$@, 'step succeeded');

    # Test 8: Multiple parameters
    my $param2 = Lugh::Autograd::Tensor->new($ctx2, 'f32', 4, { requires_grad => 1 });
    $param2->set_data(0.1, 0.2, 0.3, 0.4);
    eval { $sgd->add_param($param2); };
    ok(!$@, 'add_param for second parameter succeeded');

    # Test 9: Zero grad with multiple params
    eval { $sgd->zero_grad(); };
    ok(!$@, 'zero_grad with multiple params succeeded');

    # Test 10: Step with multiple params
    eval { $sgd->step(); };
    ok(!$@, 'step with multiple params succeeded');
};

# ============================================================================
# Test AdamW Optimizer
# ============================================================================

subtest 'AdamW Optimizer' => sub {
    plan tests => 10;

    # Test 1: Create basic AdamW
    my $adamw = Lugh::Optimizer::AdamW->new(lr => 1e-4);
    ok($adamw, 'AdamW created with default options');

    # Test 2: Create AdamW with all options
    my $adamw_full = Lugh::Optimizer::AdamW->new(
        lr           => 1e-4,
        beta1        => 0.9,
        beta2        => 0.999,
        eps          => 1e-8,
        weight_decay => 0.01,
    );
    ok($adamw_full, 'AdamW created with all options');

    # Test 3: Get learning rate
    my $lr = $adamw->get_lr();
    ok(abs($lr - 1e-4) < 1e-10, "get_lr returns correct value: $lr");

    # Test 4: Set learning rate
    $adamw->set_lr(5e-5);
    $lr = $adamw->get_lr();
    ok(abs($lr - 5e-5) < 1e-10, "set_lr updates correctly: $lr");

    # Test 5: Get step count
    my $step_count = $adamw->get_step_count();
    is($step_count, 0, 'Initial step count is 0');

    # Test 6: Add parameter
    my $ctx3 = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    my $param = Lugh::Autograd::Tensor->new($ctx3, 'f32', 4, { requires_grad => 1 });
    $param->set_data(1.0, 2.0, 3.0, 4.0);

    eval { $adamw->add_param($param); };
    ok(!$@, 'add_param succeeded');

    # Test 7: Zero gradients
    eval { $adamw->zero_grad(); };
    ok(!$@, 'zero_grad succeeded');

    # Test 8: Step
    eval { $adamw->step(); };
    ok(!$@, 'step succeeded');

    # Test 9: Step count increments
    $step_count = $adamw->get_step_count();
    is($step_count, 1, 'Step count incremented to 1');

    # Test 10: Multiple steps
    for (1..5) {
        $adamw->zero_grad();
        $adamw->step();
    }
    $step_count = $adamw->get_step_count();
    is($step_count, 6, 'Step count is 6 after 6 total steps');
};

# ============================================================================
# Test LRScheduler
# ============================================================================

subtest 'LRScheduler' => sub {
    plan tests => 16;

    my $optimizer = Lugh::Optimizer::AdamW->new(lr => 1e-3);
    ok($optimizer, 'Optimizer created for scheduler tests');

    # Test 1: Constant scheduler
    my $const_sched = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule => 'constant',
    );
    ok($const_sched, 'Constant scheduler created');

    my $lr_before = $const_sched->get_lr();
    $const_sched->step();
    my $lr_after = $const_sched->get_lr();
    ok(abs($lr_before - $lr_after) < 1e-10, 'Constant schedule keeps LR unchanged');

    # Test 2: Linear scheduler with warmup
    $optimizer->set_lr(1e-3);
    my $linear_sched = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'linear',
        warmup_steps => 10,
        total_steps  => 100,
        min_lr       => 1e-5,
    );
    ok($linear_sched, 'Linear scheduler created');

    # Test 3: Get step
    my $step = $linear_sched->get_step();
    is($step, 0, 'Initial step is 0');

    # Test 4: Step increments
    $linear_sched->step();
    $step = $linear_sched->get_step();
    is($step, 1, 'Step incremented to 1');

    # Test 5: Warmup increases LR
    $optimizer->set_lr(1e-3);
    my $warmup_sched = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'warmup',
        warmup_steps => 10,
    );

    # First step should have low LR (warmup)
    $warmup_sched->step();
    my $warmup_lr = $warmup_sched->get_lr();
    ok($warmup_lr <= 1e-3, "Warmup LR is less than or equal to initial: $warmup_lr");

    # Test 6: Cosine scheduler
    $optimizer->set_lr(1e-3);
    my $cosine_sched = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule     => 'cosine',
        warmup_steps => 5,
        total_steps  => 100,
        min_lr       => 1e-5,
    );
    ok($cosine_sched, 'Cosine scheduler created');

    # Test 7: Step scheduler with milestones
    $optimizer->set_lr(1e-3);
    my $step_sched = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule   => 'step',
        milestones => [10, 20, 30],
        decay_rate => 0.1,
    );
    ok($step_sched, 'Step scheduler with milestones created');

    # Test 8: Exponential scheduler
    $optimizer->set_lr(1e-3);
    my $exp_sched = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule   => 'exponential',
        decay_rate => 0.99,
        min_lr     => 1e-6,
    );
    ok($exp_sched, 'Exponential scheduler created');

    # Test 9: LR decreases over time with exponential
    my $initial_lr = $exp_sched->get_lr();
    for (1..10) {
        $exp_sched->step();
    }
    my $later_lr = $exp_sched->get_lr();
    ok($later_lr < $initial_lr, "Exponential decay reduces LR: $initial_lr -> $later_lr");

    # Test 10: min_lr is respected
    $optimizer->set_lr(1e-3);
    my $min_sched = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule   => 'exponential',
        decay_rate => 0.5,
        min_lr     => 1e-4,
    );

    for (1..100) {
        $min_sched->step();
    }
    my $final_lr = $min_sched->get_lr();
    ok($final_lr >= 1e-4 - 1e-10, "LR doesn't go below min_lr: $final_lr");

    # Test 11: Works with SGD
    my $sgd = Lugh::Optimizer::SGD->new(lr => 0.1);
    my $sgd_sched = Lugh::Optimizer::LRScheduler->new(
        $sgd,
        schedule     => 'linear',
        warmup_steps => 5,
        total_steps  => 50,
    );
    ok($sgd_sched, 'LRScheduler works with SGD');

    # Test 12: get_lr through scheduler
    my $sched_lr = $sgd_sched->get_lr();
    ok(defined $sched_lr, "get_lr returns defined value: $sched_lr");

    # Test 13: Schedule type 'type' alias works
    $optimizer->set_lr(1e-3);
    my $alias_sched = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        type => 'constant',  # Using 'type' instead of 'schedule'
    );
    ok($alias_sched, 'Schedule type alias works');

    # Test 14: gamma alias for decay_rate
    $optimizer->set_lr(1e-3);
    my $gamma_sched = Lugh::Optimizer::LRScheduler->new(
        $optimizer,
        schedule => 'exponential',
        gamma    => 0.95,  # Using 'gamma' instead of 'decay_rate'
    );
    ok($gamma_sched, 'gamma alias for decay_rate works');
};

# ============================================================================
# Test Gradient Clipping
# ============================================================================

subtest 'Gradient Clipping' => sub {
    plan tests => 4;

    my $ctx4 = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    my $tensor = Lugh::Autograd::Tensor->new($ctx4, 'f32', 4, { requires_grad => 1 });
    $tensor->set_data(1.0, 2.0, 3.0, 4.0);

    # Test 1: clip_grad_norm exists
    eval { Lugh::Optimizer->clip_grad_norm(1.0, $tensor); };
    ok(!$@, 'clip_grad_norm callable');

    # Test 2: clip_grad_value exists
    eval { Lugh::Optimizer->clip_grad_value(1.0, $tensor); };
    ok(!$@, 'clip_grad_value callable');

    # Test 3: Multiple tensors
    my $tensor2 = Lugh::Autograd::Tensor->new($ctx4, 'f32', 4, { requires_grad => 1 });
    $tensor2->set_data(0.1, 0.2, 0.3, 0.4);

    eval { Lugh::Optimizer->clip_grad_norm(1.0, $tensor, $tensor2); };
    ok(!$@, 'clip_grad_norm with multiple tensors');

    eval { Lugh::Optimizer->clip_grad_value(0.5, $tensor, $tensor2); };
    ok(!$@, 'clip_grad_value with multiple tensors');
};

done_testing();
