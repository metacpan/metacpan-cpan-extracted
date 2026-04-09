#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use LRU::Cache 'import';  # Get functional ops

# Warmup
for (1..10) {
    my $c = LRU::Cache::new(10);
    lru_set($c, "key", "value");
    lru_get($c, "key");
}

# ============================================
# Functional ops: lru_get, lru_set, lru_exists, lru_peek, lru_delete
# ============================================

subtest 'lru_set no leak' => sub {
    my $cache = LRU::Cache::new(100);
    no_leaks_ok {
        for (1..500) {
            lru_set($cache, "key", "value$_");
        }
    } 'lru_set does not leak';
};

subtest 'lru_get no leak' => sub {
    my $cache = LRU::Cache::new(100);
    lru_set($cache, "key$_", "value$_") for 1..50;
    no_leaks_ok {
        for (1..500) {
            my $v = lru_get($cache, "key25");
        }
    } 'lru_get does not leak';
};

subtest 'lru_get miss no leak' => sub {
    my $cache = LRU::Cache::new(100);
    no_leaks_ok {
        for (1..500) {
            my $v = lru_get($cache, "nonexistent");
        }
    } 'lru_get miss does not leak';
};

subtest 'lru_exists no leak' => sub {
    my $cache = LRU::Cache::new(100);
    lru_set($cache, "key$_", "value$_") for 1..50;
    no_leaks_ok {
        for (1..500) {
            my $e = lru_exists($cache, "key25");
            my $n = lru_exists($cache, "nonexistent");
        }
    } 'lru_exists does not leak';
};

subtest 'lru_peek no leak' => sub {
    my $cache = LRU::Cache::new(100);
    lru_set($cache, "key$_", "value$_") for 1..50;
    no_leaks_ok {
        for (1..500) {
            my $v = lru_peek($cache, "key25");
        }
    } 'lru_peek does not leak';
};

subtest 'lru_delete no leak' => sub {
    my $cache = LRU::Cache::new(1000);
    lru_set($cache, "key$_", "value$_") for 1..500;
    no_leaks_ok {
        for (1..200) {
            lru_delete($cache, "key$_");
        }
    } 'lru_delete does not leak';
};

# ============================================
# Method ops not in basic test
# ============================================

subtest 'peek method no leak' => sub {
    my $cache = LRU::Cache::new(100);
    $cache->set("key$_", "value$_") for 1..50;
    no_leaks_ok {
        for (1..500) {
            my $v = $cache->peek("key25");
        }
    } 'peek method does not leak';
};

subtest 'capacity method no leak' => sub {
    my $cache = LRU::Cache::new(100);
    no_leaks_ok {
        for (1..500) {
            my $cap = $cache->capacity;
        }
    } 'capacity does not leak';
};

subtest 'clear method no leak' => sub {
    my $cache = LRU::Cache::new(100);
    no_leaks_ok {
        for (1..100) {
            $cache->set("key$_", "value$_") for 1..20;
            $cache->clear;
        }
    } 'clear does not leak';
};

# ============================================
# Eviction behavior
# ============================================

subtest 'eviction no leak' => sub {
    my $cache = LRU::Cache::new(10);
    no_leaks_ok {
        for (1..200) {
            $cache->set("key$_", "value$_");
            # Eviction happens automatically when > capacity
        }
    } 'eviction does not leak';
};

subtest 'eviction with refs no leak' => sub {
    my $cache = LRU::Cache::new(10);
    no_leaks_ok {
        for (1..100) {
            $cache->set("key$_", { data => "value$_" });
        }
    } 'eviction with refs does not leak';
};

subtest 'functional ops cycle no leak' => sub {
    my $cache = LRU::Cache::new(10);
    no_leaks_ok {
        for (1..200) {
            lru_set($cache, "key", "value$_");
            my $v = lru_get($cache, "key");
            my $e = lru_exists($cache, "key");
            my $p = lru_peek($cache, "key");
        }
    } 'functional ops cycle does not leak';
};

done_testing;
