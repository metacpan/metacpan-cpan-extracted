#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin qw($Bin);

# Test Lugh::Optimizer module

use_ok('Lugh');
use_ok('Lugh::Optimizer');
use_ok('Lugh::Train');
use_ok('Lugh::Autograd');
use_ok('Lugh::Autograd::Tensor');

my $test_model_path = File::Spec->catfile($Bin, 'data', 'test-model.gguf');

subtest 'SGD basic' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    ok($ctx, 'created context');
    
    my $sgd = Lugh::Optimizer::SGD->new(lr => 0.1);
    ok($sgd, 'created SGD optimizer');
    isa_ok($sgd, 'Lugh::Optimizer::SGD');
    
    cmp_ok(abs($sgd->get_lr() - 0.1), '<', 0.001, 'get_lr returns ~0.1');
    
    $sgd->set_lr(0.05);
    cmp_ok(abs($sgd->get_lr() - 0.05), '<', 0.001, 'set_lr updates correctly');
    
    done_testing();
};

subtest 'SGD with momentum' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $sgd = Lugh::Optimizer::SGD->new(
        lr       => 0.1,
        momentum => 0.9,
    );
    ok($sgd, 'created SGD with momentum');
    
    # Create a simple tensor
    my $w = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $w->set_data(1.0, 2.0, 3.0);
    ok($w, 'created tensor');
    
    $sgd->add_param($w);
    
    # Compute forward/backward to get gradients
    my $loss = Lugh::Autograd::Ops->sum($ctx, $w);
    ok($loss, 'computed sum loss');
    
    $loss->backward();
    
    my @data_before = $w->get_data();
    $sgd->step();
    my @data_after = $w->get_data();
    
    # With grad of 1 and lr of 0.1, weights should decrease by 0.1
    ok($data_after[0] < $data_before[0], 'weight 0 decreased after step');
    ok($data_after[1] < $data_before[1], 'weight 1 decreased after step');
    ok($data_after[2] < $data_before[2], 'weight 2 decreased after step');
    
    done_testing();
};

subtest 'AdamW basic' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $adamw = Lugh::Optimizer::AdamW->new(
        lr           => 1e-3,
        beta1        => 0.9,
        beta2        => 0.999,
        weight_decay => 0.01,
    );
    ok($adamw, 'created AdamW optimizer');
    isa_ok($adamw, 'Lugh::Optimizer::AdamW');
    
    cmp_ok(abs($adamw->get_lr() - 1e-3), '<', 1e-6, 'get_lr returns ~0.001');
    is($adamw->get_step_count(), 0, 'step count starts at 0');
    
    done_testing();
};

subtest 'AdamW training step' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $adamw = Lugh::Optimizer::AdamW->new(lr => 0.01);
    
    my $w = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, { requires_grad => 1 });
    $w->set_data(1.0, 2.0);
    $adamw->add_param($w);
    
    # Forward and backward
    my $loss = Lugh::Autograd::Ops->sum($ctx, $w);
    $loss->backward();
    
    my @data_before = $w->get_data();
    $adamw->step();
    my @data_after = $w->get_data();
    
    ok($data_after[0] < $data_before[0], 'AdamW decreased weight 0');
    ok($data_after[1] < $data_before[1], 'AdamW decreased weight 1');
    is($adamw->get_step_count(), 1, 'step count incremented');
    
    done_testing();
};

subtest 'zero_grad' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $sgd = Lugh::Optimizer::SGD->new(lr => 0.1);
    my $w = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, { requires_grad => 1 });
    $w->set_data(1.0, 2.0);
    $sgd->add_param($w);
    
    # Compute gradient
    my $loss = Lugh::Autograd::Ops->sum($ctx, $w);
    $loss->backward();
    
    # Check grad is non-zero
    my $grad = $w->grad();
    ok($grad->[0] != 0 || $grad->[1] != 0, 'has gradients after backward');
    
    # Zero grad
    $sgd->zero_grad();
    $grad = $w->grad();
    ok($grad->[0] == 0 && $grad->[1] == 0, 'gradients zeroed');
    
    done_testing();
};

