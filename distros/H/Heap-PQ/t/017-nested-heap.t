#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Heap::PQ;

subtest 'heap of heaps - priority queue of priority queues' => sub {
    # Outer heap orders inner heaps by their minimum element
    my $outer = Heap::PQ::new('min', sub {
        $a->peek <=> $b->peek;
    });

    # Create inner heaps with different ranges
    my $h1 = Heap::PQ::new('min');
    $h1->push(10);
    $h1->push(20);
    $h1->push(30);

    my $h2 = Heap::PQ::new('min');
    $h2->push(1);
    $h2->push(2);
    $h2->push(3);

    my $h3 = Heap::PQ::new('min');
    $h3->push(5);
    $h3->push(15);
    $h3->push(25);

    $outer->push($h1);
    $outer->push($h2);
    $outer->push($h3);

    is($outer->size, 3, 'outer heap has 3 inner heaps');

    # Pop returns heap with smallest min
    my $first = $outer->pop;
    is($first->peek, 1, 'first popped heap has min 1');
    is($first->size, 3, 'first popped heap has 3 elements');

    my $second = $outer->pop;
    is($second->peek, 5, 'second popped heap has min 5');

    my $third = $outer->pop;
    is($third->peek, 10, 'third popped heap has min 10');

    # Inner heaps are still fully functional
    is($first->pop, 1, 'inner heap pop 1');
    is($first->pop, 2, 'inner heap pop 2');
    is($first->pop, 3, 'inner heap pop 3');
};

subtest 'heap storing heaps as values with numeric priority' => sub {
    # Outer heap uses default numeric comparison
    # Inner heaps are just stored as opaque values
    my $outer = Heap::PQ::new('min');

    my $h1 = Heap::PQ::new('min');
    $h1->push(100);

    my $h2 = Heap::PQ::new('max');
    $h2->push(200);

    # Push with numeric priorities
    $outer->push($h1);    # priority based on refaddr
    $outer->push($h2);

    is($outer->size, 2, 'outer has 2 heaps');

    # We get them back and they still work
    my $got_a = $outer->pop;
    my $got_b = $outer->pop;

    # One of them is h1, the other h2
    my @peeks = sort { $a <=> $b } ($got_a->peek, $got_b->peek);
    is_deeply(\@peeks, [100, 200], 'both inner heaps intact after pop');
};

subtest 'nv heap inside OO heap' => sub {
    my $outer = Heap::PQ::new('min', sub {
        Heap::PQ::nv::peek($a) <=> Heap::PQ::nv::peek($b);
    });

    my $nv1 = Heap::PQ::new_nv('min');
    $nv1->push(50.5);
    $nv1->push(10.1);

    my $nv2 = Heap::PQ::new_nv('min');
    $nv2->push(3.3);
    $nv2->push(7.7);

    $outer->push($nv1);
    $outer->push($nv2);

    my $first = $outer->pop;
    is($first->peek, 3.3, 'nv heap with smallest min popped first');

    my $second = $outer->pop;
    is($second->peek, 10.1, 'nv heap with larger min popped second');

    # Inner nv heaps still work
    is($first->pop, 3.3, 'inner nv pop 1');
    is($first->pop, 7.7, 'inner nv pop 2');
};

subtest 'deeply nested heaps' => sub {
    # 3 levels deep
    my $inner = Heap::PQ::new('min');
    $inner->push(42);

    my $middle = Heap::PQ::new('min', sub { $a->peek <=> $b->peek });
    $middle->push($inner);

    my $outer = Heap::PQ::new('min', sub { $a->peek->peek <=> $b->peek->peek });
    $outer->push($middle);

    my $got_middle = $outer->pop;
    my $got_inner = $got_middle->pop;
    is($got_inner->pop, 42, 'value survives 3 levels of nesting');
};

subtest 'heap of heaps - modify inner after insertion' => sub {
    my $outer = Heap::PQ::new('min', sub {
        $a->peek <=> $b->peek;
    });

    my $h1 = Heap::PQ::new('min');
    $h1->push(10);

    my $h2 = Heap::PQ::new('min');
    $h2->push(20);

    $outer->push($h1);
    $outer->push($h2);

    # Peek should be h1 (min=10)
    is($outer->peek->peek, 10, 'peek is heap with min 10');

    # Inner heaps are references - popping from them changes their state
    # But outer heap ordering is fixed at push time
    is($outer->size, 2, 'outer still has 2 elements');
};

subtest 'heap goes out of scope with nested heaps' => sub {
    my $survived = 0;
    {
        my $outer = Heap::PQ::new('min', sub { $a->peek <=> $b->peek });

        for my $i (1..5) {
            my $inner = Heap::PQ::new('min');
            $inner->push($i * 10);
            $inner->push($i * 10 + 5);
            $outer->push($inner);
        }
        # outer and all inner heaps go out of scope
    }
    $survived = 1;
    ok($survived, 'nested heaps destroyed without crash');
};

done_testing;
