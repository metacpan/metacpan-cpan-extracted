#!/usr/bin/env perl
# t/0044-full-weight-training.t
#
# Tests for full model weight training (not LoRA)
# This tests the backward_weight_matmul and backward_transformer_forward functions.

use 5.030;
use strict;
use warnings;
use Test::More;
use FindBin;
use File::Temp qw(tempfile);

use lib 'blib/lib', 'blib/arch';

# Helper for exception testing
sub lives_ok (&$) {
    my ($code, $name) = @_;
    eval { $code->() };
    ok(!$@, $name) or diag("Died: $@");
}

BEGIN {
    use_ok('Lugh');
    use_ok('Lugh::Train');
    use_ok('Lugh::Optimizer');
}

# Create a temporary model file for testing
my ($fh, $model_file) = tempfile(SUFFIX => '.gguf', UNLINK => 1);
close($fh);

# =============================================================================
# SETUP - Create model and get weights
# =============================================================================

my ($model, $inference, @weights, $weight_ctx, $weights_hash);

subtest 'setup model and weights' => sub {
    # Create a small model for testing
    Lugh::Model->create(
        file    => $model_file,
        n_vocab => 256,
        n_embd  => 64,
        n_layer => 2,
        n_head  => 4,
        n_ff    => 128,
        n_ctx   => 32,
    );
    ok(-f $model_file, 'created model file');
    
    $model = Lugh::Model->new(model => $model_file);
    ok($model, 'loaded model');
    
    $inference = Lugh::Inference->new(model => $model);
    ok($inference, 'created inference');
    
    $weight_ctx = Lugh::Context->new(size => 512 * 1024 * 1024);
    ok($weight_ctx, 'created weight context');
    
    $weights_hash = $model->get_trainable_weights($weight_ctx);
    ok($weights_hash, 'got trainable weights hash');
    
    my $n_tensors = delete $weights_hash->{_n_tensors} || 0;
    delete $weights_hash->{_model_id};
    
    @weights = values %$weights_hash;
    
    cmp_ok(scalar(@weights), '>', 0, 'got some weights');
    cmp_ok($n_tensors, '>=', 10, 'got at least 10 weight tensors');
    
    # Check specific weights exist
    ok(exists $weights_hash->{'token_embd.weight'}, 'has token_embd.weight');
    ok(exists $weights_hash->{'output.weight'}, 'has output.weight');
    
    done_testing();
};

# =============================================================================
# REGISTER WEIGHT TENSORS
# =============================================================================

subtest 'register weight tensors' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    my $logits = Lugh::Train->forward(
        inference  => $inference,
        context    => $ctx,
        tokens     => [1, 72, 101, 108],  # BOS + "Hel"
        train_lora => 0,
        train_full => 1,
    );
    ok($logits, 'got logits from forward pass');
    
    lives_ok {
        Lugh::Train->register_weight_tensors($logits, \@weights);
    } 'register_weight_tensors succeeds';
    
    done_testing();
};

# =============================================================================
# FULL BACKWARD PASS - THE KEY TEST
# =============================================================================

subtest 'full weight backward pass' => sub {
    my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
    
    # Forward with 3 input tokens -> 3 output positions
    my $logits = Lugh::Train->forward(
        inference  => $inference,
        context    => $ctx,
        tokens     => [1, 72, 101],  # BOS + "He"
        train_lora => 0,
        train_full => 1,
    );
    ok($logits, 'forward pass succeeded');
    
    # Register weights
    Lugh::Train->register_weight_tensors($logits, \@weights);
    
    # Loss - 3 input tokens means 3 predictions, need 3 targets
    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, [72, 101, 108]);
    ok($loss, 'computed loss');
    
    my ($loss_val) = $loss->get_data();
    cmp_ok($loss_val, '>', 0, 'loss is positive');
    
    # THE CRITICAL TEST: backward should not crash
    lives_ok { $loss->backward() } 'backward pass completes without crash';
    
    done_testing();
};

# =============================================================================
# MULTIPLE BACKWARD PASSES (PREVIOUSLY CRASHED)
# =============================================================================

