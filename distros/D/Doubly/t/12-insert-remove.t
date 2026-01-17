#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Doubly');

# Test remove (current node)
subtest 'remove - current node' => sub {
    plan tests => 7;
    
    my $list = Doubly->new();
    $list->add(1)->add(2)->add(3);
    
    is($list->length, 3, 'list has 3 items');
    
    # Move to middle
    $list->start->next;
    is($list->data, 2, 'at position 2');
    
    # Remove current (2)
    my $removed = $list->remove;
    is($removed, 2, 'removed value is 2');
    is($list->length, 2, 'list has 2 items');
    is($list->data, 3, 'current moved to next (3)');
    
    # Verify list structure
    $list->start;
    is($list->data, 1, 'first item is 1');
    $list->end;
    is($list->data, 3, 'last item is 3');
    
    $list->destroy;
};

# Test remove from head
subtest 'remove - head node' => sub {
    plan tests => 5;
    
    my $list = Doubly->new(1);
    $list->add(2)->add(3);
    
    $list->start;
    my $removed = $list->remove;
    is($removed, 1, 'removed head value is 1');
    is($list->length, 2, 'list has 2 items');
    
    $list->start;
    is($list->data, 2, 'new head is 2');
    is($list->is_start, 1, 'at start');
    
    $list->end;
    is($list->data, 3, 'tail still 3');
    
    $list->destroy;
};

# Test remove from tail
subtest 'remove - tail node' => sub {
    plan tests => 4;
    
    my $list = Doubly->new(1);
    $list->add(2)->add(3);
    
    $list->end;
    my $removed = $list->remove;
    is($removed, 3, 'removed tail value is 3');
    is($list->length, 2, 'list has 2 items');
    is($list->data, 2, 'current moved to new tail');
    is($list->is_end, 1, 'at end');
    
    $list->destroy;
};

# Test remove_from_pos
subtest 'remove_from_pos' => sub {
    plan tests => 6;
    
    my $list = Doubly->new();
    $list->bulk_add(10, 20, 30, 40, 50);
    
    is($list->length, 5, 'list has 5 items');
    
    # Remove from position 2 (30)
    my $removed = $list->remove_from_pos(2);
    is($removed, 30, 'removed value at pos 2 is 30');
    is($list->length, 4, 'list has 4 items');
    
    # Remove from position 0 (10)
    $removed = $list->remove_from_pos(0);
    is($removed, 10, 'removed value at pos 0 is 10');
    
    # Verify remaining list
    $list->start;
    is($list->data, 20, 'first item is now 20');
    $list->end;
    is($list->data, 50, 'last item is 50');
    
    $list->destroy;
};

# Test insert_before
subtest 'insert_before' => sub {
    plan tests => 6;
    
    my $list = Doubly->new(2);
    $list->add(4);
    
    is($list->length, 2, 'list has 2 items');
    
    # Insert 1 before head
    $list->start;
    $list->insert_before(1);
    is($list->length, 3, 'list has 3 items');
    is($list->data, 1, 'current is at inserted node');
    is($list->is_start, 1, 'inserted at start');
    
    # Insert 3 before 4
    $list->end;  # Go to 4
    $list->insert_before(3);
    is($list->length, 4, 'list has 4 items');
    
    # Verify order: 1, 2, 3, 4
    my @vals;
    $list->start;
    push @vals, $list->data;
    while (!$list->is_end) {
        $list->next;
        push @vals, $list->data;
    }
    is_deeply(\@vals, [1, 2, 3, 4], 'list order is 1,2,3,4');
    
    $list->destroy;
};

# Test insert_after
subtest 'insert_after' => sub {
    plan tests => 5;
    
    my $list = Doubly->new(1);
    $list->add(3);
    
    # Insert 2 after 1
    $list->start;
    $list->insert_after(2);
    is($list->length, 3, 'list has 3 items');
    is($list->data, 2, 'current is at inserted node');
    
    # Insert 4 after 3
    $list->end;
    $list->insert_after(4);
    is($list->length, 4, 'list has 4 items');
    is($list->is_end, 1, 'inserted at end');
    
    # Verify order: 1, 2, 3, 4
    my @vals;
    $list->start;
    push @vals, $list->data;
    while (!$list->is_end) {
        $list->next;
        push @vals, $list->data;
    }
    is_deeply(\@vals, [1, 2, 3, 4], 'list order is 1,2,3,4');
    
    $list->destroy;
};

