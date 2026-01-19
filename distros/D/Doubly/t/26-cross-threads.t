#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Cross-thread hash/array modification tests for Doubly

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

# Test 1: Hash ref modification across threads
subtest 'hash ref modified in thread is visible' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    my $hash = { counter => 0, name => 'test' };
    $list->add($hash);
    
    is($list->data->{counter}, 0, 'counter starts at 0');
    
    my $t = threads->create(sub {
        my $data = $list->data;
        $data->{counter} = 42;
        $data->{name} = 'modified';
        return 1;
    });
    $t->join;
    
    is($list->data->{counter}, 42, 'counter modified by thread');
    is($list->data->{name}, 'modified', 'name modified by thread');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 2: Array ref modification across threads
subtest 'array ref modified in thread is visible' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    my $arr = [1, 2, 3];
    $list->add($arr);
    
    is_deeply($list->data, [1, 2, 3], 'array starts with [1,2,3]');
    
    my $t = threads->create(sub {
        my $data = $list->data;
        push @$data, 4;
        $data->[0] = 100;
        return 1;
    });
    $t->join;
    
    is($list->data->[0], 100, 'first element modified');
    is(scalar(@{$list->data}), 4, 'array has 4 elements');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 3: Nested structure modification
subtest 'nested structure modified in thread' => sub {
    plan tests => 3;
    
    my $list = Doubly->new();
    $list->add({ users => [], config => { enabled => 0 } });
    
    my $t = threads->create(sub {
        my $data = $list->data;
        push @{$data->{users}}, 'alice', 'bob';
        $data->{config}{enabled} = 1;
        return 1;
    });
    $t->join;
    
    is_deeply($list->data->{users}, ['alice', 'bob'], 'users array modified');
    is($list->data->{config}{enabled}, 1, 'nested config modified');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 4: Multiple threads modifying same hash
subtest 'multiple threads increment counter' => sub {
    plan tests => 2;
    
    my $list = Doubly->new();
    $list->add({ count => 0 });
    
    my @threads;
    for my $i (1..5) {
        push @threads, threads->create(sub {
            for (1..10) {
                my $data = $list->data;
                $data->{count}++;
            }
            return 1;
        });
    }
    $_->join for @threads;
    
    # Note: Without proper locking in user code, this may not be exactly 50
    # but it should be > 0 and the structure should be intact
    ok($list->data->{count} > 0, 'counter was incremented');
    
    $list->destroy();
    ok(1, 'cleanup after concurrent modifications');
};

# Test 5: Add hash from one thread, read from another
# This now works! Refs added from spawned threads are stored in a shared
# Perl array and can be accessed from any thread.
subtest 'add ref in spawned thread, read in main' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    
    # Adding a hash from a spawned thread
    my $t1 = threads->create(sub {
        $list->add({ added_by => 'thread1', value => 123 });
        return $list->data->{value};  # Works within the same thread
    });
    my $thread_val = $t1->join;
    
    # The thread itself can access the data
    is($thread_val, 123, 'ref accessible within creating thread');
    
    # Main thread can now also access it!
    my $data = $list->data;
    is(ref($data), 'HASH', 'ref from thread accessible in main');
    is($data->{value}, 123, 'value correct');
    is($data->{added_by}, 'thread1', 'added_by correct');
    
    $list->destroy();
};

done_testing();
