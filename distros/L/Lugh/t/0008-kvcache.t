#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;

use Lugh;
use Lugh::Model;
use Lugh::Tokenizer;
use Lugh::Inference;

# Lugh::KVCache is loaded via Lugh's XS

# Find the bundled test model
my $model_path = "$FindBin::Bin/data/test-model.gguf";

# Skip tests if model not available
unless (-f $model_path) {
    plan skip_all => "Test model not found at $model_path";
}

plan tests => 31;

# Load model
my $model = Lugh::Model->new(model => $model_path);
ok($model, 'Model loaded');

# Create tokenizer and inference engine
my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');

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

# Test 1: KVCache creation via Inference
my $cache = $inference->create_kv_cache();
ok($cache, 'KV cache created via inference');
isa_ok($cache, 'Lugh::KVCache', 'Cache is correct type');

# Test 2: Cache starts empty
is($cache->n_cached, 0, 'Cache starts with 0 cached tokens');
ok($cache->n_ctx > 0, 'Cache has positive context size');
ok($cache->n_layer > 0, 'Cache has positive layer count');

# Test 3: Direct KVCache creation
my $cache2 = Lugh::KVCache->new(
    n_layer   => 2,
    n_ctx     => 512,
    n_head_kv => 4,
    head_dim  => 64,
);
ok($cache2, 'Direct KVCache creation works');
is($cache2->n_layer, 2, 'n_layer correctly set');
is($cache2->n_ctx, 512, 'n_ctx correctly set');
is($cache2->n_cached, 0, 'Direct cache starts empty');

# Test 4: Encode a prompt
my @prompt_tokens = $tokenizer->encode("Once upon a");
ok(@prompt_tokens > 0, 'Prompt encoded');

# Test 5: forward_cache - prefill phase
my @logits1 = $inference->forward_cache($cache, \@prompt_tokens);
ok(@logits1 > 0, 'forward_cache returns logits');
is($cache->n_cached, scalar(@prompt_tokens), 'Cache updated after prefill');

# Test 6: Get argmax for greedy sampling
my $max_idx = 0;
my $max_val = $logits1[0];
for my $i (1..$#logits1) {
    if ($logits1[$i] > $max_val) {
        $max_val = $logits1[$i];
        $max_idx = $i;
    }
}
ok($max_idx >= 0, 'Argmax token found');

# Test 7: forward_cache - decode step
my @logits2 = $inference->forward_cache($cache, [$max_idx]);
ok(@logits2 > 0, 'Decode step returns logits');
is($cache->n_cached, scalar(@prompt_tokens) + 1, 'Cache updated after decode step');

# Test 8: Clear cache
$cache->clear();
is($cache->n_cached, 0, 'Cache cleared successfully');

# Test 9: Verify cached vs non-cached produce same results
# Run full forward without cache
my @logits_full = $inference->forward_simple(\@prompt_tokens);

# Run with fresh cache
my $cache3 = $inference->create_kv_cache();
my @logits_cached = $inference->forward_cache($cache3, \@prompt_tokens);

# Compare top predictions (allow for small floating point differences)
my $full_argmax = 0;
my $cached_argmax = 0;
for my $i (1..$#logits_full) {
    $full_argmax = $i if $logits_full[$i] > $logits_full[$full_argmax];
    $cached_argmax = $i if $logits_cached[$i] > $logits_cached[$cached_argmax];
}
is($cached_argmax, $full_argmax, 'Cached and non-cached forward agree on top prediction');

# Test 10: Resize (truncate) cache - resize sets n_cached, not n_ctx
# First fill the cache a bit
my $cache4 = $inference->create_kv_cache();
$inference->forward_cache($cache4, \@prompt_tokens);
my $old_cached = $cache4->n_cached;
ok($old_cached > 0, 'Cache has tokens before resize');
$cache4->resize(1);  # Truncate to 1 token
is($cache4->n_cached, 1, 'Cache resize (truncate) works');

# ============================================================================
# Deterministic Tests - verify exact outputs match non-cached forward
# ============================================================================

