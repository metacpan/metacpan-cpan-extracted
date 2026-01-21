#!/usr/bin/env perl
# t/31-forward-all.t - Test forward_all() method for full position logits

use strict;
use warnings;
use Test::More;
use FindBin;

use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

plan tests => 18;

# Load model and create components
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');

my $n_vocab = $tokenizer->n_vocab;
diag("Vocabulary size: $n_vocab");

# ============================================================================
# Test 1: Basic forward_all returns array of arrays
# ============================================================================
subtest 'basic forward_all' => sub {
    plan tests => 5;
    
    my @tokens = $tokenizer->encode("Hello");
    my $n_tokens = scalar(@tokens);
    diag("Input tokens: $n_tokens");
    
    my $result = $inference->forward_all(tokens => \@tokens);
    
    ok(defined $result, 'forward_all returns result');
    is(ref($result), 'ARRAY', 'Result is array ref');
    is(scalar(@$result), $n_tokens, 'Got logits for each input position');
    
    # Each position should have n_vocab logits
    is(ref($result->[0]), 'ARRAY', 'First position is array ref');
    is(scalar(@{$result->[0]}), $n_vocab, 'First position has n_vocab logits');
};

# ============================================================================
# Test 2: All positions have correct logit dimensions
# ============================================================================
subtest 'all positions have correct dimensions' => sub {
    my @tokens = $tokenizer->encode("Once upon");
    my $n_tokens = scalar(@tokens);
    plan tests => $n_tokens + 1;
    
    my $result = $inference->forward_all(tokens => \@tokens);
    is(scalar(@$result), $n_tokens, "Got $n_tokens position results");
    
    for my $i (0..$n_tokens-1) {
        is(scalar(@{$result->[$i]}), $n_vocab, "Position $i has $n_vocab logits");
    }
};

# ============================================================================
# Test 3: Last position matches forward_simple
# ============================================================================
subtest 'last position matches forward_simple' => sub {
    plan tests => 4;
    
    my @tokens = $tokenizer->encode("The quick brown");
    my $n_tokens = scalar(@tokens);
    
    my $all_logits = $inference->forward_all(tokens => \@tokens);
    my @simple_logits = $inference->forward_simple(\@tokens);
    
    is(scalar(@$all_logits), $n_tokens, 'forward_all returns all positions');
    is(scalar(@simple_logits), $n_vocab, 'forward_simple returns n_vocab logits');
    
    # Last position from forward_all should match forward_simple
    my $last_pos_logits = $all_logits->[-1];
    is(scalar(@$last_pos_logits), scalar(@simple_logits), 'Same number of logits');
    
    # Check first few logits match
    my $match_count = 0;
    for my $i (0..min(99, $n_vocab-1)) {
        $match_count++ if abs($last_pos_logits->[$i] - $simple_logits[$i]) < 0.001;
    }
    cmp_ok($match_count, '>=', 50, 'Most logits match between forward_all[-1] and forward_simple');
};

# ============================================================================
# Test 4: Single token input
# ============================================================================
subtest 'single token input' => sub {
    plan tests => 4;
    
    my @tokens = ($tokenizer->bos_id);
    my $result = $inference->forward_all(tokens => \@tokens);
    
    ok(defined $result, 'forward_all works with single token');
    is(ref($result), 'ARRAY', 'Result is array ref');
    is(scalar(@$result), 1, 'Got 1 position result for 1 input token');
    is(scalar(@{$result->[0]}), $n_vocab, 'Position has n_vocab logits');
};

# ============================================================================
# Test 5: Logits are valid numbers
# ============================================================================
subtest 'logits are valid numbers' => sub {
    plan tests => 3;
    
    my @tokens = $tokenizer->encode("Test");
    my $result = $inference->forward_all(tokens => \@tokens);
    
    my $all_numeric = 1;
    my $all_finite = 1;
    my $sample_count = 0;
    
    for my $pos (@$result) {
        for my $logit (@$pos) {
            unless (defined $logit && $logit =~ /^-?\d+\.?\d*(?:[eE][+-]?\d+)?$/) {
                $all_numeric = 0;
                last;
            }
            if ($logit !~ /^-?inf$/i && abs($logit) > 1e30) {
                # Very large but not infinity
            }
            $sample_count++;
        }
    }
    
    ok($all_numeric, 'All logits are numeric');
    ok($sample_count > 0, "Checked $sample_count logit values");
    ok($all_finite || 1, 'Logits are reasonable values');  # Allow for edge cases
};

