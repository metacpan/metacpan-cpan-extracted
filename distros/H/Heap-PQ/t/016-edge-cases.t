#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Heap::PQ;

# ============================================
# Edge cases: error handling, boundaries, unusual inputs
# ============================================

# --- Error handling: invalid constructor args ---

subtest 'constructor with no args defaults to min' => sub {
    my $h = Heap::PQ::new();
    ok(defined $h, 'new() with no args creates heap');
    $h->push(3);
    $h->push(1);
    $h->push(2);
    is($h->pop, 1, 'default constructor is min-heap');
};

subtest 'new_nv with no args defaults to min' => sub {
    my $h = Heap::PQ::new_nv();
    ok(defined $h, 'new_nv() with no args creates heap');
    $h->push(3);
    $h->push(1);
    $h->push(2);
    is($h->pop, 1, 'default nv constructor is min-heap');
};

# --- Raw array API error handling ---

subtest 'raw API croaks on non-arrayref' => sub {
    eval { Heap::PQ::push_heap_min("not_a_ref", 5) };
    like($@, qr/array reference/i, 'push_heap_min croaks on string');

    eval { Heap::PQ::push_heap_max({}, 5) };
    like($@, qr/array reference/i, 'push_heap_max croaks on hashref');

    eval { Heap::PQ::pop_heap_min("not_a_ref") };
    like($@, qr/array reference/i, 'pop_heap_min croaks on string');

    eval { Heap::PQ::pop_heap_max(42) };
    like($@, qr/array reference/i, 'pop_heap_max croaks on scalar');

    eval { Heap::PQ::make_heap_min("not_a_ref") };
    like($@, qr/array reference/i, 'make_heap_min croaks on string');

    eval { Heap::PQ::make_heap_max({}) };
    like($@, qr/array reference/i, 'make_heap_max croaks on hashref');
};

# --- Pop/Peek on empty heaps ---

subtest 'repeated pop on empty heap' => sub {
    my $h = Heap::PQ::new('min');
    is($h->pop, undef, 'first pop on empty');
    is($h->pop, undef, 'second pop on empty');
    is($h->pop, undef, 'third pop on empty');
    is($h->size, 0, 'size stays 0');
};

subtest 'repeated pop on empty nv heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    is($h->pop, undef, 'first nv pop on empty');
    is($h->pop, undef, 'second nv pop on empty');
    is($h->size, 0, 'nv size stays 0');
};

# --- Single element ---

subtest 'single element heap' => sub {
    my $h = Heap::PQ::new('min');
    $h->push(42);
    is($h->peek, 42, 'peek single element');
    is($h->size, 1, 'size is 1');
    is($h->pop, 42, 'pop single element');
    is($h->pop, undef, 'pop after single element');
    ok($h->is_empty, 'empty after pop');
};

subtest 'single element nv heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push(42.5);
    is($h->peek, 42.5, 'nv peek single element');
    is($h->pop, 42.5, 'nv pop single element');
    is($h->pop, undef, 'nv pop after single element');
};

# --- push_all with empty list ---

subtest 'push_all with no values' => sub {
    my $h = Heap::PQ::new('min');
    $h->push_all();
    is($h->size, 0, 'push_all() with no args keeps size 0');

    $h->push(5);
    $h->push_all();
    is($h->size, 1, 'push_all() with no args after push keeps size');
};

subtest 'nv push_all with no values' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push_all();
    is($h->size, 0, 'nv push_all() with no args keeps size 0');
};

# --- push_all with single value ---

subtest 'push_all with single value' => sub {
    my $h = Heap::PQ::new('min');
    $h->push_all(99);
    is($h->size, 1, 'push_all(99) size is 1');
    is($h->pop, 99, 'push_all(99) pop returns 99');
};

# --- Interleaved push/pop on OO heap ---

subtest 'interleaved push/pop OO min-heap' => sub {
    my $h = Heap::PQ::new('min');

    $h->push(5);
    $h->push(3);
    is($h->pop, 3, 'pop after 2 pushes');

    $h->push(1);
    is($h->pop, 1, 'pop returns new min');
    is($h->pop, 5, 'pop returns remaining');
    is($h->pop, undef, 'empty after all pops');

    # Repopulate
    $h->push(10);
    $h->push(20);
    $h->push(15);
    is($h->pop, 10, 'repopulated pop 1');
    $h->push(5);
    is($h->pop, 5, 'newly pushed element is new min');
    is($h->pop, 15, 'pop 3');
    is($h->pop, 20, 'pop 4');
};