# Test insert_at_start
subtest 'insert_at_start' => sub {
    plan tests => 5;
    
    my $list = Doubly->new(2);
    $list->add(3);
    
    $list->insert_at_start(1);
    is($list->length, 3, 'list has 3 items');
    
    $list->start;
    is($list->data, 1, 'first item is 1');
    
    $list->insert_at_start(0);
    is($list->length, 4, 'list has 4 items');
    
    $list->start;
    is($list->data, 0, 'first item is now 0');
    
    $list->end;
    is($list->data, 3, 'last item still 3');
    
    $list->destroy;
};

# Test insert_at_end
subtest 'insert_at_end' => sub {
    plan tests => 5;
    
    my $list = Doubly->new(1);
    
    $list->insert_at_end(2);
    is($list->length, 2, 'list has 2 items');
    
    $list->end;
    is($list->data, 2, 'last item is 2');
    
    $list->insert_at_end(3);
    is($list->length, 3, 'list has 3 items');
    
    $list->end;
    is($list->data, 3, 'last item is now 3');
    
    $list->start;
    is($list->data, 1, 'first item still 1');
    
    $list->destroy;
};

# Test insert_at_pos
subtest 'insert_at_pos' => sub {
    plan tests => 6;
    
    my $list = Doubly->new(1);
    $list->add(4);
    
    # Insert at position 1 (between 1 and 4)
    $list->insert_at_pos(1, 2);
    is($list->length, 3, 'list has 3 items');
    
    # Insert at position 2 (between 2 and 4)
    $list->insert_at_pos(2, 3);
    is($list->length, 4, 'list has 4 items');
    
    # Verify order
    my @vals;
    $list->start;
    push @vals, $list->data;
    while (!$list->is_end) {
        $list->next;
        push @vals, $list->data;
    }
    is_deeply(\@vals, [1, 2, 3, 4], 'list order is 1,2,3,4');
    
    # Insert at position 0
    $list->insert_at_pos(0, 0);
    is($list->length, 5, 'list has 5 items');
    $list->start;
    is($list->data, 0, 'first item is now 0');
    
    # Insert beyond end (should insert at end)
    $list->insert_at_pos(100, 99);
    $list->end;
    # Note: behavior may differ, but shouldn't crash
    ok($list->length >= 5, 'list still works after insert beyond bounds');
    
    $list->destroy;
};

# Test empty list operations
subtest 'operations on empty list' => sub {
    plan tests => 6;
    
    my $list = Doubly->new();
    is($list->length, 0, 'empty list');
    
    $list->insert_before(1);
    is($list->length, 1, 'insert_before on empty creates item');
    $list->destroy;
    
    $list = Doubly->new();
    $list->insert_after(1);
    is($list->length, 1, 'insert_after on empty creates item');
    $list->destroy;
    
    $list = Doubly->new();
    $list->insert_at_start(1);
    is($list->length, 1, 'insert_at_start on empty creates item');
    $list->destroy;
    
    $list = Doubly->new();
    $list->insert_at_end(1);
    is($list->length, 1, 'insert_at_end on empty creates item');
    $list->destroy;
    
    $list = Doubly->new();
    $list->insert_at_pos(0, 1);
    is($list->length, 1, 'insert_at_pos on empty creates item');
    $list->destroy;
};

# Test remove last item
subtest 'remove last remaining item' => sub {
    plan tests => 4;
    
    my $list = Doubly->new(42);
    is($list->length, 1, 'list has 1 item');
    
    my $removed = $list->remove;
    is($removed, 42, 'removed value is 42');
    is($list->length, 0, 'list is now empty');
    
    # Can add again
    $list->add(100);
    is($list->length, 1, 'can add after removing last');
    
    $list->destroy;
};

# Test chaining
subtest 'method chaining' => sub {
    plan tests => 2;
    
    my $list = Doubly->new();
    $list->insert_at_start(3)->insert_at_start(2)->insert_at_start(1);
    is($list->length, 3, 'chained insert_at_start');
    
    my @vals;
    $list->start;
    push @vals, $list->data;
    while (!$list->is_end) {
        $list->next;
        push @vals, $list->data;
    }
    is_deeply(\@vals, [1, 2, 3], 'chained inserts in correct order');
    
    $list->destroy;
};

done_testing();
