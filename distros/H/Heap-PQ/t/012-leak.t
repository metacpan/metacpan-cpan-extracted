#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use Heap::PQ;

# Warmup
for (1..10) {
    my $h = Heap::PQ::new();
    $h->push($_) for 1..5;
    $h->pop for 1..5;
}

subtest 'heap push/pop cycle no leak' => sub {
    my $h = Heap::PQ::new();
    no_leaks_ok {
        for (1..1000) {
            $h->push(42);
            my $v = $h->pop;
        }
    } 'push/pop cycle no leak';
};

subtest 'heap peek no leak' => sub {
    my $h = Heap::PQ::new();
    $h->push($_) for 1..10;
    no_leaks_ok {
        for (1..1000) {
            my $v = $h->peek;
        }
    } 'heap peek no leak';
};

subtest 'heap size no leak' => sub {
    my $h = Heap::PQ::new();
    $h->push($_) for 1..10;
    no_leaks_ok {
        for (1..1000) {
            my $s = $h->size;
        }
    } 'heap size no leak';
};

subtest 'heap is_empty no leak' => sub {
    my $h = Heap::PQ::new();
    no_leaks_ok {
        for (1..1000) {
            my $e = $h->is_empty;
        }
    } 'is_empty no leak';
};

subtest 'heap pop from fixed heap no leak' => sub {
    my $h = Heap::PQ::new();
    $h->push($_) for 1..100;
    no_leaks_ok {
        for (1..100) {
            my $v = $h->pop;
        }
    } 'pop no leak';
};

subtest 'heap clear and repopulate no leak' => sub {
    my $h = Heap::PQ::new();
    $h->push($_) for 1..10;
    no_leaks_ok {
        for (1..100) {
            $h->clear;
        }
    } 'clear no leak';
};

done_testing;
