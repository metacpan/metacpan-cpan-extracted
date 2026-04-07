#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Heap::PQ;

# Test heap module with various loop variable patterns

subtest 'for with $val push' => sub {
    my $h = Heap::PQ::new('min');
    for my $val (5, 3, 8, 1, 9) {
        $h->push($val);
    }
    is($h->size(), 5, 'heap push with $val');
};

subtest 'for with $n numeric' => sub {
    my $h = Heap::PQ::new('min');
    for my $n (10, 20, 5, 15, 25) {
        $h->push($n);
    }
    is($h->peek(), 5, 'min heap peek after $n push');
};

subtest 'while with $min extraction' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (5, 3, 8, 1, 9, 2);

    my @sorted;
    while (!$h->is_empty()) {
        my $min = $h->pop();
        push @sorted, $min;
    }
    is_deeply(\@sorted, [1, 2, 3, 5, 8, 9], 'extract mins with $min');
};

subtest 'for with $item' => sub {
    my $h = Heap::PQ::new('min', sub { $a <=> $b });
    my @items = (7, 2, 9, 4, 1);
    for my $item (@items) {
        $h->push($item);
    }
    is($h->peek(), 1, 'custom heap with $item');
};

subtest 'for with $x' => sub {
    my $h = Heap::PQ::new('min');
    for my $x (100, 50, 75, 25, 60) {
        $h->push($x);
    }

    my @top3;
    for my $i (1..3) {
        push @top3, $h->pop();
    }
    is_deeply(\@top3, [25, 50, 60], 'extract with $x');
};

subtest 'nested $outer/$inner' => sub {
    my @heaps;
    for my $outer (1..2) {
        my $h = Heap::PQ::new('min');
        for my $inner (1..3) {
            $h->push($outer * 10 + $inner);
        }
        push @heaps, $h;
    }

    is($heaps[0]->peek(), 11, 'nested heap 0 min');
    is($heaps[1]->peek(), 21, 'nested heap 1 min');
};

subtest 'for with $priority tuples' => sub {
    my $h = Heap::PQ::new('min', sub { $a->[0] <=> $b->[0] });
    my @tasks = (
        [3, 'low'],
        [1, 'high'],
        [2, 'medium'],
    );

    for my $priority (@tasks) {
        $h->push($priority);
    }

    my @order;
    while (!$h->is_empty()) {
        my $task = $h->pop();
        push @order, $task->[1];
    }
    is_deeply(\@order, ['high', 'medium', 'low'], 'priority queue with tuples');
};

subtest 'map with $_ to heap' => sub {
    my @values = (4, 2, 7, 1, 5);
    my $h = Heap::PQ::new('min');
    map { $h->push($_) } @values;
    is($h->size(), 5, 'heap from map with $_');
    is($h->peek(), 1, 'min from map values');
};

subtest 'for with $data hashref' => sub {
    my $h = Heap::PQ::new('min', sub { $a->{score} <=> $b->{score} });
    my @data = (
        { name => 'c', score => 75 },
        { name => 'a', score => 90 },
        { name => 'b', score => 60 },
    );

    for my $data (@data) {
        $h->push($data);
    }

    is($h->pop()->{name}, 'b', 'lowest score first');
    is($h->pop()->{name}, 'c', 'second lowest');
};

subtest 'while with $top' => sub {
    my $h = Heap::PQ::new('min');
    $h->push($_) for (5, 10, 15, 20, 25);

    my @result;
    while (!$h->is_empty()) {
        my $top = $h->pop();
        push @result, $top if $top < 20;
    }
    is_deeply(\@result, [5, 10, 15], 'conditional extract with $top');
};

done_testing();
