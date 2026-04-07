#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Heap::PQ 'import';

# ============================================
# search($coderef) - find elements matching condition
# delete($coderef) - remove matching elements, rebuild heap
# ============================================

# --- OO heap search ---

subtest 'search basic min-heap' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1, 5, 3, 8, 2, 7, 4, 6);

    my @found = $h->search(sub { $_ > 5 });
    my @sorted = sort { $a <=> $b } @found;
    is_deeply(\@sorted, [6, 7, 8], 'search finds elements > 5');
    is($h->size, 8, 'heap unchanged after search');
};

subtest 'search returns empty when nothing matches' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1, 2, 3);

    my @found = $h->search(sub { $_ > 100 });
    is(scalar @found, 0, 'no matches returns empty list');
    is($h->size, 3, 'heap unchanged');
};

subtest 'search returns all when everything matches' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1, 2, 3);

    my @found = $h->search(sub { 1 });
    my @sorted = sort { $a <=> $b } @found;
    is_deeply(\@sorted, [1, 2, 3], 'all elements match');
};

subtest 'search on empty heap' => sub {
    my $h = Heap::PQ::new('min');
    my @found = $h->search(sub { 1 });
    is(scalar @found, 0, 'search on empty returns empty');
};

subtest 'search with $_ and argument' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (10, 20, 30, 40, 50);

    # Both $_ and $_[0] should work
    my @via_topic = $h->search(sub { $_ >= 30 });
    my @via_arg = $h->search(sub { $_[0] >= 30 });

    my @s1 = sort { $a <=> $b } @via_topic;
    my @s2 = sort { $a <=> $b } @via_arg;
    is_deeply(\@s1, [30, 40, 50], 'search via $_');
    is_deeply(\@s2, [30, 40, 50], 'search via $_[0]');
};

subtest 'search with complex objects' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{pri} <=> $b->{pri} });
    $h->push({ name => 'alice', pri => 1 });
    $h->push({ name => 'bob',   pri => 5 });
    $h->push({ name => 'carol', pri => 3 });

    my @found = $h->search(sub { $_->{name} =~ /^[ab]/ });
    my @names = sort map { $_->{name} } @found;
    is_deeply(\@names, ['alice', 'bob'], 'search on complex objects');
};

subtest 'search with single element' => sub {
    my $h = Heap::PQ::new('min');
    $h->push(42);

    my @found = $h->search(sub { $_ == 42 });
    is_deeply(\@found, [42], 'search finds single element');

    @found = $h->search(sub { $_ == 99 });
    is(scalar @found, 0, 'search misses non-matching single element');
};

# --- OO heap delete ---

subtest 'delete basic' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1, 5, 3, 8, 2, 7, 4, 6);

    my $count = $h->delete(sub { $_ > 5 });
    is($count, 3, 'deleted 3 elements');
    is($h->size, 5, 'size reduced to 5');

    # Verify heap property maintained
    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }
    is_deeply(\@out, [1, 2, 3, 4, 5], 'remaining elements sorted correctly');
};

subtest 'delete nothing when no match' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1, 2, 3);

    my $count = $h->delete(sub { $_ > 100 });
    is($count, 0, 'nothing deleted');
    is($h->size, 3, 'size unchanged');

    is($h->pop, 1, 'heap still works');
};

subtest 'delete all elements' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1, 2, 3);

    my $count = $h->delete(sub { 1 });
    is($count, 3, 'deleted all 3');
    is($h->size, 0, 'heap is empty');
    ok($h->is_empty, 'is_empty returns true');
};

subtest 'delete on empty heap' => sub {
    my $h = Heap::PQ::new('min');
    my $count = $h->delete(sub { 1 });
    is($count, 0, 'delete on empty returns 0');
};

