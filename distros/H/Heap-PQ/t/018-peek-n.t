#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Heap::PQ;
use Heap::PQ 'import';

# ============================================
# peek_n - return top N elements in sorted order without removing
# ============================================

subtest 'OO min-heap peek_n basic' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (5, 3, 7, 1, 4, 2, 8, 6);

    my @top3 = $h->peek_n(3);
    is_deeply(\@top3, [1, 2, 3], 'peek_n(3) returns top 3 sorted');
    is($h->size, 8, 'heap unchanged after peek_n');
    is($h->peek, 1, 'peek still returns min');
};

subtest 'OO max-heap peek_n basic' => sub {
    my $h = Heap::PQ::new('max');
    $h->push($_) for (5, 3, 7, 1, 4, 2, 8, 6);

    my @top3 = $h->peek_n(3);
    is_deeply(\@top3, [8, 7, 6], 'max-heap peek_n(3) returns top 3 descending');
    is($h->size, 8, 'heap unchanged');
};

subtest 'peek_n returns all when n > size' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (3, 1, 2);

    my @all = $h->peek_n(10);
    is_deeply(\@all, [1, 2, 3], 'peek_n(10) on 3-element heap returns all 3 sorted');
    is($h->size, 3, 'heap unchanged');
};

subtest 'peek_n with n = size' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (5, 3, 1);

    my @all = $h->peek_n(3);
    is_deeply(\@all, [1, 3, 5], 'peek_n(size) returns all sorted');
    is($h->size, 3, 'heap unchanged');
};

subtest 'peek_n with n = 1' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (5, 3, 1);

    my @top = $h->peek_n(1);
    is_deeply(\@top, [1], 'peek_n(1) returns just the top');
};

subtest 'peek_n on empty heap' => sub {
    my $h = Heap::PQ::new('min');
    my @result = $h->peek_n(5);
    is(scalar @result, 0, 'peek_n on empty heap returns empty list');
};

subtest 'peek_n with n = 0' => sub {
    my $h = Heap::PQ::new('min');
    $h->push(42);
    my @result = $h->peek_n(0);
    is(scalar @result, 0, 'peek_n(0) returns empty list');
};

subtest 'peek_n with negative n' => sub {
    my $h = Heap::PQ::new('min');
    $h->push(42);
    my @result = $h->peek_n(-1);
    is(scalar @result, 0, 'peek_n(-1) returns empty list');
};

subtest 'peek_n preserves heap for subsequent operations' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (10, 5, 8, 3, 7);

    my @top = $h->peek_n(3);
    is_deeply(\@top, [3, 5, 7], 'peek_n correct');

    # Now do real operations - heap should be intact
    is($h->pop, 3, 'pop after peek_n returns 3');
    is($h->pop, 5, 'pop returns 5');
    is($h->pop, 7, 'pop returns 7');
    is($h->pop, 8, 'pop returns 8');
    is($h->pop, 10, 'pop returns 10');
    ok($h->is_empty, 'heap empty after all pops');
};

subtest 'peek_n repeated calls give same result' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (9, 2, 7, 4, 1);

    my @first = $h->peek_n(3);
    my @second = $h->peek_n(3);
    is_deeply(\@first, \@second, 'repeated peek_n gives same result');
    is_deeply(\@first, [1, 2, 4], 'and result is correct');
};

subtest 'peek_n with custom comparator' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{pri} <=> $b->{pri} });
    $h->push({ name => 'c', pri => 3 });
    $h->push({ name => 'a', pri => 1 });
    $h->push({ name => 'b', pri => 2 });

    my @top2 = $h->peek_n(2);
    is($top2[0]->{name}, 'a', 'comparator peek_n first is a');
    is($top2[1]->{name}, 'b', 'comparator peek_n second is b');
    is($h->size, 3, 'heap unchanged');
};

subtest 'peek_n with duplicates' => sub {
    my $h = Heap::PQ::new('min');
    $h->push(5) for 1..5;
    $h->push(1) for 1..3;

    my @top4 = $h->peek_n(4);
    is_deeply(\@top4, [1, 1, 1, 5], 'peek_n with duplicates');
    is($h->size, 8, 'heap unchanged');
};

# --- NV heap peek_n ---

subtest 'NV min-heap peek_n basic' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (5.5, 3.3, 7.7, 1.1, 4.4);

    my @top3 = $h->peek_n(3);
    is_deeply(\@top3, [1.1, 3.3, 4.4], 'nv peek_n(3) returns top 3 sorted');
    is($h->size, 5, 'nv heap unchanged');
};

