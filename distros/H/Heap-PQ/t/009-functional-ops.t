#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Import heap with functional ops
use Heap::PQ 'import';

# ============================================
# Functional ops: heap_push, heap_pop, heap_peek, heap_size
# These are installed via import and use custom ops
# ============================================

subtest 'heap_push and heap_pop' => sub {
    my $h = Heap::PQ::new('min');

    heap_push($h, 5);
    heap_push($h, 3);
    heap_push($h, 7);
    heap_push($h, 1);

    is(heap_size($h), 4, 'heap_size after pushes');
    is(heap_peek($h), 1, 'heap_peek returns min');

    is(heap_pop($h), 1, 'heap_pop returns 1');
    is(heap_pop($h), 3, 'heap_pop returns 3');
    is(heap_pop($h), 5, 'heap_pop returns 5');
    is(heap_pop($h), 7, 'heap_pop returns 7');

    is(heap_size($h), 0, 'heap_size after all pops');
};

subtest 'heap_push with max heap' => sub {
    my $h = Heap::PQ::new('max');

    heap_push($h, 5);
    heap_push($h, 3);
    heap_push($h, 7);
    heap_push($h, 1);

    is(heap_peek($h), 7, 'heap_peek returns max');
    is(heap_pop($h), 7, 'heap_pop returns max first');
};

subtest 'heap_size on empty' => sub {
    my $h = Heap::PQ::new('min');
    is(heap_size($h), 0, 'heap_size on empty heap');
};

subtest 'heap_peek on empty' => sub {
    my $h = Heap::PQ::new('min');
    is(heap_peek($h), undef, 'heap_peek on empty returns undef');
};

subtest 'heap_pop on empty' => sub {
    my $h = Heap::PQ::new('min');
    is(heap_pop($h), undef, 'heap_pop on empty returns undef');
};

subtest 'mixed functional and method calls' => sub {
    my $h = Heap::PQ::new('min');

    # Use both styles interchangeably
    heap_push($h, 10);
    $h->push(5);
    heap_push($h, 15);
    $h->push(1);

    is(heap_size($h), 4, 'size with mixed calls');
    is($h->peek, 1, 'method peek after functional push');
    is(heap_pop($h), 1, 'functional pop');
    is($h->pop, 5, 'method pop');
    is(heap_peek($h), 10, 'functional peek');
};

subtest 'functional ops with complex values' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{priority} <=> $b->{priority} });

    heap_push($h, { name => 'low', priority => 10 });
    heap_push($h, { name => 'high', priority => 1 });
    heap_push($h, { name => 'med', priority => 5 });

    is(heap_size($h), 3, 'size with complex values');

    my $first = heap_pop($h);
    is($first->{name}, 'high', 'highest priority first');

    my $second = heap_pop($h);
    is($second->{name}, 'med', 'medium priority second');
};

subtest 'heap_is_empty functional' => sub {
    my $h = Heap::PQ::new('min');
    ok(heap_is_empty($h), 'empty heap is_empty');
    heap_push($h, 42);
    ok(!heap_is_empty($h), 'non-empty heap is not empty');
    heap_pop($h);
    ok(heap_is_empty($h), 'emptied heap is_empty again');
};

subtest 'heap_type functional' => sub {
    my $min = Heap::PQ::new('min');
    my $max = Heap::PQ::new('max');
    is(heap_type($min), 'min', 'min heap type');
    is(heap_type($max), 'max', 'max heap type');
};

subtest 'heap_clear functional' => sub {
    my $h = Heap::PQ::new('min');
    heap_push($h, $_) for (1..5);
    is(heap_size($h), 5, 'has 5 elements');
    heap_clear($h);
    is(heap_size($h), 0, 'cleared to 0');
    ok(heap_is_empty($h), 'is_empty after clear');
    # can still use after clear
    heap_push($h, 99);
    is(heap_peek($h), 99, 'push after clear works');
};

subtest 'heap_is_empty on NV heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    ok(heap_is_empty($h), 'nv empty');
    $h->push(3.14);
    ok(!heap_is_empty($h), 'nv not empty');
};

subtest 'heap_type on NV heap' => sub {
    my $h = Heap::PQ::new_nv('max');
    is(heap_type($h), 'max', 'nv max type');
};

subtest 'heap_clear on NV heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (1.1, 2.2, 3.3);
    heap_clear($h);
    ok(heap_is_empty($h), 'nv cleared');
    $h->push(9.9);
    is($h->peek, 9.9, 'nv push after clear works');
};

done_testing;
