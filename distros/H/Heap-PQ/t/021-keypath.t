#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Heap::PQ;

subtest 'single key - min heap' => sub {
    my $h = Heap::PQ::new('min', 'priority');

    $h->push({ name => 'low',    priority => 10 });
    $h->push({ name => 'high',   priority => 1  });
    $h->push({ name => 'medium', priority => 5  });

    is($h->pop->{name}, 'high',   'highest priority first');
    is($h->pop->{name}, 'medium', 'medium second');
    is($h->pop->{name}, 'low',    'low third');
};

subtest 'single key - max heap' => sub {
    my $h = Heap::PQ::new('max', 'score');

    $h->push({ player => 'Alice', score => 100 });
    $h->push({ player => 'Bob',   score => 250 });
    $h->push({ player => 'Carol', score => 175 });

    is($h->pop->{player}, 'Bob',   'Bob highest');
    is($h->pop->{player}, 'Carol', 'Carol second');
    is($h->pop->{player}, 'Alice', 'Alice third');
};

subtest 'nested key path' => sub {
    my $h = Heap::PQ::new('min', 'meta.score');

    $h->push({ name => 'c', meta => { score => 30 } });
    $h->push({ name => 'a', meta => { score => 10 } });
    $h->push({ name => 'b', meta => { score => 20 } });

    is($h->pop->{name}, 'a', 'nested: first correct');
    is($h->pop->{name}, 'b', 'nested: second correct');
    is($h->pop->{name}, 'c', 'nested: third correct');
};

subtest 'deeply nested key path' => sub {
    my $h = Heap::PQ::new('min', 'a.b.c');

    $h->push({ a => { b => { c => 99 } } });
    $h->push({ a => { b => { c => 1  } } });
    $h->push({ a => { b => { c => 50 } } });

    is($h->pop->{a}{b}{c}, 1,  'deep: first');
    is($h->pop->{a}{b}{c}, 50, 'deep: second');
    is($h->pop->{a}{b}{c}, 99, 'deep: third');
};

subtest 'key path with push_all' => sub {
    my $h = Heap::PQ::new('min', 'due');

    $h->push_all(
        { task => 'Write tests',  due => 3 },
        { task => 'Ship release', due => 5 },
        { task => 'Fix bug',      due => 1 },
    );

    my @order;
    while (!$h->is_empty) {
        push @order, $h->pop->{task};
    }
    is_deeply(\@order, ['Fix bug', 'Write tests', 'Ship release'], 'push_all with key path');
};

subtest 'key path at scale' => sub {
    my $h = Heap::PQ::new('min', 'pri');

    for my $i (1..100) {
        $h->push({ pri => int(rand(1000)), val => "item_$i" });
    }

    my @pris;
    while (!$h->is_empty) {
        push @pris, $h->pop->{pri};
    }

    my @sorted = sort { $a <=> $b } @pris;
    is_deeply(\@pris, \@sorted, 'key path heap property at scale');
};

subtest 'key path with floats' => sub {
    my $h = Heap::PQ::new('min', 'time');

    $h->push({ action => 'start',  time => 1.5 });
    $h->push({ action => 'config', time => 0.5 });
    $h->push({ action => 'end',    time => 2.0 });

    is($h->pop->{action}, 'config', 'float: first');
    is($h->pop->{action}, 'start',  'float: second');
    is($h->pop->{action}, 'end',    'float: third');
};

subtest 'key path chained push' => sub {
    my $h = Heap::PQ::new('min', 'v');
    $h->push({ v => 3 })->push({ v => 1 })->push({ v => 2 });

    is($h->pop->{v}, 1, 'chained push: first');
    is($h->pop->{v}, 2, 'chained push: second');
    is($h->pop->{v}, 3, 'chained push: third');
};

subtest 'key path with search and delete' => sub {
    my $h = Heap::PQ::new('min', 'pri');

    $h->push({ name => 'a', pri => 1 });
    $h->push({ name => 'b', pri => 5 });
    $h->push({ name => 'c', pri => 3 });
    $h->push({ name => 'd', pri => 2 });

    my @found = $h->search(sub { $_->{pri} > 3 });
    is(scalar @found, 1, 'search found 1');
    is($found[0]->{name}, 'b', 'search found bob');

    my $removed = $h->delete(sub { $_->{pri} > 3 });
    is($removed, 1, 'deleted 1');
    is($h->size, 3, '3 remain');

    is($h->pop->{name}, 'a', 'after delete: a first');
};

subtest 'key path with functional ops' => sub {
    use Heap::PQ 'import';

    my $h = Heap::PQ::new('min', 'pri');

    heap_push($h, { name => 'x', pri => 10 });
    heap_push($h, { name => 'y', pri => 1 });

    is(heap_size($h), 2, 'functional size with key path');
    is(heap_pop($h)->{name}, 'y', 'functional pop with key path');
};

done_testing;