subtest 'NV max-heap peek_n basic' => sub {
    my $h = Heap::PQ::new_nv('max');
    $h->push($_) for (5.5, 3.3, 7.7, 1.1, 4.4);

    my @top2 = $h->peek_n(2);
    is_deeply(\@top2, [7.7, 5.5], 'nv max peek_n(2)');
    is($h->size, 5, 'nv heap unchanged');
};

subtest 'NV peek_n on empty' => sub {
    my $h = Heap::PQ::new_nv('min');
    my @result = $h->peek_n(5);
    is(scalar @result, 0, 'nv peek_n on empty returns empty');
};

subtest 'NV peek_n preserves heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (10, 5, 8, 3, 7);

    my @top = $h->peek_n(2);
    is_deeply(\@top, [3, 5], 'nv peek_n correct');

    is($h->pop, 3, 'nv pop after peek_n');
    is($h->pop, 5, 'nv pop 2');
    is($h->pop, 7, 'nv pop 3');
    is($h->pop, 8, 'nv pop 4');
    is($h->pop, 10, 'nv pop 5');
};

subtest 'NV peek_n n > size' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push(2.2);
    $h->push(1.1);

    my @all = $h->peek_n(100);
    is_deeply(\@all, [1.1, 2.2], 'nv peek_n(100) on 2-element heap');
    is($h->size, 2, 'nv heap unchanged');
};

subtest 'NV peek_n large heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push(rand(10000)) for 1..1000;

    my @top10 = $h->peek_n(10);
    is(scalar @top10, 10, 'got 10 elements');
    is($h->size, 1000, 'heap still has 1000');

    # Verify sorted
    for my $i (1..$#top10) {
        ok($top10[$i] >= $top10[$i-1], "element $i >= element " . ($i-1))
            or last;
    }
};

# --- Functional-style peek_n via import ---

subtest 'functional heap_peek_n via import' => sub {
    my $h = Heap::PQ::new('min');
    heap_push($h, $_) for (5, 3, 7, 1, 4, 2);

    my @top3 = heap_peek_n($h, 3);
    is_deeply(\@top3, [1, 2, 3], 'heap_peek_n returns top 3 sorted');
    is(heap_size($h), 6, 'heap unchanged after heap_peek_n');
};

subtest 'functional heap_peek_n with max-heap' => sub {
    my $h = Heap::PQ::new('max');
    heap_push($h, $_) for (5, 3, 7, 1);

    my @top2 = heap_peek_n($h, 2);
    is_deeply(\@top2, [7, 5], 'max-heap heap_peek_n(2)');
};

subtest 'functional heap_peek_n on empty' => sub {
    my $h = Heap::PQ::new('min');
    my @result = heap_peek_n($h, 5);
    is(scalar @result, 0, 'heap_peek_n on empty returns empty');
};

subtest 'functional heap_peek_n with nv heap' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (5.5, 1.1, 3.3, 2.2);

    my @top2 = heap_peek_n($h, 2);
    is_deeply(\@top2, [1.1, 2.2], 'heap_peek_n works with nv heap too');
    is($h->size, 4, 'nv heap unchanged');
};

# --- Heap::PQ::nv::peek_n functional style ---

subtest 'nv::peek_n functional style' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (5.5, 1.1, 3.3, 7.7, 2.2);

    my @top3 = Heap::PQ::nv::peek_n($h, 3);
    is_deeply(\@top3, [1.1, 2.2, 3.3], 'nv::peek_n returns top 3');
    is($h->size, 5, 'heap unchanged');
};

subtest 'nv::peek_n functional max-heap' => sub {
    my $h = Heap::PQ::new_nv('max');
    $h->push($_) for (5.5, 1.1, 3.3, 7.7, 2.2);

    my @top2 = Heap::PQ::nv::peek_n($h, 2);
    is_deeply(\@top2, [7.7, 5.5], 'nv::peek_n max-heap');
};

subtest 'nv::peek_n preserves heap for subsequent ops' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push($_) for (10, 5, 8, 3, 7);

    my @top = Heap::PQ::nv::peek_n($h, 3);
    is_deeply(\@top, [3, 5, 7], 'correct peek_n');

    is(Heap::PQ::nv::pop($h), 3, 'nv::pop still works');
    is(Heap::PQ::nv::pop($h), 5, 'nv::pop 2');
    is(Heap::PQ::nv::size($h), 3, 'size correct');
};

done_testing;
