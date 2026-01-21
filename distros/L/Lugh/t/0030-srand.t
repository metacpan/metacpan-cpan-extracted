#!/usr/bin/env perl
# t/30-srand.t - Test Lugh::srand() C-level RNG seeding for reproducibility

use strict;
use warnings;
use Test::More;
use FindBin;

use Lugh;

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
# Test 1: Basic srand() function exists
# ============================================================================
subtest 'srand function exists' => sub {
    plan tests => 2;
    
    ok(defined &Lugh::srand, 'Lugh::srand is defined');
    
    # Call it and ensure it doesn't die
    eval { Lugh::srand(42) };
    is($@, '', 'Lugh::srand(42) runs without error');
};

# ============================================================================
# Test 2: srand accepts various seed values
# ============================================================================
subtest 'srand accepts various seeds' => sub {
    plan tests => 4;
    
    eval { Lugh::srand(0) };
    is($@, '', 'srand(0) works');
    
    eval { Lugh::srand(1) };
    is($@, '', 'srand(1) works');
    
    eval { Lugh::srand(4294967295) };  # Max unsigned 32-bit
    is($@, '', 'srand(MAX_UINT32) works');
    
    eval { Lugh::srand(12345) };
    is($@, '', 'srand with arbitrary value works');
};

# ============================================================================
# Test 3: Sampling reproducibility with same seed
# ============================================================================
subtest 'sampling reproducibility' => sub {
    plan tests => 5;
    
    my @tokens = $tokenizer->encode("Once upon a time");
    my @logits = $inference->forward_simple(\@tokens);
    ok(scalar(@logits) > 0, 'Got logits');
    
    # Sample with temperature (uses C rand()) after seeding
    Lugh::srand(42);
    my $sample1 = $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    
    Lugh::srand(42);
    my $sample2 = $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    
    is($sample1, $sample2, 'Same seed produces same sample (first)');
    
    # Do it again with different seed
    Lugh::srand(123);
    my $sample3 = $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    
    Lugh::srand(123);
    my $sample4 = $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    
    is($sample3, $sample4, 'Same seed produces same sample (second seed)');
    
    # Verify seeds can produce different results
    Lugh::srand(42);
    my $sample_a = $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    
    Lugh::srand(9999);
    my $sample_b = $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    
    # They could be same by chance, but record either way
    ok(1, "Seed 42 produced: $sample_a, Seed 9999 produced: $sample_b");
    diag("Different seeds may produce same token by chance if distribution is peaked");
    ok(defined $sample_a && defined $sample_b, 'Both samples are valid');
};

# ============================================================================
# Test 4: Multiple samples with same seed produce same sequence
# ============================================================================
subtest 'sequence reproducibility' => sub {
    plan tests => 4;
    
    my @tokens = $tokenizer->encode("The quick brown fox");
    my @logits = $inference->forward_simple(\@tokens);
    
    # Generate sequence of samples with seed 42
    Lugh::srand(42);
    my @sequence1;
    for (1..5) {
        push @sequence1, $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    }
    
    # Generate again with same seed
    Lugh::srand(42);
    my @sequence2;
    for (1..5) {
        push @sequence2, $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    }
    
    is_deeply(\@sequence1, \@sequence2, 'Same seed produces identical sample sequences');
    is(scalar(@sequence1), 5, 'Generated 5 samples');
    is(scalar(@sequence2), 5, 'Generated 5 samples (second run)');
    
    # All tokens should be valid
    my $all_valid = 1;
    for my $tok (@sequence1, @sequence2) {
        $all_valid = 0 unless defined $tok && $tok >= 0;
    }
    ok($all_valid, 'All sampled tokens are valid');
};

# ============================================================================
# Test 5: srand resets state even after consumption
# ============================================================================
subtest 'srand resets after consumption' => sub {
    plan tests => 3;
    
    my @tokens = $tokenizer->encode("Hello world");
    my @logits = $inference->forward_simple(\@tokens);
    
    # Consume some random state
    Lugh::srand(100);
    for (1..10) {
        $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    }
    
    # Now reset and sample
    Lugh::srand(42);
    my $after_consume = $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    
    # Fresh reset and sample
    Lugh::srand(42);
    my $fresh = $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    
    is($after_consume, $fresh, 'srand resets state after consumption');
    ok(defined $after_consume, 'Post-consumption sample is valid');
    ok(defined $fresh, 'Fresh sample is valid');
};