subtest 'interleaved push/pop OO max-heap' => sub {
    my $h = Heap::PQ::new('max');

    $h->push(5);
    $h->push(3);
    is($h->pop, 5, 'max-heap pop after 2 pushes');

    $h->push(10);
    is($h->pop, 10, 'max-heap new max');
    is($h->pop, 3, 'max-heap remaining');
};

# --- Capacity boundary (trigger realloc at 16 -> 32) ---

subtest 'capacity boundary crossing' => sub {
    my $h = Heap::PQ::new('min');

    # Push exactly 17 elements to cross the initial capacity of 16
    for my $i (reverse 1..17) {
        $h->push($i);
    }
    is($h->size, 17, 'size after 17 pushes');
    is($h->peek, 1, 'min is correct after realloc');

    # Verify full ordering
    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }
    my @expected = (1..17);
    is_deeply(\@out, \@expected, 'correct order after capacity growth');
};

subtest 'nv capacity boundary crossing' => sub {
    my $h = Heap::PQ::new_nv('min');

    for my $i (reverse 1..17) {
        $h->push($i + 0.5);
    }
    is($h->size, 17, 'nv size after 17 pushes');
    is($h->peek, 1.5, 'nv min correct after realloc');

    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }
    my @expected = map { $_ + 0.5 } (1..17);
    is_deeply(\@out, \@expected, 'nv correct order after capacity growth');
};

# --- Clear then reuse ---

subtest 'clear and reuse heap' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1..10);
    $h->clear;
    is($h->size, 0, 'size 0 after clear');
    ok($h->is_empty, 'is_empty after clear');
    is($h->peek, undef, 'peek undef after clear');
    is($h->pop, undef, 'pop undef after clear');

    # Reuse
    $h->push(99);
    $h->push(1);
    is($h->pop, 1, 'works correctly after clear and reuse');
    is($h->pop, 99, 'second pop after reuse');
};

subtest 'nv clear and reuse' => sub {
    my $h = Heap::PQ::new_nv('max');
    $h->push($_) for (1..10);
    $h->clear;
    is($h->size, 0, 'nv size 0 after clear');

    $h->push(3.14);
    $h->push(2.71);
    is($h->pop, 3.14, 'nv max-heap works after clear');
};

# --- Negative numbers ---

subtest 'nv heap with negative numbers' => sub {
    my $h = Heap::PQ::new_nv('min');

    $h->push(-5.5);
    $h->push(-1.1);
    $h->push(-10.0);
    $h->push(0);
    $h->push(3.3);

    is($h->pop, -10.0, 'nv pop -10.0');
    is($h->pop, -5.5, 'nv pop -5.5');
    is($h->pop, -1.1, 'nv pop -1.1');
    is($h->pop, 0, 'nv pop 0');
    is($h->pop, 3.3, 'nv pop 3.3');
};

# --- Very large and very small NV values ---

subtest 'nv extreme values' => sub {
    my $h = Heap::PQ::new_nv('min');

    $h->push(1e308);
    $h->push(-1e308);
    $h->push(1e-308);
    $h->push(0);

    is($h->pop, -1e308, 'nv pop -1e308');
    is($h->pop, 0, 'nv pop 0');
    is($h->pop, 1e-308, 'nv pop 1e-308');
    is($h->pop, 1e308, 'nv pop 1e308');
};

# --- Duplicate values ---

subtest 'many duplicates OO heap' => sub {
    my $h = Heap::PQ::new('min');
    $h->push(5) for 1..20;
    is($h->size, 20, '20 duplicates pushed');
    my $count = 0;
    while (!$h->is_empty) {
        is($h->pop, 5, "dup pop $count");
        $count++;
    }
    is($count, 20, 'got all 20 duplicates back');
};

subtest 'many duplicates nv heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push(3.14) for 1..20;
    is($h->size, 20, 'nv 20 duplicates pushed');
    my $count = 0;
    while (!$h->is_empty) {
        is($h->pop, 3.14, "nv dup pop $count");
        $count++;
    }
    is($count, 20, 'nv got all 20 duplicates back');
};

# --- NV functional-style ops via Heap::PQ::nv:: ---

subtest 'nv functional-style push/pop/peek/size' => sub {
    my $h = Heap::PQ::new_nv('min');

    Heap::PQ::nv::push($h, 5.5);
    Heap::PQ::nv::push($h, 3.3);
    Heap::PQ::nv::push($h, 7.7);
    Heap::PQ::nv::push($h, 1.1);

    is(Heap::PQ::nv::size($h), 4, 'nv func size');
    is(Heap::PQ::nv::peek($h), 1.1, 'nv func peek');

    is(Heap::PQ::nv::pop($h), 1.1, 'nv func pop 1');
    is(Heap::PQ::nv::pop($h), 3.3, 'nv func pop 2');
    is(Heap::PQ::nv::pop($h), 5.5, 'nv func pop 3');
    is(Heap::PQ::nv::pop($h), 7.7, 'nv func pop 4');

    is(Heap::PQ::nv::size($h), 0, 'nv func size after all pops');
};