subtest 'delete preserves max-heap property' => sub {
    my $h = Heap::PQ::new('max');
    $h->push($_) for (1, 5, 3, 8, 2, 7, 4, 6);

    $h->delete(sub { $_ % 2 == 0 });  # Remove evens
    is($h->size, 4, '4 odd numbers remain');

    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }
    is_deeply(\@out, [7, 5, 3, 1], 'max-heap order preserved after delete');
};

subtest 'delete single match' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (10, 20, 30, 40, 50);

    my $count = $h->delete(sub { $_ == 30 });
    is($count, 1, 'deleted 1 element');
    is($h->size, 4, 'size is 4');

    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }
    is_deeply(\@out, [10, 20, 40, 50], 'correct elements remain');
};

subtest 'delete with complex objects' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{pri} <=> $b->{pri} });
    $h->push({ name => 'alice', pri => 1 });
    $h->push({ name => 'bob',   pri => 5 });
    $h->push({ name => 'carol', pri => 3 });
    $h->push({ name => 'dave',  pri => 2 });

    my $count = $h->delete(sub { $_->{pri} > 3 });
    is($count, 1, 'deleted bob');
    is($h->size, 3, '3 remain');

    is($h->pop->{name}, 'alice', 'alice first');
    is($h->pop->{name}, 'dave', 'dave second');
    is($h->pop->{name}, 'carol', 'carol third');
};

subtest 'delete then push works' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1, 2, 3, 4, 5);
    $h->delete(sub { $_ <= 3 });

    $h->push(0);
    is($h->pop, 0, 'push after delete works');
    is($h->pop, 4, 'remaining order correct');
    is($h->pop, 5, 'all remaining correct');
};

subtest 'search then delete same condition' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1..10);

    my @found = $h->search(sub { $_ % 3 == 0 });
    is(scalar @found, 3, 'search finds 3 multiples of 3');
    my @sorted_found = sort { $a <=> $b } @found;
    is_deeply(\@sorted_found, [3, 6, 9], 'search finds multiples of 3');

    my $count = $h->delete(sub { $_ % 3 == 0 });
    is($count, 3, 'delete removes multiples of 3');
    is($h->size, 7, '7 remain');

    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }
    is_deeply(\@out, [1, 2, 4, 5, 7, 8, 10], 'correct elements remain');
};

# --- NV heap search ---

subtest 'nv search basic' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (1.1, 5.5, 3.3, 8.8, 2.2);

    my @found = $h->search(sub { $_ > 4 });
    my @sorted = sort { $a <=> $b } @found;
    is_deeply(\@sorted, [5.5, 8.8], 'nv search finds elements > 4');
    is($h->size, 5, 'nv heap unchanged');
};

subtest 'nv search empty result' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (1, 2, 3);

    my @found = $h->search(sub { $_ > 100 });
    is(scalar @found, 0, 'nv search no matches');
};

subtest 'nv search on empty heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    my @found = $h->search(sub { 1 });
    is(scalar @found, 0, 'nv search on empty');
};

# --- NV heap delete ---

subtest 'nv delete basic' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (1, 5, 3, 8, 2, 7, 4, 6);

    my $count = $h->delete(sub { $_ > 5 });
    is($count, 3, 'nv deleted 3');
    is($h->size, 5, 'nv size 5');

    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }
    is_deeply(\@out, [1, 2, 3, 4, 5], 'nv remaining sorted');
};

subtest 'nv delete preserves max-heap' => sub {
    my $h = Heap::PQ::new_nv('max');
    $h->push($_) for (1, 5, 3, 8, 2, 7, 4, 6);

    $h->delete(sub { $_ < 4 });
    is($h->size, 5, 'nv 5 remain');

    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }
    is_deeply(\@out, [8, 7, 6, 5, 4], 'nv max-heap order preserved');
};

subtest 'nv delete all' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (1, 2, 3);
    my $count = $h->delete(sub { 1 });
    is($count, 3, 'nv deleted all');
    ok($h->is_empty, 'nv empty after delete all');
};

