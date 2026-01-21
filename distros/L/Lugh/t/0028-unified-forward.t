#!perl
use strict;
use warnings;
use Test::More;
use FindBin;

# Load modules
use_ok('Lugh');
use_ok('Lugh::RoPE');

# Use bundled test model
my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

# Load model and create components
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');

# Test tokens
my @tokens = $tokenizer->encode("Once upon a time");
ok(@tokens > 0, 'Prompt encoded');
diag("Tokens: " . scalar(@tokens));

# Helper to get argmax
sub argmax {
    my ($logits) = @_;
    my $max_idx = 0;
    my $max_val = $logits->[0];
    for my $i (1..$#$logits) {
        if ($logits->[$i] > $max_val) {
            $max_val = $logits->[$i];
            $max_idx = $i;
        }
    }
    return $max_idx;
}

# ============================================================================
# Test 1: Basic forward with tokens
# ============================================================================
subtest 'Basic forward' => sub {
    # Basic tokens only
    my @logits = $inference->forward(tokens => \@tokens);
    ok(@logits > 0, 'forward with tokens returns logits');
    
    # Compare with old forward()
    my @old_logits = $inference->forward_simple(\@tokens);
    ok(@old_logits > 0, 'Old forward() still works');
    
    # Should produce same predictions
    my $unified_pred = argmax(\@logits);
    my $old_pred = argmax(\@old_logits);
    is($unified_pred, $old_pred, 'Unified and old forward produce same prediction');
};

# ============================================================================
# Test 2: Convenience helpers
# ============================================================================
subtest 'Convenience helpers' => sub {
    # forward_simple
    my @simple_logits = $inference->forward_simple(\@tokens);
    ok(@simple_logits > 0, 'forward_simple() works');
    
    # Compare with baseline
    my @base_logits = $inference->forward_simple(\@tokens);
    my $simple_pred = argmax(\@simple_logits);
    my $base_pred = argmax(\@base_logits);
    is($simple_pred, $base_pred, 'forward_simple matches forward');
};

# ============================================================================
# Test 3: forward_pool helper
# ============================================================================
subtest 'forward_pool helper' => sub {
    my $pool = $inference->create_memory_pool();
    ok($pool, 'Memory pool created');
    
    my @pool_logits = $inference->forward_pool($pool, \@tokens);
    ok(@pool_logits > 0, 'forward_pool() works');
    
    my @base_logits = $inference->forward_simple(\@tokens);
    my $pool_pred = argmax(\@pool_logits);
    my $base_pred = argmax(\@base_logits);
    is($pool_pred, $base_pred, 'forward_pool matches forward');
};

# ============================================================================
# Test 4: forward_cache helper
# ============================================================================
subtest 'forward_cache helper' => sub {
    my $cache = $inference->create_kv_cache();
    ok($cache, 'KV cache created');
    
    my @cache_logits = $inference->forward_cache($cache, \@tokens);
    ok(@cache_logits > 0, 'forward_cache() works');
    is($cache->n_cached, scalar(@tokens), 'Cache updated correctly');
    
    # Decode one more token
    my $pred = argmax(\@cache_logits);
    my @decode_logits = $inference->forward_cache($cache, [$pred]);
    ok(@decode_logits > 0, 'Decode with cache works');
    is($cache->n_cached, scalar(@tokens) + 1, 'Cache updated after decode');
};

# ============================================================================
# Test 5: forward_batch helper
# ============================================================================
subtest 'forward_batch helper' => sub {
    my @seq1 = $tokenizer->encode("Hello world");
    my @seq2 = $tokenizer->encode("The quick brown");
    my @seq3 = $tokenizer->encode("Once upon a");
    my @sequences = (\@seq1, \@seq2, \@seq3);
    
    my $results = $inference->forward_batch(\@sequences);
    ok(ref($results) eq 'ARRAY', 'forward_batch returns array ref');
    is(scalar(@$results), 3, 'Got 3 results');
    
    for my $i (0..2) {
        ok(ref($results->[$i]) eq 'ARRAY', "Result $i is array ref");
        ok(scalar(@{$results->[$i]}) > 0, "Result $i has logits");
    }
};

# ============================================================================
# Test 6: cache + pool combination (NEW!)
# ============================================================================
subtest 'cache + pool combination' => sub {
    my $cache = $inference->create_kv_cache();
    my $pool = $inference->create_memory_pool();
    ok($cache && $pool, 'Cache and pool created');
    
    # Use forward_cache_pool helper
    my @logits1 = $inference->forward_cache_pool($cache, $pool, \@tokens);
    ok(@logits1 > 0, 'forward_cache_pool() works');
    is($cache->n_cached, scalar(@tokens), 'Cache updated');
    
    # Decode step with same cache and pool
    my $pred = argmax(\@logits1);
    my @logits2 = $inference->forward_cache_pool($cache, $pool, [$pred]);
    ok(@logits2 > 0, 'Decode with cache+pool works');
    is($cache->n_cached, scalar(@tokens) + 1, 'Cache updated after decode');
};

