#!/usr/bin/env perl
# t/0036-memory-pool.t - Tests for Lugh::MemoryPool
#
# Tests the MemoryPool functionality for efficient inference.

use strict;
use warnings;
use Test::More;
use FindBin;
use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

plan tests => 12;

# Test 1: Create memory pool from inference object
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference created');

my $pool = $inference->create_memory_pool();
ok($pool, 'Memory pool created');
isa_ok($pool, 'Lugh::MemoryPool', 'Pool is correct type');

# Test 2: Use pool for forward pass
my @tokens = $tokenizer->encode("Hello");
ok(scalar(@tokens) > 0, 'Tokens encoded');

my @logits = $inference->forward_pool(
    tokens => \@tokens,
    pool   => $pool,
);
ok(scalar(@logits) > 0, 'Forward with pool returned logits');

# Test 3: Reset pool
my $reset_ok = $pool->reset();
ok($reset_ok, 'Pool reset succeeded');

# Test 4: Use pool again after reset
my @tokens2 = $tokenizer->encode("World");
my @logits2 = $inference->forward_pool(
    tokens => \@tokens2,
    pool   => $pool,
);
ok(scalar(@logits2) > 0, 'Forward with pool after reset returned logits');

# Test 5: Multiple resets
for my $i (1..5) {
    $pool->reset();
    my @t = $tokenizer->encode("Test $i");
    my @l = $inference->forward_pool(
        tokens => \@t,
        pool   => $pool,
    );
}
pass('Multiple reset cycles completed');

# Test 6: Pool with KV cache
my $cache = $inference->create_kv_cache();
ok($cache, 'KV cache created');

$pool->reset();
$cache->clear();

my @logits3 = $inference->forward_cache_pool(
    tokens => \@tokens,
    cache  => $cache,
    pool   => $pool,
);
ok(scalar(@logits3) > 0, 'Forward with cache and pool returned logits');

done_testing();