subtest 'nv delete then push' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (10, 20, 30, 40, 50);
    $h->delete(sub { $_ > 25 });

    $h->push(5);
    is($h->pop, 5, 'nv push after delete works');
    is($h->pop, 10, 'nv remaining order correct');
};

# --- Error handling ---

subtest 'search croaks on non-coderef' => sub {
    my $h = Heap::PQ::new('min');
    $h->push(1);

    eval { $h->search("not a coderef") };
    like($@, qr/code reference/i, 'search croaks on string');

    eval { $h->search(42) };
    like($@, qr/code reference/i, 'search croaks on number');
};

subtest 'delete croaks on non-coderef' => sub {
    my $h = Heap::PQ::new('min');
    $h->push(1);

    eval { $h->delete("not a coderef") };
    like($@, qr/code reference/i, 'delete croaks on string');
};

subtest 'nv search croaks on non-coderef' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push(1);

    eval { $h->search([]) };
    like($@, qr/code reference/i, 'nv search croaks on arrayref');
};

subtest 'nv delete croaks on non-coderef' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push(1);

    eval { $h->delete({}) };
    like($@, qr/code reference/i, 'nv delete croaks on hashref');
};

# --- Functional interface (heap_search / heap_delete) ---

subtest 'functional heap_search on OO heap' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1, 5, 3, 8, 2, 7, 4, 6);

    my @found = heap_search($h, sub { $_ > 5 });
    my @sorted = sort { $a <=> $b } @found;
    is_deeply(\@sorted, [6, 7, 8], 'heap_search finds elements > 5');
    is($h->size, 8, 'heap unchanged');
};

subtest 'functional heap_delete on OO heap' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (1, 5, 3, 8, 2, 7, 4, 6);

    my $count = heap_delete($h, sub { $_ > 5 });
    is($count, 3, 'heap_delete removed 3');
    is($h->size, 5, 'size is 5');

    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }
    is_deeply(\@out, [1, 2, 3, 4, 5], 'remaining sorted correctly');
};

subtest 'functional heap_search on NV heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (1.1, 5.5, 3.3, 8.8, 2.2);

    my @found = heap_search($h, sub { $_ > 4 });
    my @sorted = sort { $a <=> $b } @found;
    is_deeply(\@sorted, [5.5, 8.8], 'heap_search on NV heap');
};

subtest 'functional heap_delete on NV heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (1, 5, 3, 8, 2, 7, 4, 6);

    my $count = heap_delete($h, sub { $_ > 5 });
    is($count, 3, 'heap_delete on NV removed 3');

    my @out;
    while (!$h->is_empty) {
        push @out, $h->pop;
    }
    is_deeply(\@out, [1, 2, 3, 4, 5], 'NV remaining sorted');
};

subtest 'functional heap_search empty heap' => sub {
    my $h = Heap::PQ::new('min');
    my @found = heap_search($h, sub { 1 });
    is(scalar @found, 0, 'search on empty via functional');
};

subtest 'functional heap_delete empty heap' => sub {
    my $h = Heap::PQ::new('min');
    my $count = heap_delete($h, sub { 1 });
    is($count, 0, 'delete on empty via functional');
};

subtest 'functional nv::search direct' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (10, 20, 30, 40, 50);

    my @found = Heap::PQ::nv::search($h, sub { $_ >= 30 });
    my @sorted = sort { $a <=> $b } @found;
    is_deeply(\@sorted, [30, 40, 50], 'nv::search finds >= 30');
};

subtest 'functional nv::delete direct' => sub {
    my $h = Heap::PQ::new_nv('max');
    $h->push($_) for (10, 20, 30, 40, 50);

    my $count = Heap::PQ::nv::delete($h, sub { $_ <= 20 });
    is($count, 2, 'nv::delete removed 2');
    is($h->pop, 50, 'max still correct');
};

done_testing;