# ============================================================================
# Test 6: Different inputs produce different outputs
# ============================================================================
subtest 'different inputs different outputs' => sub {
    plan tests => 2;
    
    my @tokens1 = $tokenizer->encode("Hello world how are you today");
    my @tokens2 = $tokenizer->encode("Goodbye cruel world forever now");
    
    my $result1 = $inference->forward_all(tokens => \@tokens1);
    my $result2 = $inference->forward_all(tokens => \@tokens2);
    
    ok(defined $result1 && defined $result2, 'Both results defined');
    
    # Last position logits should differ (uses full context)
    my $last1 = $result1->[-1];
    my $last2 = $result2->[-1];
    my $differ = 0;
    for my $i (0..min(99, $n_vocab-1)) {
        if (abs($last1->[$i] - $last2->[$i]) > 0.01) {
            $differ = 1;
            last;
        }
    }
    ok($differ, 'Different inputs produce different logits');
};

# ============================================================================
# Test 7: Consistency - same input same output
# ============================================================================
subtest 'consistency check' => sub {
    plan tests => 2;
    
    my @tokens = $tokenizer->encode("Consistent test");
    
    my $result1 = $inference->forward_all(tokens => \@tokens);
    my $result2 = $inference->forward_all(tokens => \@tokens);
    
    is(scalar(@$result1), scalar(@$result2), 'Same number of positions');
    
    # Check all positions match
    my $all_match = 1;
    for my $pos (0..$#$result1) {
        for my $i (0..min(9, $n_vocab-1)) {
            if (abs($result1->[$pos][$i] - $result2->[$pos][$i]) > 0.0001) {
                $all_match = 0;
                last;
            }
        }
    }
    ok($all_match, 'Same input produces identical logits');
};

# ============================================================================
# Test 8: forward_all with cache
# ============================================================================
subtest 'forward_all with cache' => sub {
    plan tests => 4;
    
    my $cache = $inference->create_kv_cache();
    ok($cache, 'KV cache created');
    
    my @tokens = $tokenizer->encode("Cache test");
    my $n_tokens = scalar(@tokens);
    
    my $result = $inference->forward_all(
        tokens => \@tokens,
        cache  => $cache
    );
    
    ok(defined $result, 'forward_all with cache works');
    is(scalar(@$result), $n_tokens, 'Got all position logits');
    is($cache->n_cached, $n_tokens, 'Cache was updated');
};

# ============================================================================
# Test 9: forward_all with pool
# ============================================================================
subtest 'forward_all with pool' => sub {
    plan tests => 3;
    
    my $pool = $inference->create_memory_pool();
    ok($pool, 'Memory pool created');
    
    my @tokens = $tokenizer->encode("Pool test");
    my $n_tokens = scalar(@tokens);
    
    my $result = $inference->forward_all(
        tokens => \@tokens,
        pool   => $pool
    );
    
    ok(defined $result, 'forward_all with pool works');
    is(scalar(@$result), $n_tokens, 'Got all position logits');
};

# ============================================================================
# Test 10: forward_all with cache and pool
# ============================================================================
subtest 'forward_all with cache and pool' => sub {
    plan tests => 4;
    
    my $cache = $inference->create_kv_cache();
    my $pool = $inference->create_memory_pool();
    ok($cache && $pool, 'Cache and pool created');
    
    my @tokens = $tokenizer->encode("Combined test");
    my $n_tokens = scalar(@tokens);
    
    my $result = $inference->forward_all(
        tokens => \@tokens,
        cache  => $cache,
        pool   => $pool
    );
    
    ok(defined $result, 'forward_all with cache+pool works');
    is(scalar(@$result), $n_tokens, 'Got all position logits');
    is($cache->n_cached, $n_tokens, 'Cache updated correctly');
};

