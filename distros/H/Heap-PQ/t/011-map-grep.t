#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Test Heap::PQ functions work correctly in map/grep context
# This ensures call checkers properly handle $_ usage

use Heap::PQ;

# ============================================
# Heap::PQ->size in map
# ============================================
subtest 'Heap::PQ->size in map' => sub {
    my $h1 = Heap::PQ::new('min');
    my $h2 = Heap::PQ::new('min');
    my $h3 = Heap::PQ::new('min');
    
    $h1->push($_) for 1..3;
    $h2->push($_) for 1..5;
    $h3->push($_) for 1..2;
    
    my @heaps = ($h1, $h2, $h3);
    my @sizes = map { $_->size } @heaps;
    is_deeply(\@sizes, [3, 5, 2], 'size returns correct values in map');
};

# ============================================
# Heap::PQ->peek in map
# ============================================
subtest 'Heap::PQ->peek in map' => sub {
    my $h1 = Heap::PQ::new('min'); $h1->push(100); $h1->push(50); $h1->push(75);
    my $h2 = Heap::PQ::new('min'); $h2->push(200); $h2->push(300);
    my $h3 = Heap::PQ::new('min'); $h3->push(10);
    
    my @heaps = ($h1, $h2, $h3);
    my @mins = map { $_->peek } @heaps;
    
    # Min-heap: peek should return smallest
    is($mins[0], 50, 'first heap min is 50');
    is($mins[1], 200, 'second heap min is 200');
    is($mins[2], 10, 'third heap min is 10');
};

# ============================================
# Filter heaps by size in grep
# ============================================
subtest 'filter heaps by size in grep' => sub {
    my @heaps;
    for my $size (1, 5, 3, 7, 2) {
        my $h = Heap::PQ::new('min');
        $h->push($_) for 1..$size;
        push @heaps, $h;
    }
    
    my @large_heaps = grep { $_->size >= 5 } @heaps;
    is(scalar(@large_heaps), 2, 'grep finds 2 heaps with size >= 5');
};

# ============================================
# Heap::PQ->pop in map (destructive)
# ============================================
subtest 'Heap::PQ->pop in map' => sub {
    my $h1 = Heap::PQ::new('min'); $h1->push(10); $h1->push(5);
    my $h2 = Heap::PQ::new('min'); $h2->push(20); $h2->push(15);
    
    my @heaps = ($h1, $h2);
    my @popped = map { $_->pop } @heaps;
    
    is($popped[0], 5, 'first heap popped 5');
    is($popped[1], 15, 'second heap popped 15');
    is($h1->size, 1, 'first heap now has 1 element');
    is($h2->size, 1, 'second heap now has 1 element');
};

# ============================================
# Nested map with heaps
# ============================================
subtest 'nested map with heaps' => sub {
    my @heap_groups;
    for my $group_num (1, 2) {
        my @group;
        for my $i (1..2) {
            my $h = Heap::PQ::new('min');
            $h->push($group_num * 10 + $i);
            push @group, $h;
        }
        push @heap_groups, \@group;
    }
    
    my @sizes = map {
        my $group = $_;
        [ map { $_->size } @$group ]
    } @heap_groups;
    
    is_deeply($sizes[0], [1, 1], 'first group sizes correct');
    is_deeply($sizes[1], [1, 1], 'second group sizes correct');
};

done_testing();