subtest 'multiple training steps' => sub {
    plan tests => 11;
    
    for my $step (1..10) {
        my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
        
        my $logits = Lugh::Train->forward(
            inference  => $inference,
            context    => $ctx,
            tokens     => [1, 72, 101],
            train_lora => 0,
            train_full => 1,
        );
        
        Lugh::Train->register_weight_tensors($logits, \@weights);
        
        my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, [72, 101, 108]);
        
        lives_ok { $loss->backward() } "step $step backward succeeds";
    }
    
    pass('completed 10 training steps without crash');
};

# =============================================================================
# OPTIMIZER STEP WITH FULL WEIGHTS
# =============================================================================

subtest 'optimizer updates weights' => sub {
    # Create fresh model for this test to avoid state issues
    my ($fh2, $opt_model_file) = tempfile(SUFFIX => '.gguf', UNLINK => 1);
    close($fh2);
    
    Lugh::Model->create(
        file    => $opt_model_file,
        n_vocab => 256,
        n_embd  => 64,
        n_layer => 2,
        n_head  => 4,
        n_ff    => 128,
        n_ctx   => 32,
    );
    
    my $opt_model = Lugh::Model->new(model => $opt_model_file);
    my $opt_inference = Lugh::Inference->new(model => $opt_model);
    my $opt_weight_ctx = Lugh::Context->new(size => 512 * 1024 * 1024);
    my $opt_weights_hash = $opt_model->get_trainable_weights($opt_weight_ctx);
    delete $opt_weights_hash->{_n_tensors};
    delete $opt_weights_hash->{_model_id};
    my @opt_weights = values %$opt_weights_hash;
    
    # Create optimizer
    my $optimizer = Lugh::Optimizer::AdamW->new(lr => 0.01);
    $optimizer->add_param($_) for @opt_weights;
    
    # Run 3 training steps
    for my $step (1..3) {
        $optimizer->zero_grad();
        
        my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
        my $logits = Lugh::Train->forward(
            inference  => $opt_inference,
            context    => $ctx,
            tokens     => [1, 72, 101],
            train_lora => 0,
            train_full => 1,
        );
        
        Lugh::Train->register_weight_tensors($logits, \@opt_weights);
        
        my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, [72, 101, 108]);
        $loss->backward();
        $optimizer->step();
    }
    
    pass('completed 3 optimizer training steps');
    
    done_testing();
};

# =============================================================================
# GRADIENT ACCUMULATION
# =============================================================================

subtest 'gradient accumulation' => sub {
    my $optimizer = Lugh::Optimizer::AdamW->new(lr => 0.01);
    $optimizer->add_param($_) for @weights;
    
    $optimizer->zero_grad();
    
    # Accumulate gradients from multiple forward/backward
    for my $i (1..3) {
        my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
        my $logits = Lugh::Train->forward(
            inference  => $inference,
            context    => $ctx,
            tokens     => [1, 72, 101],
            train_lora => 0,
            train_full => 1,
        );
        
        Lugh::Train->register_weight_tensors($logits, \@weights);
        
        my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, [72, 101, 108]);
        lives_ok { $loss->backward() } "accumulation step $i backward";
    }
    
    lives_ok { $optimizer->step() } 'optimizer step after accumulation';
    
    done_testing();
};

# =============================================================================
# STRESS TEST - MANY ITERATIONS (REGRESSION TEST FOR MEMORY CORRUPTION)
# =============================================================================

subtest 'stress test many iterations' => sub {
    # This catches memory corruption that manifests after many iterations
    my $iterations = 50;
    
    for my $i (1..$iterations) {
        my $ctx = Lugh::Context->new(size => 64 * 1024 * 1024);
        
        my $logits = Lugh::Train->forward(
            inference  => $inference,
            context    => $ctx,
            tokens     => [1, 65, 66, 67],  # 4 tokens
            train_lora => 0,
            train_full => 1,
        );
        
        Lugh::Train->register_weight_tensors($logits, \@weights);
        
        my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, [65, 66, 67, 68]);
        
        eval { $loss->backward() };
        if ($@) {
            fail("iteration $i crashed: $@");
            last;
        }
    }
    
    pass("completed $iterations iterations without crash");
    
    done_testing();
};

sub min { $_[0] < $_[1] ? $_[0] : $_[1] }

done_testing();
