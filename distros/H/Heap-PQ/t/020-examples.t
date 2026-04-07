#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Heap::PQ 'import';

# === Event scheduler: events processed in time order ===
subtest 'event scheduler ordering' => sub {
    my $scheduler = Heap::PQ::new('min', sub {
        $a->{time} <=> $b->{time}
    });

    heap_push($scheduler, { time => 1.0, action => 'start_server' });
    heap_push($scheduler, { time => 0.5, action => 'load_config' });
    heap_push($scheduler, { time => 2.0, action => 'open_connections' });
    heap_push($scheduler, { time => 1.5, action => 'warm_cache' });
    heap_push($scheduler, { time => 0.1, action => 'init_logging' });

    is(heap_size($scheduler), 5, 'all events queued');

    my @order;
    while (!heap_is_empty($scheduler)) {
        push @order, heap_pop($scheduler)->{action};
    }

    is_deeply(\@order, [
        'init_logging',
        'load_config',
        'start_server',
        'warm_cache',
        'open_connections',
    ], 'events processed in chronological order');
};

# === Leaderboard: max-heap with search and delete ===
subtest 'leaderboard pruning and ordering' => sub {
    my $board = Heap::PQ::new('max', sub {
        $a->{score} <=> $b->{score}
    });

    $board->push({ player => 'Alice', score => 4200 });
    $board->push({ player => 'Bob',   score => 3800 });
    $board->push({ player => 'Carol', score => 5100 });
    $board->push({ player => 'Dave',  score => 4700 });
    $board->push({ player => 'Eve',   score => 3200 });

    is($board->size, 5, 'five players on the board');
    is($board->peek->{player}, 'Carol', 'top of max-heap is Carol');

    # search for high scorers
    my @elite = $board->search(sub { $_->{score} >= 4500 });
    is(scalar @elite, 2, 'two elite players (>= 4500)');

    # delete players below 4000
    my $removed = $board->delete(sub { $_->{score} < 4000 });
    is($removed, 2, 'deleted 2 players below 4000');
    is($board->size, 3, '3 players remain');

    # remaining players should still come out in order
    my @remaining;
    while (!$board->is_empty) {
        push @remaining, $board->pop->{player};
    }
    is_deeply(\@remaining, ['Carol', 'Dave', 'Alice'],
        'remaining players in descending score order');
};

# === K-largest using raw array API ===
subtest 'k-largest via raw array' => sub {
    use Heap::PQ 'raw';

    my @stream = (42, 15, 88, 3, 67, 29, 95, 11, 54, 73);
    my $k = 3;
    my @heap;

    for my $n (@stream) {
        Heap::PQ::push_heap_min(\@heap, $n);
        if (@heap > $k) {
            Heap::PQ::pop_heap_min(\@heap);
        }
    }

    is(scalar @heap, $k, "heap holds exactly $k elements");

    my @largest;
    while (@heap) {
        push @largest, Heap::PQ::pop_heap_min(\@heap);
    }
    is_deeply(\@largest, [73, 88, 95], 'top 3 largest found');
};

# === NV heap for numeric data ===
subtest 'nv heap sorts doubles' => sub {
    my $h = Heap::PQ::new_nv('min');
    $h->push_all(3.14, 2.71, 1.41, 1.73, 2.23);

    is($h->size, 5, 'five values pushed');

    my @sorted;
    while (!$h->is_empty) {
        push @sorted, $h->pop;
    }

    # Compare as formatted strings to avoid float precision issues
    my @got = map { sprintf("%.2f", $_) } @sorted;
    is_deeply(\@got, ['1.41', '1.73', '2.23', '2.71', '3.14'],
        'NV heap pops in ascending order');
};

# === Search ===
subtest 'search finds matching elements' => sub {
    my $h = Heap::PQ::new('min');
    $h->push_all(1, 5, 10, 15, 20, 25);

    my @big = sort { $a <=> $b } $h->search(sub { $_ > 12 });
    is_deeply(\@big, [15, 20, 25], 'search returns elements > 12');
    is($h->size, 6, 'search did not mutate the heap');
};

# === Method chaining ===
subtest 'push chaining' => sub {
    my $h = Heap::PQ::new('min');
    $h->push(3)->push(1)->push(2);
    is($h->size, 3, 'chained 3 pushes');
    is($h->pop, 1, 'min is correct after chaining');
};

done_testing;
