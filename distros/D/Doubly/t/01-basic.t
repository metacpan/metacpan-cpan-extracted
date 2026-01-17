#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Check if threads are available
BEGIN {
    eval {
        require threads;
        require threads::shared;
    };
    if ($@) {
        plan skip_all => 'threads not available';
    }
}

use threads;
use threads::shared;
use_ok('Doubly');

# Test 1: Basic operations
subtest 'basic operations' => sub {
    plan tests => 6;
    
    my $list = Doubly->new();
    ok($list, 'created list');
    is($list->length, 0, 'empty list has length 0');
    
    $list->add(1);
    is($list->length, 1, 'length is 1 after add');
  
    $list->add(2);
    $list->add(3);
    is($list->length, 3, 'length is 3 after adding more');
    
    $list->start;
    is($list->data, 1, 'data at start is 1');
    
    $list->end;
    is($list->data, 3, 'data at end is 3');
    
    $list->destroy;
};

# Test 2: Navigation
subtest 'navigation' => sub {
    plan tests => 6;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3, 4, 5);
    
    $list->start;
    ok($list->is_start, 'at start');
    ok(!$list->is_end, 'not at end');
    
    $list->end;
    ok($list->is_end, 'at end');
    ok(!$list->is_start, 'not at start');
    
    $list->prev;
    is($list->data, 4, 'prev from end gives 4');
    
    $list->next;
    is($list->data, 5, 'next gives 5');
    
    $list->destroy;
};

# Test 3: Remove operations
subtest 'remove operations' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3, 4, 5);
    
    my $val = $list->remove_from_start;
    is($val, 1, 'removed 1 from start');
    is($list->length, 4, 'length is 4');
    
    $val = $list->remove_from_end;
    is($val, 5, 'removed 5 from end');
    is($list->length, 3, 'length is 3');
    
    $list->destroy;
};

# Test 4: Thread safety - concurrent adds
subtest 'thread safety - concurrent adds' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    
    my @threads;
    for my $t (1..4) {
        push @threads, threads->create(sub {
            my $tid = shift;
            for my $i (1..25) {
                $list->add("t${tid}_$i");
            }
            return 1;
        }, $t);
    }
    
    $_->join for @threads;
    
    is($list->length, 100, '100 items added by 4 threads');
    
    $list->destroy;
};

# Test 5: Thread safety - concurrent removes
subtest 'thread safety - concurrent removes' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    $list->bulk_add(1..100);
    
    my @threads;
    for my $t (1..4) {
        push @threads, threads->create(sub {
            for my $i (1..25) {
                eval { $list->remove_from_start };
            }
            return 1;
        });
    }
    
    $_->join for @threads;
    
    is($list->length, 0, 'all items removed');
    
    $list->destroy;
};

# Test 6: Rapid create/destroy
subtest 'rapid create and destroy' => sub {
    plan tests => 1;
    
    my $ok = 1;
    for my $i (1..100) {
        my $list = Doubly->new();
        $list->bulk_add(1..10);
        $list->destroy;
    }
    
    ok($ok, 'rapid create/destroy completed');
};

# Test 7: Thread creates and uses its own list
subtest 'thread local lists' => sub {
    plan tests => 1;
    
    my @threads;
    for my $t (1..4) {
        push @threads, threads->create(sub {
            my $list = Doubly->new();
            $list->bulk_add(1..100);
            my $len = $list->length;
            $list->destroy;
            return $len;
        });
    }
    
    my @results = map { $_->join } @threads;
    is_deeply(\@results, [100, 100, 100, 100], 'each thread got 100 items');
};

# Test 8: Mixed operations
subtest 'mixed concurrent operations' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    $list->bulk_add(1..50);
    
    my @threads;
    
    # Adder threads
    for my $t (1..2) {
        push @threads, threads->create(sub {
            for my $i (1..25) {
                $list->add("added_$i");
            }
            return 1;
        });
    }
    
    # Remover threads
    for my $t (1..2) {
        push @threads, threads->create(sub {
            for my $i (1..25) {
                eval { $list->remove_from_start };
            }
            return 1;
        });
    }
    
    $_->join for @threads;
    
    # Should have 50 + 50 - 50 = 50 items
    is($list->length, 50, 'mixed operations result in 50 items');
    
    $list->destroy;
};

done_testing();
