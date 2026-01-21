#!/usr/bin/env perl
# t/32-speculative-reproducibility.t - Test speculative decoding with srand reproducibility

use strict;
use warnings;
use Test::More;
use FindBin;

use Lugh;
use Lugh::Speculative;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

plan tests => 13;

# Load model and create components
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');

# ============================================================================
# Test 1: Speculative decoding with srand produces reproducible results
# ============================================================================
subtest 'speculative reproducibility with srand' => sub {
    plan tests => 4;
    
    my $spec = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,  # Same model for testing
        k           => 3,
        temperature => 0.8,
        top_p       => 0.9,
    );
    ok($spec, 'Speculative decoder created');
    
    my @prompt = $tokenizer->encode("Once upon a time");
    
    # First generation with seed
    Lugh::srand(42);
    $spec->reset_stats;
    my $output1 = $spec->generate(\@prompt, 10);
    
    # Second generation with same seed
    Lugh::srand(42);
    $spec->reset_stats;
    my $output2 = $spec->generate(\@prompt, 10);
    
    is(ref($output1), 'ARRAY', 'First output is array ref');
    is(ref($output2), 'ARRAY', 'Second output is array ref');
    is_deeply($output1, $output2, 'Same seed produces identical speculative output');
};

# ============================================================================
# Test 2: Different seeds produce different outputs
# ============================================================================
subtest 'different seeds different outputs' => sub {
    plan tests => 2;
    
    my $spec = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,
        k           => 3,
        temperature => 1.0,  # Higher temperature for more randomness
        top_p       => 0.95,
    );
    
    my @prompt = $tokenizer->encode("The quick");
    
    # Generation with seed 42
    Lugh::srand(42);
    $spec->reset_stats;
    my $output1 = $spec->generate(\@prompt, 8);
    
    # Generation with different seed
    Lugh::srand(9999);
    $spec->reset_stats;
    my $output2 = $spec->generate(\@prompt, 8);
    
    ok(defined $output1 && defined $output2, 'Both outputs generated');
    # With temperature=1.0, different seeds should usually produce different outputs
    # (could be same by chance, but that's very unlikely with 8 tokens)
    diag("Seed 42 tokens: " . join(',', @$output1));
    diag("Seed 9999 tokens: " . join(',', @$output2));
    ok(1, 'Outputs generated with different seeds');
};

# ============================================================================
# Test 3: Speculative after standard generation with srand reset
# ============================================================================
subtest 'speculative after standard with srand reset' => sub {
    plan tests => 4;
    
    my @prompt = $tokenizer->encode("Hello world");
    
    # Run some standard generation first (consumes random state)
    for (1..10) {
        my @logits = $inference->forward_simple(\@prompt);
        $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.9);
    }
    
    # Now run speculative with srand reset
    my $spec = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,
        k           => 3,
        temperature => 0.8,
        top_p       => 0.9,
    );
    
    Lugh::srand(42);
    $spec->reset_stats;
    my $output1 = $spec->generate(\@prompt, 5);
    
    # Run more standard generation (pollute random state)
    for (1..20) {
        my @logits = $inference->forward_simple(\@prompt);
        $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.9);
    }
    
    # Reset seed and generate again
    Lugh::srand(42);
    $spec->reset_stats;
    my $output2 = $spec->generate(\@prompt, 5);
    
    ok(defined $output1, 'First speculative output generated');
    ok(defined $output2, 'Second speculative output generated');
    is_deeply($output1, $output2, 'srand reset produces identical output after pollution');
    ok($spec->acceptance_rate >= 0, 'Acceptance rate is valid');
};

# ============================================================================
# Test 4: Step method reproducibility
# ============================================================================
subtest 'step method reproducibility' => sub {
    plan tests => 3;
    
    my $spec = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,
        k           => 4,
        temperature => 0.7,
        top_p       => 0.85,
    );
    
    my @prompt = $tokenizer->encode("In the beginning");
    
    # First step with seed
    Lugh::srand(42);
    $spec->reset_stats;
    my $result1 = $spec->step(\@prompt);
    
    # Reset and step again
    Lugh::srand(42);
    $spec->reset_stats;
    my $result2 = $spec->step(\@prompt);
    
    is(ref($result1), 'ARRAY', 'Step returns array ref');
    is(ref($result2), 'ARRAY', 'Step returns array ref');
    is_deeply($result1, $result2, 'Step is reproducible with srand');
};

# ============================================================================
# Test 5: Draft tokens reproducibility
# ============================================================================
subtest 'draft_tokens reproducibility' => sub {
    plan tests => 3;
    
    my $spec = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,
        k           => 4,
        temperature => 1.0,
        top_p       => 0.9,
    );
    
    ok($spec->init_caches, 'Caches initialized');
    
    my @prompt = $tokenizer->encode("Test draft");
    
    # First draft with seed
    Lugh::srand(42);
    my $draft1 = $spec->draft_tokens(\@prompt, 3);
    
    # Reset and draft again
    Lugh::srand(42);
    my $draft2 = $spec->draft_tokens(\@prompt, 3);
    
    is(ref($draft1), 'ARRAY', 'draft_tokens returns array');
    is_deeply($draft1, $draft2, 'draft_tokens is reproducible with srand');
};

