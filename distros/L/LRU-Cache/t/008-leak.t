#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use LRU::Cache;

# Warmup
for (1..10) {
    my $cache = LRU::Cache::new(10);
    $cache->set("key", "value");
    $cache->get("key");
}

subtest 'lru get no leak' => sub {
    my $cache = LRU::Cache::new(100);
    $cache->set("key$_", "value$_") for 1..50;
    no_leaks_ok {
        for (1..1000) {
            my $v = $cache->get("key25");
        }
    } 'lru get no leak';
};

subtest 'lru set existing key no leak' => sub {
    my $cache = LRU::Cache::new(100);
    $cache->set("key", "initial");
    no_leaks_ok {
        for (1..1000) {
            $cache->set("key", "updated");
        }
    } 'lru set existing no leak';
};

subtest 'lru exists no leak' => sub {
    my $cache = LRU::Cache::new(100);
    $cache->set("key$_", "value$_") for 1..50;
    no_leaks_ok {
        for (1..1000) {
            my $e = $cache->exists("key25");
            my $n = $cache->exists("nonexistent");
        }
    } 'lru exists no leak';
};

subtest 'lru size no leak' => sub {
    my $cache = LRU::Cache::new(100);
    $cache->set("key$_", "value$_") for 1..50;
    no_leaks_ok {
        for (1..1000) {
            my $s = $cache->size;
        }
    } 'lru size no leak';
};

subtest 'lru keys no leak' => sub {
    my $cache = LRU::Cache::new(100);
    $cache->set("key$_", "value$_") for 1..20;
    no_leaks_ok {
        for (1..100) {
            my @k = $cache->keys;
        }
    } 'lru keys no leak';
};

subtest 'lru delete no leak' => sub {
    my $cache = LRU::Cache::new(100);
    for (1..100) {
        $cache->set("key$_", "value$_");
    }
    no_leaks_ok {
        for (1..50) {
            $cache->delete("key$_");
        }
    } 'lru delete no leak';
};

subtest 'lru get/set cycle no leak' => sub {
    my $cache = LRU::Cache::new(10);
    $cache->set("key", "initial");
    no_leaks_ok {
        for (1..1000) {
            my $v = $cache->get("key");
            $cache->set("key", "value");
        }
    } 'get/set cycle no leak';
};

done_testing;