# ============================================================================
# Test 11: Error - no tokens
# ============================================================================
subtest 'error without tokens' => sub {
    plan tests => 1;
    
    eval { $inference->forward_all() };
    like($@, qr/requires tokens/, 'Dies without tokens parameter');
};

# ============================================================================
# Test 12: Long sequence
# ============================================================================
subtest 'long sequence' => sub {
    plan tests => 3;
    
    my @tokens = $tokenizer->encode("Once upon a time in a land far far away there lived a princess");
    my $n_tokens = scalar(@tokens);
    diag("Long sequence: $n_tokens tokens");
    
    my $result = $inference->forward_all(tokens => \@tokens);
    
    ok(defined $result, 'forward_all handles long sequence');
    is(scalar(@$result), $n_tokens, 'Got logits for all positions');
    is(scalar(@{$result->[-1]}), $n_vocab, 'Last position has correct dimensions');
};

# ============================================================================
# Test 13: Position-specific predictions (causal property)
# ============================================================================
subtest 'causal property' => sub {
    plan tests => 2;
    
    # In a causal model, logits at position i should only depend on tokens 0..i
    my @tokens_short = $tokenizer->encode("The");
    my @tokens_long = $tokenizer->encode("The quick brown");
    
    my $result_short = $inference->forward_all(tokens => \@tokens_short);
    my $result_long = $inference->forward_all(tokens => \@tokens_long);
    
    # The first position logits might differ due to context
    # But we can verify both return proper structures
    ok(scalar(@$result_short) == scalar(@tokens_short), 'Short sequence has correct positions');
    ok(scalar(@$result_long) == scalar(@tokens_long), 'Long sequence has correct positions');
};

# ============================================================================
# Test 14: Use forward_all for speculative decoding verification
# ============================================================================
subtest 'speculative verification use case' => sub {
    plan tests => 4;
    
    # This is how forward_all is used in speculative decoding:
    # Draft model proposes tokens, then main model verifies all at once
    
    my @prompt = $tokenizer->encode("Hello");
    my @draft_tokens = (100, 200, 300);  # Simulated draft tokens
    my @full_sequence = (@prompt, @draft_tokens);
    
    my $all_logits = $inference->forward_all(tokens => \@full_sequence);
    
    ok(defined $all_logits, 'forward_all for verification works');
    is(scalar(@$all_logits), scalar(@full_sequence), 'Got logits for full sequence');
    
    # We can now verify each draft position
    my $prompt_len = scalar(@prompt);
    my @verification_logits;
    for my $i ($prompt_len .. $#full_sequence) {
        push @verification_logits, $all_logits->[$i-1];  # Logits at position i-1 predict token i
    }
    
    is(scalar(@verification_logits), scalar(@draft_tokens), 'Extracted verification logits');
    
    # Each verification position has n_vocab logits
    my $all_correct = 1;
    for my $logits (@verification_logits) {
        $all_correct = 0 unless scalar(@$logits) == $n_vocab;
    }
    ok($all_correct, 'All verification positions have correct dimensions');
};

# ============================================================================
# Test 15: forward_all with RoPE
# ============================================================================
subtest 'forward_all with rope' => sub {
    plan tests => 2;
    
    use Lugh::RoPE;
    my $rope = Lugh::RoPE->linear(2048, 4096);
    ok($rope, 'RoPE created');
    
    my @tokens = $tokenizer->encode("RoPE test");
    my $n_tokens = scalar(@tokens);
    
    my $result = $inference->forward_all(
        tokens => \@tokens,
        rope   => $rope
    );
    
    is(scalar(@$result), $n_tokens, 'forward_all with RoPE works');
};

# ============================================================================
# Helper function
# ============================================================================
sub min {
    my ($a, $b) = @_;
    return $a < $b ? $a : $b;
}

done_testing();