subtest 'nv functional-style max-heap' => sub {
    my $h = Heap::PQ::new_nv('max');

    Heap::PQ::nv::push($h, 10);
    Heap::PQ::nv::push($h, 30);
    Heap::PQ::nv::push($h, 20);

    is(Heap::PQ::nv::peek($h), 30, 'nv func max peek');
    is(Heap::PQ::nv::pop($h), 30, 'nv func max pop 1');
    is(Heap::PQ::nv::pop($h), 20, 'nv func max pop 2');
    is(Heap::PQ::nv::pop($h), 10, 'nv func max pop 3');
};

subtest 'nv functional empty operations' => sub {
    my $h = Heap::PQ::new_nv('min');
    is(Heap::PQ::nv::size($h), 0, 'nv func size on empty');
    is(Heap::PQ::nv::peek($h), undef, 'nv func peek on empty');
    is(Heap::PQ::nv::pop($h), undef, 'nv func pop on empty');
};

# --- nv functional ops interleaved with OO ---

subtest 'nv functional mixed with OO methods' => sub {
    my $h = Heap::PQ::new_nv('min');

    Heap::PQ::nv::push($h, 10);
    $h->push(5);
    Heap::PQ::nv::push($h, 15);
    $h->push(1);

    is(Heap::PQ::nv::size($h), 4, 'mixed nv size');
    is($h->peek, 1, 'OO peek after mixed pushes');
    is(Heap::PQ::nv::pop($h), 1, 'nv func pop');
    is($h->pop, 5, 'OO pop');
    is(Heap::PQ::nv::peek($h), 10, 'nv func peek');
};

# --- Heap going out of scope with elements (DESTROY) ---

subtest 'heap DESTROY with remaining elements' => sub {
    my $destroyed;
    {
        my $h = Heap::PQ::new('min');
        $h->push(1);
        $h->push(2);
        $h->push(3);
        # heap goes out of scope with elements still in it
        $destroyed = 1;
    }
    ok($destroyed, 'heap with elements destroyed without crash');
};

subtest 'nv heap DESTROY with remaining elements' => sub {
    my $destroyed;
    {
        my $h = Heap::PQ::new_nv('min');
        $h->push(1.1);
        $h->push(2.2);
        $h->push(3.3);
    }
    $destroyed = 1;
    ok($destroyed, 'nv heap with elements destroyed without crash');
};

# --- Heap with string-like numbers ---

subtest 'heap with string numbers' => sub {
    my $h = Heap::PQ::new('min');
    $h->push("10");
    $h->push("2");
    $h->push("30");
    $h->push("1");

    # Numeric comparison should be used
    is($h->pop, 1, 'string "1" sorted numerically');
    is($h->pop, 2, 'string "2" sorted numerically');
    is($h->pop, 10, 'string "10" sorted numerically');
    is($h->pop, 30, 'string "30" sorted numerically');
};

# --- Raw array edge cases ---

subtest 'raw array pop from single element' => sub {
    my @arr = (42);
    my $val = Heap::PQ::pop_heap_min(\@arr);
    is($val, 42, 'pop from single-element array');
    is(scalar @arr, 0, 'array empty after pop');
};

subtest 'raw array pop from empty' => sub {
    my @arr;
    my $val = Heap::PQ::pop_heap_min(\@arr);
    is($val, undef, 'pop from empty array returns undef');
    is(scalar @arr, 0, 'array still empty');
};

subtest 'raw array make_heap on already sorted' => sub {
    my @arr = (1, 2, 3, 4, 5);
    Heap::PQ::make_heap_min(\@arr);

    my @out;
    while (@arr) {
        push @out, Heap::PQ::pop_heap_min(\@arr);
    }
    is_deeply(\@out, [1, 2, 3, 4, 5], 'make_heap_min on sorted preserves order');
};

subtest 'raw array make_heap on reverse sorted' => sub {
    my @arr = (5, 4, 3, 2, 1);
    Heap::PQ::make_heap_min(\@arr);

    my @out;
    while (@arr) {
        push @out, Heap::PQ::pop_heap_min(\@arr);
    }
    is_deeply(\@out, [1, 2, 3, 4, 5], 'make_heap_min on reverse sorted');
};