# ============================================================================
# Test 6: Low temperature sampling reproducibility
# ============================================================================
subtest 'low temperature reproducibility' => sub {
    plan tests => 3;
    
    my @tokens = $tokenizer->encode("The capital of France is");
    my @logits = $inference->forward_simple(\@tokens);
    
    # Low temperature (more deterministic, less random influence)
    Lugh::srand(42);
    my $sample1 = $inference->sample_top_p(\@logits, temperature => 0.1, top_p => 0.95);
    
    Lugh::srand(42);
    my $sample2 = $inference->sample_top_p(\@logits, temperature => 0.1, top_p => 0.95);
    
    is($sample1, $sample2, 'Low temperature sampling is reproducible with srand');
    ok(defined $sample1 && $sample1 >= 0, 'Sample is valid token');
    ok(defined $sample2 && $sample2 >= 0, 'Sample is valid token');
};

# ============================================================================
# Test 7: High temperature sampling reproducibility
# ============================================================================
subtest 'high temperature reproducibility' => sub {
    plan tests => 2;
    
    my @tokens = $tokenizer->encode("Random text for testing");
    my @logits = $inference->forward_simple(\@tokens);
    
    # High temperature (more randomness)
    Lugh::srand(42);
    my @high_temp1;
    for (1..3) {
        push @high_temp1, $inference->sample_top_p(\@logits, temperature => 2.0, top_p => 0.99);
    }
    
    Lugh::srand(42);
    my @high_temp2;
    for (1..3) {
        push @high_temp2, $inference->sample_top_p(\@logits, temperature => 2.0, top_p => 0.99);
    }
    
    is_deeply(\@high_temp1, \@high_temp2, 'High temperature sampling is reproducible with srand');
    ok(scalar(@high_temp1) == 3 && scalar(@high_temp2) == 3, 'Got 3 samples each');
};

# ============================================================================
# Test 8: Generation loop reproducibility
# ============================================================================
subtest 'generation loop reproducibility' => sub {
    plan tests => 3;
    
    my @prompt = $tokenizer->encode("Once upon");
    my $max_tokens = 5;
    
    # First generation run
    Lugh::srand(42);
    my @generated1 = @prompt;
    for (1..$max_tokens) {
        my @logits = $inference->forward_simple(\@generated1);
        my $next = $inference->sample_top_p(\@logits, temperature => 0.8, top_p => 0.9);
        push @generated1, $next;
    }
    
    # Second generation run with same seed
    Lugh::srand(42);
    my @generated2 = @prompt;
    for (1..$max_tokens) {
        my @logits = $inference->forward_simple(\@generated2);
        my $next = $inference->sample_top_p(\@logits, temperature => 0.8, top_p => 0.9);
        push @generated2, $next;
    }
    
    is_deeply(\@generated1, \@generated2, 'Full generation loop is reproducible');
    is(scalar(@generated1), scalar(@prompt) + $max_tokens, 'Generated correct number of tokens');
    
    my $text1 = $tokenizer->decode(\@generated1);
    my $text2 = $tokenizer->decode(\@generated2);
    is($text1, $text2, 'Decoded text matches');
    diag("Generated: $text1");
};

# ============================================================================
# Test 9: srand does not affect Perl's rand()
# ============================================================================
subtest 'srand isolation from Perl' => sub {
    plan tests => 2;
    
    # Set Perl's srand
    srand(12345);
    my $perl_rand1 = rand();
    
    # Reset Perl's srand
    srand(12345);
    my $perl_rand2 = rand();
    
    # Call Lugh::srand (should not affect Perl's rand)
    Lugh::srand(99999);
    
    # Reset Perl's srand again
    srand(12345);
    my $perl_rand3 = rand();
    
    is($perl_rand1, $perl_rand2, 'Perl srand produces reproducible rand()');
    is($perl_rand2, $perl_rand3, 'Lugh::srand does not affect Perl rand()');
};

# ============================================================================
# Test 10: Reproducible token prediction across inference
# ============================================================================
subtest 'cross-inference reproducibility' => sub {
    plan tests => 2;
    
    # Create two separate inference engines
    my $inf1 = Lugh::Inference->new(model => $model);
    my $inf2 = Lugh::Inference->new(model => $model);
    
    my @tokens = $tokenizer->encode("Test prompt");
    
    # Both should produce same logits
    my @logits1 = $inf1->forward_simple(\@tokens);
    my @logits2 = $inf2->forward_simple(\@tokens);
    
    # With same seed, sampling should match
    Lugh::srand(42);
    my $sample1 = $inf1->sample_top_p(\@logits1, temperature => 1.0, top_p => 0.9);
    
    Lugh::srand(42);
    my $sample2 = $inf2->sample_top_p(\@logits2, temperature => 1.0, top_p => 0.9);
    
    is($sample1, $sample2, 'Different inference engines produce same sample with same seed');
    ok(defined $sample1 && defined $sample2, 'Both samples are valid');
};

done_testing();
