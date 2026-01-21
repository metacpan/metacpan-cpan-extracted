#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;

# Find the test data directory
my $test_dir = File::Spec->catdir('t', 'data');
my $model_path = File::Spec->catfile($test_dir, 'test-model.gguf');

# Skip if no model available
unless (-f $model_path) {
    plan skip_all => "No test model available at $model_path";
}

use_ok('Lugh');
use_ok('Lugh::Model');
use_ok('Lugh::Inference');
use_ok('Lugh::Speculative');

# ============================================================================
# Test 1: Constructor validation
# ============================================================================
subtest 'constructor validation' => sub {
    plan tests => 6;
    
    # Load model for main inference
    my $model = Lugh::Model->new(path => $model_path);
    ok($model, 'loaded main model');
    
    my $inference = Lugh::Inference->new(model => $model);
    ok($inference, 'created main inference');
    
    # Test missing inference
    eval { Lugh::Speculative->new(draft => $inference) };
    like($@, qr/requires.*inference/, 'dies without main inference');
    
    # Test missing draft
    eval { Lugh::Speculative->new(inference => $inference) };
    like($@, qr/requires.*draft/, 'dies without draft inference');
    
    # Test with same model for both (valid - same vocab)
    my $spec = Lugh::Speculative->new(
        inference => $inference,
        draft     => $inference,
        k         => 3,
    );
    ok($spec, 'created speculative decoder with same model');
    isa_ok($spec, 'Lugh::Speculative');
};

# ============================================================================
# Test 2: Accessors
# ============================================================================
subtest 'accessors' => sub {
    plan tests => 4;
    
    my $model = Lugh::Model->new(path => $model_path);
    my $inference = Lugh::Inference->new(model => $model);
    
    my $spec = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,
        k           => 5,
        temperature => 0.7,
        top_p       => 0.9,
    );
    
    is($spec->k, 5, 'k accessor');
    # Use cmp_ok for floating point tolerance
    cmp_ok(abs($spec->temperature - 0.7), '<', 0.001, 'temperature accessor');
    cmp_ok(abs($spec->top_p - 0.9), '<', 0.001, 'top_p accessor');
    ok($spec->n_vocab > 0, 'n_vocab is positive');
};

# ============================================================================
# Test 3: Statistics
# ============================================================================
subtest 'statistics' => sub {
    plan tests => 5;
    
    my $model = Lugh::Model->new(path => $model_path);
    my $inference = Lugh::Inference->new(model => $model);
    
    my $spec = Lugh::Speculative->new(
        inference => $inference,
        draft     => $inference,
        k         => 4,
    );
    
    # Initial stats should be zero
    is($spec->tokens_drafted, 0, 'initial tokens_drafted is 0');
    is($spec->tokens_accepted, 0, 'initial tokens_accepted is 0');
    is($spec->total_steps, 0, 'initial total_steps is 0');
    is($spec->acceptance_rate, 0, 'initial acceptance_rate is 0');
    
    # Reset stats should work
    $spec->reset_stats;
    is($spec->tokens_drafted, 0, 'stats reset');
};

# ============================================================================
# Test 4: Invalid k values
# ============================================================================
subtest 'k validation' => sub {
    plan tests => 2;
    
    my $model = Lugh::Model->new(path => $model_path);
    my $inference = Lugh::Inference->new(model => $model);
    
    # k too small
    eval {
        Lugh::Speculative->new(
            inference => $inference,
            draft     => $inference,
            k         => 0,
        );
    };
    like($@, qr/k must be between/, 'k=0 rejected');
    
    # k too large
    eval {
        Lugh::Speculative->new(
            inference => $inference,
            draft     => $inference,
            k         => 20,
        );
    };
    like($@, qr/k must be between/, 'k=20 rejected');
};

# ============================================================================
# Test 5: Init caches
# ============================================================================
subtest 'init_caches' => sub {
    plan tests => 2;
    
    my $model = Lugh::Model->new(path => $model_path);
    my $inference = Lugh::Inference->new(model => $model);
    
    my $spec = Lugh::Speculative->new(
        inference => $inference,
        draft     => $inference,
        k         => 4,
    );
    
    # Init caches
    my $result = $spec->init_caches;
    ok($result, 'init_caches succeeded');
    
    # Second call should also succeed (returns immediately)
    $result = $spec->init_caches;
    ok($result, 'init_caches second call succeeded');
};

