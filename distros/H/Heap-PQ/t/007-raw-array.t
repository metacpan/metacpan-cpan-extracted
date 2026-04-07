#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Heap::PQ;

# ============================================
# Raw array API - operates directly on Perl arrays
# This is the fastest API, matching Array::Heap speed
# ============================================

# --------------------------------------------
# make_heap_min - convert array to min-heap in O(n)
# --------------------------------------------

subtest 'make_heap_min basic' => sub {
    my @arr = (5, 3, 7, 1, 4, 6, 2);
    Heap::PQ::make_heap_min(\@arr);

    # After heapify, root should be minimum
    is($arr[0], 1, 'make_heap_min: root is minimum');

    # Verify heap property: parent <= children
    for my $i (0 .. $#arr) {
        my $left = 2 * $i + 1;
        my $right = 2 * $i + 2;
        if ($left <= $#arr) {
            ok($arr[$i] <= $arr[$left], "make_heap_min: parent[$i] <= left[$left]");
        }
        if ($right <= $#arr) {
            ok($arr[$i] <= $arr[$right], "make_heap_min: parent[$i] <= right[$right]");
        }
    }
};

subtest 'make_heap_min edge cases' => sub {
    # Empty array
    my @empty = ();
    Heap::PQ::make_heap_min(\@empty);
    is(scalar(@empty), 0, 'make_heap_min: empty array stays empty');

    # Single element
    my @single = (42);
    Heap::PQ::make_heap_min(\@single);
    is($single[0], 42, 'make_heap_min: single element unchanged');

    # Already sorted
    my @sorted = (1, 2, 3, 4, 5);
    Heap::PQ::make_heap_min(\@sorted);
    is($sorted[0], 1, 'make_heap_min: sorted array root is min');

    # Reverse sorted
    my @reverse = (5, 4, 3, 2, 1);
    Heap::PQ::make_heap_min(\@reverse);
    is($reverse[0], 1, 'make_heap_min: reverse array root is min');
};

# --------------------------------------------
# make_heap_max - convert array to max-heap in O(n)
# --------------------------------------------

subtest 'make_heap_max basic' => sub {
    my @arr = (5, 3, 7, 1, 4, 6, 2);
    Heap::PQ::make_heap_max(\@arr);

    # After heapify, root should be maximum
    is($arr[0], 7, 'make_heap_max: root is maximum');

    # Verify heap property: parent >= children
    for my $i (0 .. $#arr) {
        my $left = 2 * $i + 1;
        my $right = 2 * $i + 2;
        if ($left <= $#arr) {
            ok($arr[$i] >= $arr[$left], "make_heap_max: parent[$i] >= left[$left]");
        }
        if ($right <= $#arr) {
            ok($arr[$i] >= $arr[$right], "make_heap_max: parent[$i] >= right[$right]");
        }
    }
};

subtest 'make_heap_max edge cases' => sub {
    # Empty array
    my @empty = ();
    Heap::PQ::make_heap_max(\@empty);
    is(scalar(@empty), 0, 'make_heap_max: empty array stays empty');

    # Single element
    my @single = (42);
    Heap::PQ::make_heap_max(\@single);
    is($single[0], 42, 'make_heap_max: single element unchanged');

    # Reverse sorted (already max-heap order)
    my @reverse = (5, 4, 3, 2, 1);
    Heap::PQ::make_heap_max(\@reverse);
    is($reverse[0], 5, 'make_heap_max: reverse array root is max');
};

# --------------------------------------------
# push_heap_min / pop_heap_min
# --------------------------------------------

subtest 'push_heap_min basic' => sub {
    my @arr;

    Heap::PQ::push_heap_min(\@arr, 5);
    is($arr[0], 5, 'push_heap_min: first element');

    Heap::PQ::push_heap_min(\@arr, 3);
    is($arr[0], 3, 'push_heap_min: new min bubbles up');

    Heap::PQ::push_heap_min(\@arr, 7);
    is($arr[0], 3, 'push_heap_min: min stays at root');

    Heap::PQ::push_heap_min(\@arr, 1);
    is($arr[0], 1, 'push_heap_min: new min bubbles up');

    is(scalar(@arr), 4, 'push_heap_min: correct size');
};