subtest 'LRScheduler constant' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $sgd = Lugh::Optimizer::SGD->new(lr => 0.1);
    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $sgd,
        schedule => 'constant',
    );
    ok($scheduler, 'created constant scheduler');
    
    cmp_ok(abs($scheduler->get_lr() - 0.1), '<', 0.001, 'initial LR correct');
    
    $scheduler->step();
    cmp_ok(abs($scheduler->get_lr() - 0.1), '<', 0.001, 'LR unchanged after step');
    is($scheduler->get_step(), 1, 'step count is 1');
    
    $scheduler->step();
    cmp_ok(abs($scheduler->get_lr() - 0.1), '<', 0.001, 'LR still unchanged');
    is($scheduler->get_step(), 2, 'step count is 2');
    
    done_testing();
};

subtest 'LRScheduler warmup' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $sgd = Lugh::Optimizer::SGD->new(lr => 0.1);
    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $sgd,
        schedule     => 'warmup',
        warmup_steps => 10,
    );
    ok($scheduler, 'created warmup scheduler');
    
    # Step through warmup
    for my $i (1..5) {
        $scheduler->step();
    }
    my $mid_warmup_lr = $scheduler->get_lr();
    ok($mid_warmup_lr < 0.1, 'LR < initial during warmup');
    ok($mid_warmup_lr > 0, 'LR > 0 during warmup');
    
    # Complete warmup
    for my $i (6..10) {
        $scheduler->step();
    }
    my $post_warmup_lr = $scheduler->get_lr();
    cmp_ok(abs($post_warmup_lr - 0.1), '<', 0.001, 'LR reached initial after warmup');
    
    # After warmup, should stay constant
    $scheduler->step();
    cmp_ok(abs($scheduler->get_lr() - 0.1), '<', 0.001, 'LR stays constant after warmup');
    
    done_testing();
};

subtest 'LRScheduler cosine' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $sgd = Lugh::Optimizer::SGD->new(lr => 0.1);
    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $sgd,
        schedule     => 'cosine',
        warmup_steps => 0,
        total_steps  => 100,
        min_lr       => 0.001,
    );
    ok($scheduler, 'created cosine scheduler');
    
    my @lrs;
    for my $i (1..100) {
        $scheduler->step();
        push @lrs, $scheduler->get_lr();
    }
    
    # LR should decrease overall
    ok($lrs[0] > $lrs[50], 'LR at step 1 > step 50');
    ok($lrs[50] > $lrs[-1], 'LR at step 50 > step 100');
    
    # Should approach min_lr at the end
    cmp_ok(abs($lrs[-1] - 0.001), '<', 0.01, 'LR approaches min_lr');
    
    done_testing();
};

subtest 'LRScheduler step decay' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $sgd = Lugh::Optimizer::SGD->new(lr => 0.1);
    my $scheduler = Lugh::Optimizer::LRScheduler->new(
        $sgd,
        schedule   => 'step',
        milestones => [10, 20],
        decay_rate => 0.5,
    );
    ok($scheduler, 'created step scheduler');
    
    # Before first milestone
    for (1..9) { $scheduler->step(); }
    cmp_ok(abs($scheduler->get_lr() - 0.1), '<', 0.001, 'LR = 0.1 before milestone');
    
    # At first milestone
    $scheduler->step();  # step 10
    cmp_ok(abs($scheduler->get_lr() - 0.05), '<', 0.001, 'LR = 0.05 at milestone 10');
    
    # At second milestone  
    for (11..20) { $scheduler->step(); }
    cmp_ok(abs($scheduler->get_lr() - 0.025), '<', 0.001, 'LR = 0.025 at milestone 20');
    
    done_testing();
};