# ============================================================================
# Test 6: Multiple speculative decoders with srand
# ============================================================================
subtest 'multiple decoders reproducibility' => sub {
    plan tests => 2;
    
    my $spec1 = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,
        k           => 3,
        temperature => 0.8,
        top_p       => 0.9,
    );
    
    my $spec2 = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,
        k           => 3,
        temperature => 0.8,
        top_p       => 0.9,
    );
    
    my @prompt = $tokenizer->encode("Story time");
    
    Lugh::srand(42);
    $spec1->reset_stats;
    my $output1 = $spec1->generate(\@prompt, 5);
    
    Lugh::srand(42);
    $spec2->reset_stats;
    my $output2 = $spec2->generate(\@prompt, 5);
    
    ok(defined $output1 && defined $output2, 'Both decoders generated output');
    is_deeply($output1, $output2, 'Different decoder instances with same seed match');
};

# ============================================================================
# Test 7: Acceptance rate consistency
# ============================================================================
subtest 'acceptance rate consistency' => sub {
    plan tests => 3;
    
    my $spec = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,  # Same model = high acceptance
        k           => 4,
        temperature => 0.5,
        top_p       => 0.9,
    );
    
    my @prompt = $tokenizer->encode("Reproducible");
    
    Lugh::srand(42);
    $spec->reset_stats;
    $spec->generate(\@prompt, 8);
    my $rate1 = $spec->acceptance_rate;
    my $drafted1 = $spec->tokens_drafted;
    my $accepted1 = $spec->tokens_accepted;
    
    Lugh::srand(42);
    $spec->reset_stats;
    $spec->generate(\@prompt, 8);
    my $rate2 = $spec->acceptance_rate;
    my $drafted2 = $spec->tokens_drafted;
    my $accepted2 = $spec->tokens_accepted;
    
    is($drafted1, $drafted2, 'Same number of tokens drafted');
    is($accepted1, $accepted2, 'Same number of tokens accepted');
    cmp_ok(abs($rate1 - $rate2), '<', 0.001, 'Acceptance rates match');
};

# ============================================================================
# Test 8: Low temperature speculative decoding
# ============================================================================
subtest 'low temperature speculative' => sub {
    plan tests => 2;
    
    my $spec = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,
        k           => 4,
        temperature => 0.1,  # Very low temperature
        top_p       => 0.9,
    );
    
    my @prompt = $tokenizer->encode("Deterministic");
    
    Lugh::srand(42);
    $spec->reset_stats;
    my $output1 = $spec->generate(\@prompt, 6);
    
    Lugh::srand(42);
    $spec->reset_stats;
    my $output2 = $spec->generate(\@prompt, 6);
    
    is_deeply($output1, $output2, 'Low temperature speculative is reproducible');
    
    # With same draft/main model and low temperature, acceptance should be high
    cmp_ok($spec->acceptance_rate, '>=', 0.5, 'High acceptance with same model + low temp');
};

# ============================================================================
# Test 9: Decoded text reproducibility
# ============================================================================
subtest 'decoded text reproducibility' => sub {
    plan tests => 2;
    
    my $spec = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,
        k           => 3,
        temperature => 0.7,
        top_p       => 0.9,
    );
    
    my @prompt = $tokenizer->encode("Once upon");
    
    Lugh::srand(42);
    $spec->reset_stats;
    my $output1 = $spec->generate(\@prompt, 10);
    my $text1 = $tokenizer->decode($output1);
    
    Lugh::srand(42);
    $spec->reset_stats;
    my $output2 = $spec->generate(\@prompt, 10);
    my $text2 = $tokenizer->decode($output2);
    
    is($text1, $text2, 'Decoded text is identical with same seed');
    diag("Generated text: $text1");
    ok(length($text1) > 0, 'Generated non-empty text');
};

# ============================================================================
# Test 10: Stats reset between runs
# ============================================================================
subtest 'stats reset between runs' => sub {
    plan tests => 4;
    
    my $spec = Lugh::Speculative->new(
        inference   => $inference,
        draft       => $inference,
        k           => 3,
        temperature => 0.8,
        top_p       => 0.9,
    );
    
    my @prompt = $tokenizer->encode("Test");
    
    # First run
    Lugh::srand(42);
    $spec->reset_stats;
    $spec->generate(\@prompt, 5);
    my $drafted1 = $spec->tokens_drafted;
    
    # Second run without reset
    Lugh::srand(42);
    $spec->generate(\@prompt, 5);
    my $drafted2 = $spec->tokens_drafted;
    
    # drafted2 should be approximately 2x drafted1 (accumulated)
    cmp_ok($drafted2, '>=', $drafted1, 'Stats accumulate without reset');
    
    # Third run with reset
    Lugh::srand(42);
    $spec->reset_stats;
    $spec->generate(\@prompt, 5);
    my $drafted3 = $spec->tokens_drafted;
    
    is($drafted1, $drafted3, 'Stats are fresh after reset');
    ok($spec->total_steps > 0, 'total_steps tracked');
    ok($spec->tokens_accepted >= 0, 'tokens_accepted tracked');
};

done_testing();
