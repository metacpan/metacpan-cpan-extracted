#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Chained method calls and edge cases for Doubly

use_ok('Doubly');

# Test 1: Long chain of navigation
subtest 'long navigation chain' => sub {
    plan tests => 5;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3, 4, 5);
    
    # Chain: start -> next -> next -> next -> next (should be at 5)
    my $result = $list->start->next->next->next->next;
    is($list->data, 5, 'chained to last element');
    
    # Chain back: prev -> prev -> prev -> prev (should be at 1)
    $list->prev->prev->prev->prev;
    is($list->data, 1, 'chained back to first');
    
    # Mixed chain
    $list->start->next->next->prev->next;
    is($list->data, 3, 'mixed chain navigation');
    
    # End then prev chain
    $list->end->prev->prev;
    is($list->data, 3, 'end then prev chain');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 2: Chained adds
subtest 'chained add operations' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    
    # Can't really chain add() as it returns the data, but we can do multiple
    $list->add(1);
    $list->add(2);
    $list->add(3);
    
    is($list->length, 3, 'three items added');
    is($list->start->data, 1, 'first is 1');
    is($list->end->data, 3, 'last is 3');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 3: Navigation past boundaries
subtest 'navigation at boundaries' => sub {
    plan tests => 6;
    
    my $list = Doubly->new();
    $list->bulk_add('a', 'b', 'c');
    
    # At start, call prev - should stay at start
    $list->start;
    is($list->data, 'a', 'at start');
    $list->prev;  # Should not crash
    is($list->data, 'a', 'prev at start stays at start');
    
    # At end, call next - should stay at end
    $list->end;
    is($list->data, 'c', 'at end');
    $list->next;  # Should not crash
    is($list->data, 'c', 'next at end stays at end');
    
    $list->destroy();
    ok(1, 'cleanup successful');
    
    # Single element list
    my $single = Doubly->new('only');
    is($single->start->end->data, 'only', 'single element start/end');
    $single->destroy();
};

# Test 4: Chained insert operations
subtest 'chained insert operations' => sub {
    plan tests => 5;
    
    my $list = Doubly->new();
    $list->add(2);
    
    # Insert before then navigate
    $list->start->insert_before(1)->start;
    is($list->data, 1, 'insert_before then start');
    
    # Insert after then navigate
    $list->end->insert_after(3)->end;
    is($list->data, 3, 'insert_after then end');
    
    is($list->length, 3, 'three items total');
    
    # Verify order
    my @values;
    $list->start;
    push @values, $list->data;
    while (!$list->is_end) {
        $list->next;
        push @values, $list->data;
    }
    is_deeply(\@values, [1, 2, 3], 'correct order after chained inserts');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 5: Remove then navigate
subtest 'remove then navigate chain' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3, 4, 5);
    
    # Remove from start, then navigate
    $list->remove_from_start;
    is($list->start->data, 2, 'after remove_from_start, first is 2');
    
    # Remove from end, then navigate
    $list->remove_from_end;
    is($list->end->data, 4, 'after remove_from_end, last is 4');
    
    is($list->length, 3, 'three items remain');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 6: is_start/is_end in chains
subtest 'is_start and is_end checks' => sub {
    plan tests => 6;
    
    my $list = Doubly->new();
    $list->bulk_add('a', 'b', 'c');
    
    ok($list->start->is_start, 'is_start after start');
    ok(!$list->is_end, 'not is_end at start');
    
    ok($list->end->is_end, 'is_end after end');
    ok(!$list->is_start, 'not is_start at end');
    
    $list->next;  # Move to middle (actually we're at end, so this stays)
    $list->start->next;  # Now at 'b'
    ok(!$list->is_start && !$list->is_end, 'middle element is neither');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 7: Empty list edge cases
subtest 'empty list operations' => sub {
    plan tests => 5;
    
    my $list = Doubly->new();
    
    is($list->length, 0, 'new list is empty');
    
    # These should not crash on empty list
    my $start_result = $list->start;
    ok(defined $start_result, 'start on empty list returns something');
    
    my $end_result = $list->end;
    ok(defined $end_result, 'end on empty list returns something');
    
    # Add then remove to empty
    $list->add('x');
    $list->remove_from_start;
    is($list->length, 0, 'back to empty after add/remove');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 8: data() getter and setter chaining
subtest 'data getter and setter' => sub {
    plan tests => 4;
    
    my $list = Doubly->new('initial');
    
    is($list->data, 'initial', 'initial data');
    
    $list->data('changed');
    is($list->data, 'changed', 'data changed');
    
    # Add more and change specific positions
    $list->add('second');
    $list->start->data('first');
    $list->end->data('last');
    
    is($list->start->data, 'first', 'first element changed');
    is($list->end->data, 'last', 'last element changed');
    
    $list->destroy();
};

done_testing();