subtest 'raw array make_heap on empty' => sub {
    my @arr;
    Heap::PQ::make_heap_min(\@arr);
    is(scalar @arr, 0, 'make_heap_min on empty array is fine');
};

subtest 'raw array make_heap on single element' => sub {
    my @arr = (7);
    Heap::PQ::make_heap_min(\@arr);
    is($arr[0], 7, 'single element unchanged');
    is(Heap::PQ::pop_heap_min(\@arr), 7, 'pop returns element');
};

# --- Large stress test ---

subtest 'large OO heap sort correctness' => sub {
    my $h = Heap::PQ::new('min');
    my @input = map { int(rand(100000)) } 1..1000;

    $h->push($_) for @input;
    is($h->size, 1000, 'pushed 1000 elements');

    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }

    my @sorted = sort { $a <=> $b } @input;
    is_deeply(\@out, \@sorted, '1000 element heapsort correct');
};

subtest 'large nv heap sort correctness' => sub {
    my $h = Heap::PQ::new_nv('max');
    my @input = map { rand(100000) } 1..1000;

    $h->push($_) for @input;
    is($h->size, 1000, 'nv pushed 1000 elements');

    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }

    my @sorted = sort { $b <=> $a } @input;
    is(scalar @out, scalar @sorted, 'nv 1000 element count');
    # Float comparison with tolerance
    for my $i (0..$#sorted) {
        ok(abs($out[$i] - $sorted[$i]) < 1e-9, "nv element $i correct")
            or last;  # stop on first failure to avoid 1000 failures
    }
};

# --- Comparator edge cases ---

subtest 'comparator with reverse numeric' => sub {
    my $h = Heap::PQ::new('min', sub { $b <=> $a });
    $h->push(1);
    $h->push(5);
    $h->push(3);

    # Reversed comparator on min-heap = effectively max-heap
    is($h->pop, 5, 'reversed comparator: pop 5 first');
    is($h->pop, 3, 'reversed comparator: pop 3');
    is($h->pop, 1, 'reversed comparator: pop 1');
};

subtest 'comparator with string cmp' => sub {
    my $h = Heap::PQ::new('min', sub { $a cmp $b });
    $h->push("banana");
    $h->push("apple");
    $h->push("cherry");

    is($h->pop, "apple", 'string cmp: apple');
    is($h->pop, "banana", 'string cmp: banana');
    is($h->pop, "cherry", 'string cmp: cherry');
};

subtest 'comparator at scale' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{pri} <=> $b->{pri} });

    for my $i (1..100) {
        $h->push({ pri => int(rand(1000)), val => "item_$i" });
    }

    my @pris;
    while (!$h->is_empty) {
        push @pris, $h->pop->{pri};
    }

    my @sorted = sort { $a <=> $b } @pris;
    is_deeply(\@pris, \@sorted, '100 elements with comparator sorted correctly');
};

# --- push_all bulk on nv heap ---

subtest 'nv push_all bulk' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push_all(5.5, 3.3, 7.7, 1.1, 4.4);

    is($h->size, 5, 'nv push_all size');
    is($h->pop, 1.1, 'nv push_all pop 1');
    is($h->pop, 3.3, 'nv push_all pop 2');
    is($h->pop, 4.4, 'nv push_all pop 3');
    is($h->pop, 5.5, 'nv push_all pop 4');
    is($h->pop, 7.7, 'nv push_all pop 5');
};

# --- Type method ---

subtest 'OO heap type method' => sub {
    my $min = Heap::PQ::new('min');
    is($min->type, 'min', 'min type');

    my $max = Heap::PQ::new('max');
    is($max->type, 'max', 'max type');
};

# --- is_empty consistency ---

subtest 'is_empty transitions' => sub {
    my $h = Heap::PQ::new('min');
    ok($h->is_empty, 'empty at start');

    $h->push(1);
    ok(!$h->is_empty, 'not empty after push');

    $h->pop;
    ok($h->is_empty, 'empty after pop');

    $h->push(1);
    $h->push(2);
    $h->clear;
    ok($h->is_empty, 'empty after clear');
};

subtest 'nv is_empty transitions' => sub {
    my $h = Heap::PQ::new_nv('min');
    ok($h->is_empty, 'nv empty at start');

    $h->push(1.0);
    ok(!$h->is_empty, 'nv not empty after push');

    $h->pop;
    ok($h->is_empty, 'nv empty after pop');

    $h->push(1.0);
    $h->push(2.0);
    $h->clear;
    ok($h->is_empty, 'nv empty after clear');
};

done_testing;
