#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Fork tests for Doubly module
# Note: Forks DON'T share memory like threads do.
# Each forked process gets a copy of the list registry.
# Doubly uses process-global storage, so forks are independent.

BEGIN {
    if ($^O eq 'MSWin32') {
        plan skip_all => 'fork not available on Windows';
    }
}

use_ok('Doubly');

# Test 1: Basic fork - child process gets copy
subtest 'Fork - child gets independent copy' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    $list->add(1);
    $list->add(2);
    $list->add(3);
    
    is($list->length, 3, 'parent has 3 items before fork');
    
    my $pid = fork();
    
    if ($pid == 0) {
        # Child process gets a copy of the global registry
        # Modifications here don't affect parent
        if ($list->length == 3) {
            $list->add(4);
            $list->add(5);
            exit($list->length == 5 ? 0 : 1);
        }
        exit(1);
    } else {
        waitpid($pid, 0);
        my $child_status = $? >> 8;
        
        is($child_status, 0, 'child completed successfully');
        is($list->length, 3, 'parent still has 3 items');
        
        $list->add(10);
        is($list->length, 4, 'parent can add to its list');
    }
};

# Test 2: Multiple forks - each gets independent copy
subtest 'Multiple forks - independent copies' => sub {
    plan tests => 3;
    
    my $list = Doubly->new();
    $list->add("parent_item");
    
    my @pids;
    for my $i (1..4) {
        my $pid = fork();
        if ($pid == 0) {
            # Child adds to its own copy
            $list->add("child_${i}_item");
            # Each child should see 2 items
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
    
    $list->add("parent_2");
    is($list->length, 2, 'parent can continue adding');
};

# Test 3: Fork after operations
subtest 'Fork after complex operations' => sub {
    plan tests => 3;
    
    my $list = Doubly->new(100);
    
    for my $i (1..10) {
        $list->add($i);
    }
    $list->remove_from_start;
    $list->remove_from_end;
    
    is($list->length, 9, 'list has 9 items');
    
    my $pid = fork();
    
    if ($pid == 0) {
        my $len = $list->length;
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

# Test 4: Navigation preserved across fork
subtest 'Fork preserves navigation' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    $list->add(1);
    $list->add(2);
    $list->add(3);
    $list->add(4);
    $list->add(5);
    
    $list->start->next->next;
    is($list->data, 3, 'parent at position 3');
    
    my $pid = fork();
    
    if ($pid == 0) {
        my $data = $list->data;
        exit($data == 3 ? 0 : 1);
    } else {
        waitpid($pid, 0);
        my $status = $? >> 8;
        
        is($status, 0, 'child saw position 3');
        is($list->data, 3, 'parent still at position 3');
        
        $list->end;
        is($list->data, 5, 'parent navigated to end');
    }
};

# Test 5: Destroy in child independent
subtest 'Destroy in child is independent' => sub {
    plan tests => 3;
    
    my $list = Doubly->new();
    $list->add(1);
    $list->add(2);
    $list->add(3);
    
    my $pid = fork();
    
    if ($pid == 0) {
        $list->destroy;
        exit(0);
    } else {
        waitpid($pid, 0);
        my $status = $? >> 8;
        
        is($status, 0, 'child completed');
        is($list->length, 3, 'parent list still has 3 items');
        
        $list->start;
        is($list->data, 1, 'parent data accessible');
    }
};

# Test 6: Create new list in child
subtest 'Create new list in child' => sub {
    plan tests => 2;
    
    my $parent_list = Doubly->new();
    $parent_list->add("parent");
    
    my $pid = fork();
    
    if ($pid == 0) {
        # Child creates its own list
        my $child_list = Doubly->new();
        $child_list->add("child1");
        $child_list->add("child2");
        
        # Parent's list is a copy
        exit($parent_list->length == 1 && $child_list->length == 2 ? 0 : 1);
    } else {
        waitpid($pid, 0);
        my $status = $? >> 8;
        
        is($status, 0, 'child created separate list');
        is($parent_list->length, 1, 'parent list unchanged');
    }
};

# Test 7: Fork stress test
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
            for my $j (1..10) {
                $list->add($j + 100);
                $list->remove_from_start;
            }
            exit(0);
        }
        push @pids, $pid;
    }
    
    for my $pid (@pids) {
        waitpid($pid, 0);
    }
    
    is($list->length, 50, 'parent list unchanged after fork stress');
};

# Test 8: Fork with bulk_add
subtest 'Fork with bulk_add' => sub {
    plan tests => 3;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3, 4, 5);
    
    is($list->length, 5, 'parent has 5 items');
    
    my $pid = fork();
    
    if ($pid == 0) {
        $list->bulk_add(6, 7, 8, 9, 10);
        exit($list->length == 10 ? 0 : 1);
    } else {
        waitpid($pid, 0);
        my $status = $? >> 8;
        
        is($status, 0, 'child bulk_add succeeded');
        is($list->length, 5, 'parent unchanged');
    }
};

done_testing();
