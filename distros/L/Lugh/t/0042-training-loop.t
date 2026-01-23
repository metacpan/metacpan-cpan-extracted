#!/usr/bin/env perl

use 5.030;
use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use lib 'blib/lib', 'blib/arch';

# Helper for exception testing
sub lives_ok (&$) {
    my ($code, $name) = @_;
    eval { $code->() };
    ok(!$@, $name) or diag("Died: $@");
}

sub dies_ok (&$) {
    my ($code, $name) = @_;
    eval { $code->() };
    ok($@, $name);
}

# Must use the test model
use constant TEST_MODEL => 't/data/test-model.gguf';

BEGIN {
    unless (-f TEST_MODEL) {
        plan skip_all => 'Test model not found at ' . TEST_MODEL;
    }
    use_ok('Lugh');
    use_ok('Lugh::Train');
    use_ok('Lugh::Autograd');
    use_ok('Lugh::Autograd::Tensor');
}

# Helper to compute tensor
sub compute_tensor {
    my ($ctx, $tensor) = @_;
    my $graph = Lugh::Graph->new($ctx);
    my $raw = Lugh::Tensor->from_ptr($tensor->_raw_tensor_ptr);
    $graph->build_forward($raw);
    $graph->compute($ctx, 1);
}

# =============================================================================
# CROSS-ENTROPY LOSS TESTS
# =============================================================================

subtest 'cross_entropy_loss basic' => sub {
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    ok($ctx, 'created context');
    
    # Create logits tensor [vocab_size=5]
    my $logits = Lugh::Autograd::Tensor->new($ctx, 'f32', 5, { requires_grad => 1 });
    $logits->set_data(1.0, 2.0, 3.0, 4.0, 5.0);
    ok($logits, 'created logits tensor');
    ok($logits->requires_grad, 'logits requires grad');
    
    # Compute cross-entropy with target class 4 (highest logit)
    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, [4]);
    ok($loss, 'computed cross-entropy loss');
    
    my @loss_data = $loss->get_data();
    is(scalar(@loss_data), 1, 'loss is scalar');
    
    # For target=4 (highest logit), loss should be relatively low
    cmp_ok($loss_data[0], '>', 0, 'loss is positive');
    cmp_ok($loss_data[0], '<', 2, 'loss is reasonable for correct class');
    
    done_testing();
};

subtest 'cross_entropy_loss backward' => sub {
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    
    my $logits = Lugh::Autograd::Tensor->new($ctx, 'f32', 5, { requires_grad => 1 });
    $logits->set_data(0.0, 0.0, 0.0, 0.0, 0.0);  # uniform logits
    
    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, [2]);  # target class 2
    ok($loss->requires_grad, 'loss requires grad');
    
    # Backward pass
    lives_ok { $loss->backward() } 'backward pass succeeds';
    
    # Check gradients
    my $grad = $logits->grad();
    is(scalar(@$grad), 5, 'got 5 gradients');
    
    # For uniform logits, softmax = [0.2, 0.2, 0.2, 0.2, 0.2]
    # Gradient = softmax - one_hot = [0.2, 0.2, -0.8, 0.2, 0.2]
    cmp_ok($grad->[0], '>', 0, 'grad[0] > 0 (non-target)');
    cmp_ok($grad->[1], '>', 0, 'grad[1] > 0 (non-target)');
    cmp_ok($grad->[2], '<', 0, 'grad[2] < 0 (target class)');
    cmp_ok($grad->[3], '>', 0, 'grad[3] > 0 (non-target)');
    cmp_ok($grad->[4], '>', 0, 'grad[4] > 0 (non-target)');
    
    # Sum of gradients should be approximately 0
    my $grad_sum = 0;
    $grad_sum += $_ for @$grad;
    cmp_ok(abs($grad_sum), '<', 0.001, 'gradients sum to ~0');
    
    done_testing();
};