# Test 11: Verify that prefill with cache matches non-cached forward exactly
{
    my @tokens = $tokenizer->encode("Once upon a time");
    
    # Non-cached forward
    my @logits_nc = $inference->forward_simple(\@tokens);
    my $pred_nc = argmax(\@logits_nc);
    
    # Cached forward (prefill only, no decode)
    my $cache = $inference->create_kv_cache();
    my @logits_c = $inference->forward_cache($cache, \@tokens);
    my $pred_c = argmax(\@logits_c);
    
    is($pred_c, $pred_nc, 'Prefill prediction matches non-cached');
    is($cache->n_cached, scalar(@tokens), 'Cache has correct token count after prefill');
}

# Test 12: Verify second decode step by comparing full forward vs incremental
# Full forward: tokens + [first_pred]
# Incremental: cache(tokens), then forward_cache([first_pred])
{
    my @tokens = $tokenizer->encode("Once upon a time");
    
    # Get first prediction
    my @logits1 = $inference->forward_simple(\@tokens);
    my $first_pred = argmax(\@logits1);
    
    # Full forward with tokens + first_pred
    my @extended = (@tokens, $first_pred);
    my @logits_full = $inference->forward_simple(\@extended);
    my $second_pred_full = argmax(\@logits_full);
    
    # Incremental with cache
    my $cache = $inference->create_kv_cache();
    $inference->forward_cache($cache, \@tokens);  # prefill
    my @logits_inc = $inference->forward_cache($cache, [$first_pred]);  # decode
    my $second_pred_inc = argmax(\@logits_inc);
    
    is($second_pred_inc, $second_pred_full, 
        'Incremental decode prediction matches full forward');
}

# Test 13: Known deterministic output - 5 tokens from "Once upon a time"
# Using full forward for each step (as baseline) - matches t/07-generate.t
{
    my @tokens = $tokenizer->encode("Once upon a time");
    my @generated;
    my @current = @tokens;
    
    for (1..5) {
        my @logits = $inference->forward_simple(\@current);
        my $next = argmax(\@logits);
        push @generated, $next;
        push @current, $next;
    }
    
    # Record what full forward produces - should match generate() greedy output
    is_deeply(\@generated, [759, 93, 605, 308, 1296], 
        'Full forward greedy output matches expected [759, 93, 605, 308, 1296]');
}

# Test 14: Cache state after multi-token generation
{
    my @tokens = $tokenizer->encode("The");  # Short prompt
    my $cache = $inference->create_kv_cache();
    
    # Prefill
    $inference->forward_cache($cache, \@tokens);
    is($cache->n_cached, scalar(@tokens), 'Cache has prompt tokens');
    
    # Generate 1 more token
    my @logits = $inference->forward_cache($cache, [1]);  # dummy token
    is($cache->n_cached, scalar(@tokens) + 1, 'Cache incremented by 1 after decode step');
}

# Test 15: Multiple sequences with cache clear between them
{
    my $cache = $inference->create_kv_cache();
    
    # First sequence
    my @tokens1 = $tokenizer->encode("Hello");
    my @logits1 = $inference->forward_cache($cache, \@tokens1);
    my $pred1 = argmax(\@logits1);
    my $cached1 = $cache->n_cached;
    
    # Clear and second sequence
    $cache->clear();
    is($cache->n_cached, 0, 'Cache cleared between sequences');
    
    my @tokens2 = $tokenizer->encode("World");
    my @logits2 = $inference->forward_cache($cache, \@tokens2);
    my $pred2 = argmax(\@logits2);
    
    is($cache->n_cached, scalar(@tokens2), 'Cache has second sequence tokens');
}

# Test 16: Top-5 predictions match between cached prefill and non-cached
{
    my @tokens = $tokenizer->encode("Test prompt");
    
    # Non-cached forward
    my @logits_nc = $inference->forward_simple(\@tokens);
    
    # Cached forward (prefill)
    my $cache = $inference->create_kv_cache();
    my @logits_c = $inference->forward_cache($cache, \@tokens);
    
    # Top-5 predictions should match
    my @sorted_nc = sort { $logits_nc[$b] <=> $logits_nc[$a] } (0..$#logits_nc);
    my @sorted_c = sort { $logits_c[$b] <=> $logits_c[$a] } (0..$#logits_c);
    
    is_deeply([@sorted_nc[0..4]], [@sorted_c[0..4]], 
        'Top-5 predictions match between cached and non-cached prefill');
}

done_testing();