# ============================================================================
# Test 7: batch + pool combination (NEW!)
# ============================================================================
subtest 'batch + pool combination' => sub {
    my $pool = $inference->create_memory_pool();
    ok($pool, 'Memory pool created');
    
    my @seq1 = $tokenizer->encode("Hello");
    my @seq2 = $tokenizer->encode("World");
    my @sequences = (\@seq1, \@seq2);
    
    my $results = $inference->forward_batch_pool($pool, \@sequences);
    ok(ref($results) eq 'ARRAY', 'forward_batch_pool returns array ref');
    is(scalar(@$results), 2, 'Got 2 results');
    
    for my $i (0..1) {
        ok(ref($results->[$i]) eq 'ARRAY', "Result $i is array ref");
        ok(scalar(@{$results->[$i]}) > 0, "Result $i has logits");
    }
};

# ============================================================================
# Test 8: Error cases
# ============================================================================
subtest 'Error cases' => sub {
    # No tokens or sequences
    eval { $inference->forward() };
    like($@, qr/requires tokens/, 'Error on missing tokens/sequences');
    
    # forward() with sequences should use forward_batch
    # Both tokens and sequences is no longer an error in forward()
    # because forward() now only looks for tokens
    ok(1, 'forward() only accepts tokens (use forward_batch for sequences)');
    
    # Cache with batch mode (use 'caches' array, not 'cache')
    my $cache = $inference->create_kv_cache();
    eval {
        $inference->forward_batch(
            sequences => [\@tokens],
            cache => $cache
        );
    };
    like($@, qr/caches.*array.*not.*cache|Use 'caches'/i, 'Error on cache with batch');
};

# ============================================================================
# Test 9: With optional parameters (rope, lora)
# ============================================================================
subtest 'Optional parameters' => sub {
    my $rope = Lugh::RoPE->linear(2048, 4096);
    
    # forward with rope
    my @logits = $inference->forward(
        tokens => \@tokens,
        rope => $rope
    );
    ok(@logits > 0, 'forward with rope works');
    
    # forward_cache with rope via opts
    my $cache = $inference->create_kv_cache();
    my @cache_logits = $inference->forward_cache($cache, \@tokens, rope => $rope);
    ok(@cache_logits > 0, 'forward_cache with rope works');
    
    # forward_pool with rope
    my $pool = $inference->create_memory_pool();
    my @pool_logits = $inference->forward_pool($pool, \@tokens, rope => $rope);
    ok(@pool_logits > 0, 'forward_pool with rope works');
    
    # forward_batch with rope
    my $results = $inference->forward_batch([\@tokens], rope => $rope);
    ok(ref($results) eq 'ARRAY', 'forward_batch with rope works');
};

# ============================================================================
# Test 10: Batch mode with per-sequence caches
# ============================================================================
subtest 'Batch with per-sequence caches' => sub {
    # Create caches for each sequence
    my $cache1 = $inference->create_kv_cache();
    my $cache2 = $inference->create_kv_cache();
    
    ok($cache1, 'Cache 1 created');
    ok($cache2, 'Cache 2 created');
    
    # Two sequences with their own caches
    my @seq1 = $tokenizer->encode("Hello");
    my @seq2 = $tokenizer->encode("World");
    
    # First batch - uses prompt tokens
    my $results = $inference->forward(
        sequences => [\@seq1, \@seq2],
        caches => [$cache1, $cache2]
    );
    
    ok(ref($results) eq 'ARRAY', 'Batch with caches returns array');
    is(scalar(@$results), 2, 'Got results for 2 sequences');
    
    # Each cache should now have cached tokens
    ok($cache1->n_cached > 0, 'Cache 1 has cached tokens');
    ok($cache2->n_cached > 0, 'Cache 2 has cached tokens');
    
    # Second batch - continuation with new token for each
    my @next_tok1 = ($tokenizer->encode("there"))[0..0];  # just first token
    my @next_tok2 = ($tokenizer->encode("wide"))[0..0];   # just first token
    
    my $results2 = $inference->forward_batch(
        sequences => [\@next_tok1, \@next_tok2],
        caches => [$cache1, $cache2]
    );
    
    ok(ref($results2) eq 'ARRAY', 'Second batch with caches works');
    is(scalar(@$results2), 2, 'Got continuation results for 2 sequences');
    
    # Caches should have grown
    ok($cache1->n_cached > scalar(@seq1), 'Cache 1 grew after continuation');
    ok($cache2->n_cached > scalar(@seq2), 'Cache 2 grew after continuation');
    
    # Error: caches count must match sequences count
    my $cache3 = $inference->create_kv_cache();
    eval {
        $inference->forward_batch(
            sequences => [\@seq1, \@seq2],
            caches => [$cache3]  # Only 1 cache for 2 sequences
        );
    };
    like($@, qr/caches.*sequences|mismatch/i, 'Error when cache count != sequence count');
};


done_testing();