subtest 'cross_entropy_loss batch' => sub {
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    
    # Batch of 3 with vocab_size=4 = 12 elements
    my $logits = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, 3, { requires_grad => 1 });
    $logits->set_data(
        1.0, 0.0, 0.0, 0.0,  # batch 0: class 0 highest
        0.0, 2.0, 0.0, 0.0,  # batch 1: class 1 highest  
        0.0, 0.0, 3.0, 0.0   # batch 2: class 2 highest
    );
    
    # Targets matching the highest logits
    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, [0, 1, 2]);
    ok($loss, 'batch cross-entropy computed');
    
    my @loss_data = $loss->get_data();
    cmp_ok($loss_data[0], '>', 0, 'batch loss is positive');
    
    done_testing();
};

# =============================================================================
# MSE LOSS TESTS
# =============================================================================

subtest 'mse_loss basic' => sub {
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    
    my $predictions = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $predictions->set_data(1.0, 2.0, 3.0);
    
    my $targets = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 0 });
    $targets->set_data(1.0, 2.0, 3.0);  # same as predictions
    
    my $loss = Lugh::Train->mse_loss($ctx, $predictions, $targets);
    ok($loss, 'computed MSE loss');
    
    my @loss_data = $loss->get_data();
    # Perfect predictions: MSE = 0
    cmp_ok(abs($loss_data[0]), '<', 0.0001, 'MSE is ~0 for perfect predictions');
    
    done_testing();
};

subtest 'mse_loss with error' => sub {
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    
    my $predictions = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $predictions->set_data(1.0, 2.0, 3.0);
    
    my $targets = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 0 });
    $targets->set_data(2.0, 3.0, 4.0);  # each off by 1
    
    my $loss = Lugh::Train->mse_loss($ctx, $predictions, $targets);
    my @loss_data = $loss->get_data();
    
    # MSE = mean((1-2)^2 + (2-3)^2 + (3-4)^2) = mean(1 + 1 + 1) = 1.0
    cmp_ok(abs($loss_data[0] - 1.0), '<', 0.0001, 'MSE = 1.0 for unit errors');
    
    done_testing();
};

subtest 'mse_loss backward' => sub {
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    
    my $predictions = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $predictions->set_data(1.0, 2.0, 3.0);
    
    my $targets = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 0 });
    $targets->set_data(2.0, 2.0, 2.0);  # target = 2 for all
    
    my $loss = Lugh::Train->mse_loss($ctx, $predictions, $targets);
    lives_ok { $loss->backward() } 'MSE backward succeeds';
    
    my $grad = $predictions->grad();
    is(scalar(@$grad), 3, 'got 3 gradients');
    
    # dL/d(pred) = 2*(pred - target)/n
    cmp_ok($grad->[0], '<', 0, 'grad[0] < 0 (pred < target)');
    cmp_ok(abs($grad->[1]), '<', 0.001, 'grad[1] ≈ 0 (pred = target)');
    cmp_ok($grad->[2], '>', 0, 'grad[2] > 0 (pred > target)');
    
    # grad[0] + grad[2] should be ~0 (symmetric around target)
    cmp_ok(abs($grad->[0] + $grad->[2]), '<', 0.001, 'gradients symmetric');
    
    done_testing();
};

# =============================================================================
# BATCH DATA UTILITY TESTS
# =============================================================================

subtest 'batch_data' => sub {
    my @data = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    
    # Batch size 3
    my @batches = Lugh::Train->batch_data(\@data, batch_size => 3);
    is(scalar(@batches), 4, 'got 4 batches for 10 items with batch_size=3');
    is_deeply($batches[0], [1, 2, 3], 'first batch correct');
    is_deeply($batches[1], [4, 5, 6], 'second batch correct');
    is_deeply($batches[2], [7, 8, 9], 'third batch correct');
    is_deeply($batches[3], [10], 'last batch has remainder');
    
    # Batch size 5
    @batches = Lugh::Train->batch_data(\@data, batch_size => 5);
    is(scalar(@batches), 2, 'got 2 batches for 10 items with batch_size=5');
    is(scalar(@{$batches[0]}), 5, 'first batch has 5 items');
    is(scalar(@{$batches[1]}), 5, 'second batch has 5 items');
    
    done_testing();
};

