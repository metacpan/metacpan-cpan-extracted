#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Heap::PQ;

# ============================================
# Numeric heap API - stores NV directly, no SV overhead
# Faster than standard heap for numeric-only data
# ============================================

# --------------------------------------------
# Heap::PQ::new_nv - create numeric heap
# --------------------------------------------

subtest 'new_nv min-heap basic' => sub {
    my $h = Heap::PQ::new_nv('min');
    ok(defined $h, 'new_nv creates heap');

    $h->push(5);
    $h->push(3);
    $h->push(7);
    $h->push(1);
    $h->push(4);

    is($h->size, 5, 'new_nv min: correct size');
    is($h->peek, 1, 'new_nv min: peek returns minimum');

    # Pop in order
    is($h->pop, 1, 'new_nv min: pop 1');
    is($h->pop, 3, 'new_nv min: pop 3');
    is($h->pop, 4, 'new_nv min: pop 4');
    is($h->pop, 5, 'new_nv min: pop 5');
    is($h->pop, 7, 'new_nv min: pop 7');

    ok($h->is_empty, 'new_nv min: empty after all pops');
};

subtest 'new_nv max-heap basic' => sub {
    my $h = Heap::PQ::new_nv('max');
    ok(defined $h, 'new_nv max creates heap');

    $h->push(5);
    $h->push(3);
    $h->push(7);
    $h->push(1);
    $h->push(4);

    is($h->size, 5, 'new_nv max: correct size');
    is($h->peek, 7, 'new_nv max: peek returns maximum');

    # Pop in order
    is($h->pop, 7, 'new_nv max: pop 7');
    is($h->pop, 5, 'new_nv max: pop 5');
    is($h->pop, 4, 'new_nv max: pop 4');
    is($h->pop, 3, 'new_nv max: pop 3');
    is($h->pop, 1, 'new_nv max: pop 1');

    ok($h->is_empty, 'new_nv max: empty after all pops');
};

subtest 'new_nv with floats' => sub {
    my $h = Heap::PQ::new_nv('min');

    $h->push(3.14159);
    $h->push(2.71828);
    $h->push(1.41421);
    $h->push(1.61803);

    is($h->peek, 1.41421, 'new_nv float: correct min');

    my @results;
    while (!$h->is_empty) {
        push @results, $h->pop;
    }

    # Check sorted order with float tolerance
    my @expected = (1.41421, 1.61803, 2.71828, 3.14159);
    is(scalar(@results), scalar(@expected), 'new_nv float: correct count');
    for my $i (0 .. $#expected) {
        ok(abs($results[$i] - $expected[$i]) < 0.0001, "new_nv float: element $i correct");
    }
};

subtest 'new_nv with negative numbers' => sub {
    my $h = Heap::PQ::new_nv('min');

    $h->push(-5);
    $h->push(0);
    $h->push(-10);
    $h->push(5);
    $h->push(-3);

    is($h->peek, -10, 'new_nv negative: correct min');

    my @results;
    while (!$h->is_empty) {
        push @results, $h->pop;
    }

    is_deeply(\@results, [-10, -5, -3, 0, 5], 'new_nv negative: correct order');
};

subtest 'new_nv push_all' => sub {
    my $h = Heap::PQ::new_nv('min');

    $h->push_all(5, 3, 7, 1, 4, 6, 2);

    is($h->size, 7, 'new_nv push_all: correct size');
    is($h->peek, 1, 'new_nv push_all: correct min');

    my @results;
    while (!$h->is_empty) {
        push @results, $h->pop;
    }

    is_deeply(\@results, [1, 2, 3, 4, 5, 6, 7], 'new_nv push_all: correct order');
};

subtest 'new_nv clear' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push_all(1, 2, 3, 4, 5);

    is($h->size, 5, 'new_nv clear: has elements');
    ok(!$h->is_empty, 'new_nv clear: not empty');

    $h->clear;

    is($h->size, 0, 'new_nv clear: size is 0');
    ok($h->is_empty, 'new_nv clear: is empty');
    is($h->peek, undef, 'new_nv clear: peek returns undef');
    is($h->pop, undef, 'new_nv clear: pop returns undef');
};

subtest 'new_nv empty operations' => sub {
    my $h = Heap::PQ::new_nv('min');

    ok($h->is_empty, 'new_nv empty: starts empty');
    is($h->size, 0, 'new_nv empty: size is 0');
    is($h->peek, undef, 'new_nv empty: peek returns undef');
    is($h->pop, undef, 'new_nv empty: pop returns undef');
};

subtest 'new_nv large dataset' => sub {
    my $h = Heap::PQ::new_nv('min');
    my @nums = map { rand(10000) } 1..1000;
    my @sorted = sort { $a <=> $b } @nums;

    $h->push_all(@nums);

    is($h->size, 1000, 'new_nv large: correct size');

    my @results;
    while (!$h->is_empty) {
        push @results, $h->pop;
    }

    # Compare with tolerance for floats
    is(scalar(@results), 1000, 'new_nv large: all elements popped');
    for my $i (0 .. $#sorted) {
        ok(abs($results[$i] - $sorted[$i]) < 0.0001, "new_nv large: element $i correct");
    }
};

subtest 'new_nv method chaining' => sub {
    my $h = Heap::PQ::new_nv('min');

    $h->push(5)->push(3)->push(1);

    is($h->size, 3, 'new_nv chain: correct size');
    is($h->peek, 1, 'new_nv chain: correct min');
};

subtest 'new_nv interleaved push/pop' => sub {
    my $h = Heap::PQ::new_nv('min');

    $h->push(5);
    $h->push(3);
    is($h->pop, 3, 'new_nv interleaved: pop 3');

    $h->push(1);
    is($h->pop, 1, 'new_nv interleaved: pop 1');
    is($h->pop, 5, 'new_nv interleaved: pop 5');

    $h->push(7);
    $h->push(2);
    is($h->pop, 2, 'new_nv interleaved: pop 2');
    is($h->pop, 7, 'new_nv interleaved: pop 7');

    ok($h->is_empty, 'new_nv interleaved: empty');
};

subtest 'new_nv very small numbers' => sub {
    my $h = Heap::PQ::new_nv('min');

    $h->push(1e-10);
    $h->push(1e-15);
    $h->push(1e-5);
    $h->push(1e-20);

    is($h->peek, 1e-20, 'new_nv tiny: correct min');

    my $first = $h->pop;
    ok($first < 1e-19, 'new_nv tiny: first pop is smallest');
};

subtest 'new_nv very large numbers' => sub {
    my $h = Heap::PQ::new_nv('max');

    $h->push(1e10);
    $h->push(1e15);
    $h->push(1e5);
    $h->push(1e20);

    is($h->peek, 1e20, 'new_nv huge: correct max');

    my $first = $h->pop;
    ok($first > 1e19, 'new_nv huge: first pop is largest');
};

done_testing;