subtest 'pop_heap_min basic' => sub {
    my @arr = (1, 3, 2, 5, 4);
    Heap::PQ::make_heap_min(\@arr);

    my @popped;
    while (@arr) {
        push @popped, Heap::PQ::pop_heap_min(\@arr);
    }

    is_deeply(\@popped, [1, 2, 3, 4, 5], 'pop_heap_min: elements in sorted order');
};

subtest 'pop_heap_min empty array' => sub {
    my @arr;
    my $result = Heap::PQ::pop_heap_min(\@arr);
    is($result, undef, 'pop_heap_min: empty array returns undef');
};

# --------------------------------------------
# push_heap_max / pop_heap_max
# --------------------------------------------

subtest 'push_heap_max basic' => sub {
    my @arr;

    Heap::PQ::push_heap_max(\@arr, 3);
    is($arr[0], 3, 'push_heap_max: first element');

    Heap::PQ::push_heap_max(\@arr, 5);
    is($arr[0], 5, 'push_heap_max: new max bubbles up');

    Heap::PQ::push_heap_max(\@arr, 1);
    is($arr[0], 5, 'push_heap_max: max stays at root');

    Heap::PQ::push_heap_max(\@arr, 7);
    is($arr[0], 7, 'push_heap_max: new max bubbles up');

    is(scalar(@arr), 4, 'push_heap_max: correct size');
};

subtest 'pop_heap_max basic' => sub {
    my @arr = (1, 3, 2, 5, 4);
    Heap::PQ::make_heap_max(\@arr);

    my @popped;
    while (@arr) {
        push @popped, Heap::PQ::pop_heap_max(\@arr);
    }

    is_deeply(\@popped, [5, 4, 3, 2, 1], 'pop_heap_max: elements in reverse sorted order');
};

subtest 'pop_heap_max empty array' => sub {
    my @arr;
    my $result = Heap::PQ::pop_heap_max(\@arr);
    is($result, undef, 'pop_heap_max: empty array returns undef');
};

# --------------------------------------------
# Combined operations
# --------------------------------------------

subtest 'min-heap priority queue pattern' => sub {
    my @pq;

    # Add tasks with priorities (lower = higher priority)
    Heap::PQ::push_heap_min(\@pq, 5);  # priority 5
    Heap::PQ::push_heap_min(\@pq, 1);  # priority 1 (highest)
    Heap::PQ::push_heap_min(\@pq, 3);  # priority 3
    Heap::PQ::push_heap_min(\@pq, 2);  # priority 2
    Heap::PQ::push_heap_min(\@pq, 4);  # priority 4

    # Process in priority order
    my @order;
    while (@pq) {
        push @order, Heap::PQ::pop_heap_min(\@pq);
    }

    is_deeply(\@order, [1, 2, 3, 4, 5], 'min-heap: correct priority order');
};

subtest 'max-heap priority queue pattern' => sub {
    my @pq;

    # Add tasks (higher = higher priority)
    Heap::PQ::push_heap_max(\@pq, 10);
    Heap::PQ::push_heap_max(\@pq, 50);  # highest priority
    Heap::PQ::push_heap_max(\@pq, 30);
    Heap::PQ::push_heap_max(\@pq, 20);
    Heap::PQ::push_heap_max(\@pq, 40);

    # Process in priority order
    my @order;
    while (@pq) {
        push @order, Heap::PQ::pop_heap_max(\@pq);
    }

    is_deeply(\@order, [50, 40, 30, 20, 10], 'max-heap: correct priority order');
};

subtest 'large dataset' => sub {
    my @arr = map { int(rand(10000)) } 1..1000;
    my @sorted = sort { $a <=> $b } @arr;

    Heap::PQ::make_heap_min(\@arr);

    my @result;
    while (@arr) {
        push @result, Heap::PQ::pop_heap_min(\@arr);
    }

    is_deeply(\@result, \@sorted, 'large dataset sorted correctly');
};

subtest 'floats and negatives' => sub {
    my @arr = (3.14, -2.71, 0, 1.41, -1.73);
    Heap::PQ::make_heap_min(\@arr);

    my @result;
    while (@arr) {
        push @result, Heap::PQ::pop_heap_min(\@arr);
    }

    is_deeply(\@result, [-2.71, -1.73, 0, 1.41, 3.14], 'floats and negatives sorted');
};

done_testing;