subtest 'batch_data shuffle' => sub {
    my @data = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
    
    srand(42);  # Deterministic for testing
    my @batches1 = Lugh::Train->batch_data(\@data, batch_size => 3, shuffle => 1);
    
    srand(42);  # Same seed
    my @batches2 = Lugh::Train->batch_data(\@data, batch_size => 3, shuffle => 1);
    
    # Same seed should give same order
    is_deeply(\@batches1, \@batches2, 'same seed gives same shuffle');
    
    # Different from unshuffled (very likely)
    my @unshuffled = Lugh::Train->batch_data(\@data, batch_size => 3, shuffle => 0);
    my $same_as_unshuffled = 1;
    for my $i (0 .. $#batches1) {
        if (!eq_array($batches1[$i], $unshuffled[$i])) {
            $same_as_unshuffled = 0;
            last;
        }
    }
    ok(!$same_as_unshuffled || @data <= 2, 'shuffled differs from unshuffled (usually)');
    
    done_testing();
};

# =============================================================================
# ZERO_GRAD TEST
# =============================================================================

subtest 'zero_grad' => sub {
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    
    my $tensor = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $tensor->set_data(1.0, 2.0, 3.0);
    
    # Create a computation to generate gradients
    my $result = Lugh::Autograd::Ops->sum($ctx, $tensor);
    compute_tensor($ctx, $result);
    $result->backward();
    
    my $grad_before = $tensor->grad();
    my $has_nonzero = scalar(grep { $_ != 0 } @$grad_before) > 0;
    ok($has_nonzero, 'has non-zero gradients before zero_grad');
    
    # Test the zero_grad utility
    lives_ok { Lugh::Train->zero_grad($tensor) } 'zero_grad runs without error';
    
    done_testing();
};

# =============================================================================
# ERROR HANDLING TESTS
# =============================================================================

subtest 'error handling' => sub {
    my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
    
    my $logits = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $logits->set_data(1.0, 2.0, 3.0);
    
    # Wrong number of targets
    dies_ok {
        Lugh::Train->cross_entropy_loss($ctx, $logits, [0, 1]);  # 2 targets for 1 batch
    } 'dies on target count mismatch';
    
    # Target out of range
    dies_ok {
        Lugh::Train->cross_entropy_loss($ctx, $logits, [5]);  # class 5 doesn't exist
    } 'dies on target out of range';
    
    # MSE shape mismatch
    my $pred = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $pred->set_data(1.0, 2.0, 3.0);
    
    my $tgt = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, { requires_grad => 0 });
    $tgt->set_data(1.0, 2.0);
    
    dies_ok {
        Lugh::Train->mse_loss($ctx, $pred, $tgt);
    } 'dies on MSE shape mismatch';
    
    done_testing();
};

# =============================================================================
# INTEGRATION TEST WITH MODEL
# =============================================================================

subtest 'training loop integration' => sub {
    # Skip if model not available
    plan skip_all => 'Test model not found' unless -f TEST_MODEL;
    
    my $ctx = Lugh::Context->new(mem_size => 128 * 1024 * 1024);
    my $model = Lugh::Model->new(path => TEST_MODEL);
    ok($model, 'loaded test model');
    
    # Use a fixed vocab size for testing
    my $vocab_size = 1000;
    
    # Create simple logits tensor
    my $logits = Lugh::Autograd::Tensor->new($ctx, 'f32', $vocab_size, { requires_grad => 1 });
    my @logits_data = map { rand() - 0.5 } (1 .. $vocab_size);
    $logits->set_data(@logits_data);
    
    # Random target
    my $target = int(rand($vocab_size));
    
    # Compute loss
    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, [$target]);
    ok($loss, 'computed loss with vocab size');
    
    my @loss_val = $loss->get_data();
    cmp_ok($loss_val[0], '>', 0, 'loss is positive');
    
    # Backward
    lives_ok { $loss->backward() } 'backward on large tensor';
    
    my $grad = $logits->grad();
    is(scalar(@$grad), $vocab_size, "got $vocab_size gradients");
    
    done_testing();
};

done_testing();