# ============================================================================
# Test 6: Draft tokens
# ============================================================================
subtest 'draft_tokens' => sub {
    plan tests => 5;
    
    my $model = Lugh::Model->new(path => $model_path);
    my $inference = Lugh::Inference->new(model => $model);
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    
    my $spec = Lugh::Speculative->new(
        inference => $inference,
        draft     => $inference,
        k         => 4,
    );
    
    # Initialize caches first
    ok($spec->init_caches, 'init_caches for draft_tokens');
    
    # Encode some real tokens
    my @input = $tokenizer->encode("Hello");
    ok(scalar(@input) > 0, 'got input tokens');
    
    # Call draft_tokens
    my $draft = $spec->draft_tokens(\@input, 3);
    ok(defined $draft, 'draft_tokens returned result');
    is(ref($draft), 'ARRAY', 'draft_tokens returns array ref');
    ok($spec->tokens_drafted > 0, 'tokens_drafted counter updated');
};

# ============================================================================
# Test 7: Verify tokens
# ============================================================================
subtest 'verify_tokens' => sub {
    plan tests => 5;
    
    my $model = Lugh::Model->new(path => $model_path);
    my $inference = Lugh::Inference->new(model => $model);
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    
    my $spec = Lugh::Speculative->new(
        inference => $inference,
        draft     => $inference,
        k         => 4,
    );
    
    ok($spec->init_caches, 'init_caches for verify_tokens');
    
    my @input = $tokenizer->encode("Hello");
    ok(scalar(@input) > 0, 'got input tokens');
    
    # First generate some draft tokens, then verify them
    my $draft = $spec->draft_tokens(\@input, 2);
    ok(defined $draft && ref($draft) eq 'ARRAY', 'got draft tokens to verify');
    
    my $accepted = $spec->verify_tokens(\@input, $draft);
    ok(defined $accepted, 'verify_tokens returned result');
    is(ref($accepted), 'ARRAY', 'verify_tokens returns array ref');
};

# ============================================================================
# Test 8: Step method
# ============================================================================
subtest 'step method' => sub {
    plan tests => 5;
    
    my $model = Lugh::Model->new(path => $model_path);
    my $inference = Lugh::Inference->new(model => $model);
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    
    my $spec = Lugh::Speculative->new(
        inference => $inference,
        draft     => $inference,
        k         => 3,
    );
    
    my @input = $tokenizer->encode("Once upon");
    ok(scalar(@input) > 0, 'got input tokens');
    
    my $result = $spec->step(\@input);
    ok(defined $result, 'step returned result');
    is(ref($result), 'ARRAY', 'step returns array ref');
    ok($spec->total_steps > 0, 'step updated total_steps');
    ok($spec->tokens_drafted > 0, 'step updated tokens_drafted');
};

# ============================================================================
# Test 9: Generate method
# ============================================================================
subtest 'generate method' => sub {
    plan tests => 6;
    
    my $model = Lugh::Model->new(path => $model_path);
    my $inference = Lugh::Inference->new(model => $model);
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    
    my $spec = Lugh::Speculative->new(
        inference => $inference,
        draft     => $inference,
        k         => 3,
    );
    
    my @input = $tokenizer->encode("The quick brown");
    ok(scalar(@input) > 0, 'got input tokens');
    
    my $output = $spec->generate(\@input, 10);  # Generate up to 10 tokens
    ok(defined $output, 'generate returned result');
    is(ref($output), 'ARRAY', 'generate returns array ref');
    ok(scalar(@$output) > 0, 'generate produced tokens');
    ok($spec->total_steps > 0, 'generate updated total_steps');
    ok($spec->tokens_accepted > 0, 'generate accepted tokens (same model = high acceptance)');
};

# ============================================================================
# Test 10: Vocab mismatch detection (would need two different models)
# ============================================================================
subtest 'vocab mismatch' => sub {
    plan tests => 1;
    
    # With same model, no mismatch
    my $model = Lugh::Model->new(path => $model_path);
    my $inference = Lugh::Inference->new(model => $model);
    
    my $spec = Lugh::Speculative->new(
        inference => $inference,
        draft     => $inference,
        k         => 4,
    );
    
    ok($spec, 'same model has matching vocab');
    
    # To test vocab mismatch, we'd need two models with different vocabs
    # which we don't have in the test suite
};

done_testing();