subtest 'gradient clipping by norm' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $w = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $w->set_data(1.0, 2.0, 3.0);
    
    # Create a large gradient by using scale
    my $scaled = Lugh::Autograd::Ops->scale($ctx, $w, 100.0);
    my $loss = Lugh::Autograd::Ops->sum($ctx, $scaled);
    $loss->backward();
    
    my @grad_before = @{$w->grad()};
    my $norm_before = sqrt($grad_before[0]**2 + $grad_before[1]**2 + $grad_before[2]**2);
    ok($norm_before > 1.0, "gradient norm ($norm_before) > 1.0 before clipping");
    
    my $returned_norm = Lugh::Optimizer->clip_grad_norm(1.0, $w);
    cmp_ok(abs($returned_norm - $norm_before), '<', 0.01, 'returned norm matches original');
    
    my @grad_after = @{$w->grad()};
    my $norm_after = sqrt($grad_after[0]**2 + $grad_after[1]**2 + $grad_after[2]**2);
    cmp_ok($norm_after, '<=', 1.01, "gradient norm ($norm_after) <= 1.0 after clipping");
    
    done_testing();
};

subtest 'gradient clipping by value' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $w = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $w->set_data(1.0, 2.0, 3.0);
    
    # Create large gradients
    my $scaled = Lugh::Autograd::Ops->scale($ctx, $w, 10.0);
    my $loss = Lugh::Autograd::Ops->sum($ctx, $scaled);
    $loss->backward();
    
    my @grad_before = @{$w->grad()};
    ok(abs($grad_before[0]) > 0.5, 'grad > 0.5 before clipping');
    
    Lugh::Optimizer->clip_grad_value(0.5, $w);
    
    my @grad_after = @{$w->grad()};
    ok(abs($grad_after[0]) <= 0.5, 'grad <= 0.5 after clipping');
    ok(abs($grad_after[1]) <= 0.5, 'grad[1] <= 0.5 after clipping');
    ok(abs($grad_after[2]) <= 0.5, 'grad[2] <= 0.5 after clipping');
    
    done_testing();
};

subtest 'weight decay' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    # Test that weight decay pulls weights toward 0
    my $w = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, { requires_grad => 1 });
    $w->set_data(10.0, 10.0);
    
    my $adamw = Lugh::Optimizer::AdamW->new(
        lr           => 0.1,
        weight_decay => 0.1,  # 10% decay per step
    );
    $adamw->add_param($w);
    
    my @data_before = $w->get_data();
    
    # Forward/backward with MSE loss toward zero
    my $zero = Lugh::Autograd::Tensor->new($ctx, 'f32', 2);
    $zero->set_data(0.0, 0.0);
    my $loss = Lugh::Train->mse_loss($ctx, $w, $zero);
    $loss->backward();
    $adamw->zero_grad();  # Zero out MSE gradient to isolate weight decay effect
    
    # Now step - should only apply weight decay (since grad is zero)
    $adamw->step();
    
    my @data_after = $w->get_data();
    
    # With weight_decay=0.1 and lr=0.1, weights should decrease
    ok($data_after[0] < $data_before[0], 'weight decay reduced weight 0');
    ok($data_after[1] < $data_before[1], 'weight decay reduced weight 1');
    
    done_testing();
};

subtest 'multiple parameters' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $w1 = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, { requires_grad => 1 });
    $w1->set_data(1.0, 2.0);
    my $w2 = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, { requires_grad => 1 });
    $w2->set_data(3.0, 4.0);
    
    my $sgd = Lugh::Optimizer::SGD->new(lr => 0.1);
    $sgd->add_param($w1);
    $sgd->add_param($w2);
    
    # Compute gradients for both
    my $sum1 = Lugh::Autograd::Ops->sum($ctx, $w1);
    my $sum2 = Lugh::Autograd::Ops->sum($ctx, $w2);
    $sum1->backward();
    $sum2->backward();
    
    my @w1_before = $w1->get_data();
    my @w2_before = $w2->get_data();
    
    $sgd->step();
    
    my @w1_after = $w1->get_data();
    my @w2_after = $w2->get_data();
    
    ok($w1_after[0] < $w1_before[0], 'w1[0] updated');
    ok($w2_after[0] < $w2_before[0], 'w2[0] updated');
    
    done_testing();
};

done_testing();
