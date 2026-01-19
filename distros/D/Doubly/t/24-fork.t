#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Fork tests for Doubly module
# Forks don't share memory, so each process gets its own copy

BEGIN {
    if ($^O eq 'MSWin32') {
        plan skip_all => 'fork not available on Windows';
    }
}

use_ok('Doubly');

# Test 1: Basic fork - child process gets copy of list
subtest 'Fork - child gets copy of list' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    $list->add(1);
    $list->add(2);
    $list->add(3);
    
    is($list->length, 3, 'parent has 3 items before fork');
    
    my $pid = fork();
    
    if ($pid == 0) {
        # Child process
        # Should have a copy of the list
        if ($list->length == 3) {
            $list->add(4);
            $list->add(5);
            exit($list->length == 5 ? 0 : 1);
        }
        exit(1);
    } else {
        # Parent process
        waitpid($pid, 0);
        my $child_status = $? >> 8;
        
        is($child_status, 0, 'child completed successfully');
        is($list->length, 3, 'parent still has 3 items (not affected by child)');
        
        # Parent can still modify its own list
        $list->add(10);
        is($list->length, 4, 'parent can add to its list');
    }
};

# Test 2: Multiple forks
subtest 'Multiple forks' => sub {
    plan tests => 3;
    
    my $list = Doubly->new();
    $list->add("parent_item");
    
    my @pids;
    for my $i (1..4) {
        my $pid = fork();
        if ($pid == 0) {
            # Child process
            $list->add("child_${i}_item");
            exit($list->length == 2 ? 0 : 1);
        }
        push @pids, $pid;
    }
    
    # Wait for all children
    my $all_ok = 1;
    for my $pid (@pids) {
        waitpid($pid, 0);
        $all_ok = 0 if ($? >> 8) != 0;
    }
    
    ok($all_ok, 'all children completed successfully');
    is($list->length, 1, 'parent still has only 1 item');
    
    # Add more in parent
    $list->add("parent_item_2");
    $list->add("parent_item_3");
    is($list->length, 3, 'parent can continue adding');
};

# Test 3: Fork after complex operations
subtest 'Fork after complex operations' => sub {
    plan tests => 3;
    
    my $list = Doubly->new(100);
    
    # Do some operations
    for my $i (1..10) {
        $list->add($i);
    }
    $list->remove_from_start;
    $list->remove_from_end;
    
    is($list->length, 9, 'list has 9 items');
    
    my $pid = fork();
    
    if ($pid == 0) {
        # Child - verify copy is intact
        my $len = $list->length;
        
        # Do more operations in child
        $list->add(999);
        $list->remove_from_start;
        
        exit($list->length == 9 ? 0 : 1);
    } else {
        waitpid($pid, 0);
        my $status = $? >> 8;
        
        is($status, 0, 'child operations succeeded');
        is($list->length, 9, 'parent list unchanged');
    }
};

# Test 4: Destroy in child doesn't affect parent
subtest 'Destroy in child is independent' => sub {
    plan tests => 3;
    
    my $list = Doubly->new();
    $list->add(1);
    $list->add(2);
    $list->add(3);
    
    my $pid = fork();
    
    if ($pid == 0) {
        # Child destroys its copy
        $list->destroy;
        exit(0);
    } else {
        waitpid($pid, 0);
        my $status = $? >> 8;
        
        is($status, 0, 'child completed');
        is($list->length, 3, 'parent list still has 3 items');
        
        $list->start;
        is($list->data, 1, 'parent data still accessible');
    }
};

# Test 6: Heavy fork stress test
subtest 'Fork stress test' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    for my $i (1..50) {
        $list->add($i);
    }
    
    my @pids;
    for my $round (1..10) {
        my $pid = fork();
        if ($pid == 0) {
            # Child does some work
            for my $j (1..10) {
                $list->add($j + 100);
                $list->remove_from_start;
            }
            exit(0);
        }
        push @pids, $pid;
    }
    
    # Wait for all
    for my $pid (@pids) {
        waitpid($pid, 0);
    }
    
    # Parent should be unaffected
    is($list->length, 50, 'parent list unchanged after fork stress');
};

done_testing();
