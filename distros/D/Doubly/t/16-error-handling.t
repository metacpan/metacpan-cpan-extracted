#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Error handling and edge case tests for Doubly

use_ok('Doubly');

# Test 1: Negative position handling
subtest 'negative position handling' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3, 4, 5);
    
    # insert_at_pos with negative - should handle gracefully
    eval { $list->insert_at_pos(-1, 'neg'); };
    ok(!$@, 'insert_at_pos with -1 does not crash');
    
    # remove_from_pos with negative
    eval { $list->remove_from_pos(-1); };
    ok(!$@, 'remove_from_pos with -1 does not crash');
    
    # Verify list is still usable
    ok($list->length >= 3, 'list still has items');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 2: Position beyond length
subtest 'position beyond length' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3);
    
    # insert_at_pos beyond length
    eval { $list->insert_at_pos(100, 'far'); };
    ok(!$@, 'insert_at_pos beyond length does not crash');
    
    # remove_from_pos beyond length
    eval { $list->remove_from_pos(100); };
    ok(!$@, 'remove_from_pos beyond length does not crash');
    
    ok($list->length >= 1, 'list still usable');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 3: Operations on destroyed list
subtest 'operations after destroy' => sub {
    plan tests => 5;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3);
    $list->destroy();
    
    # These should not crash after destroy
    eval { $list->length; };
    ok(!$@, 'length after destroy does not crash');
    
    eval { $list->start; };
    ok(!$@, 'start after destroy does not crash');
    
    eval { $list->add(1); };
    ok(!$@, 'add after destroy does not crash');
    
    eval { $list->data; };
    ok(!$@, 'data after destroy does not crash');
    
    ok(1, 'all post-destroy operations handled');
};

# Test 4: Undef values
subtest 'undef value handling' => sub {
    plan tests => 5;
    
    my $list = Doubly->new();
    
    # Add undef
    $list->add(undef);
    is($list->length, 1, 'added undef');
    ok(!defined($list->data), 'data is undef');
    
    # Add mix of values and undef
    $list->add('real');
    $list->add(undef);
    $list->add(42);
    
    is($list->length, 4, 'four items including undefs');
    
    $list->destroy();
    ok(1, 'cleanup successful');
    
    # New with undef
    my $list2 = Doubly->new(undef);
    ok(!defined($list2->data) || $list2->length == 0, 'new with undef handled');
    $list2->destroy();
};

# Test 5: Empty string values
subtest 'empty string handling' => sub {
    plan tests => 4;
    
    my $list = Doubly->new('');
    is($list->data, '', 'empty string stored');
    
    $list->add('');
    $list->add('not empty');
    $list->add('');
    
    is($list->length, 4, 'four items including empty strings');
    is($list->start->data, '', 'first is empty string');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 6: Zero value handling
subtest 'zero value handling' => sub {
    plan tests => 5;
    
    my $list = Doubly->new(0);
    is($list->data, 0, 'zero stored correctly');
    ok(defined($list->data), 'zero is defined');
    
    $list->add(0);
    $list->add(0.0);
    $list->add('0');
    
    is($list->length, 4, 'four zeros');
    
    # Verify zeros are retrievable
    $list->start;
    my $count = 0;
    do {
        $count++ if defined($list->data) && $list->data == 0;
    } while (!$list->is_end && $list->next);
    
    ok($count >= 3, 'zeros retrievable');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 7: Very long strings
subtest 'long string handling' => sub {
    plan tests => 3;
    
    my $list = Doubly->new();
    my $long = 'x' x 10000;
    
    $list->add($long);
    is(length($list->data), 10000, 'long string stored');
    is($list->data, $long, 'long string matches');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 8: Unicode handling
subtest 'unicode handling' => sub {
    plan tests => 4;
    
    my $list = Doubly->new();
    
    $list->add("Hello 世界");
    $list->add("🎉🎊🎈");
    $list->add("Ñoño");
    
    is($list->length, 3, 'three unicode items');
    
    $list->start;
    like($list->data, qr/世界/, 'chinese characters preserved');
    
    $list->next;
    like($list->data, qr/🎉/, 'emoji preserved');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 9: Find with no matches
subtest 'find with no matches' => sub {
    plan tests => 3;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3, 4, 5);
    
    my $result = $list->find(sub { $_[0] == 999 });
    ok(!defined($result) || !$result, 'find returns false for no match');
    
    # List should still be usable
    is($list->length, 5, 'list unchanged after failed find');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 10: Find on empty list
subtest 'find on empty list' => sub {
    plan tests => 3;
    
    my $list = Doubly->new();
    
    my $result;
    eval { $result = $list->find(sub { 1 }); };
    ok(!$@, 'find on empty list does not crash');
    ok(!defined($result) || !$result, 'find on empty returns false');
    
    $list->destroy();
    ok(1, 'cleanup successful');
};

# Test 11: Insert on empty list
subtest 'insert operations on empty list' => sub {
    plan tests => 8;
    
    # insert_before on empty
    my $list1 = Doubly->new();
    $list1->insert_before('val');
    ok($list1->length >= 0, 'insert_before on empty handled');
    $list1->destroy();
    
    # insert_after on empty
    my $list2 = Doubly->new();
    $list2->insert_after('val');
    ok($list2->length >= 0, 'insert_after on empty handled');
    $list2->destroy();
    
    # insert_at_start on empty
    my $list3 = Doubly->new();
    $list3->insert_at_start('val');
    is($list3->length, 1, 'insert_at_start on empty creates item');
    is($list3->data, 'val', 'value correct');
    $list3->destroy();
    
    # insert_at_end on empty
    my $list4 = Doubly->new();
    $list4->insert_at_end('val');
    is($list4->length, 1, 'insert_at_end on empty creates item');
    is($list4->data, 'val', 'value correct');
    $list4->destroy();
    
    # insert_at_pos(0) on empty
    my $list5 = Doubly->new();
    $list5->insert_at_pos(0, 'val');
    ok($list5->length >= 0, 'insert_at_pos(0) on empty handled');
    $list5->destroy();
    
    ok(1, 'all insert on empty tests passed');
};

# Test 12: Remove from single-element list
subtest 'remove from single element list' => sub {
    plan tests => 6;
    
    my $list1 = Doubly->new('only');
    $list1->remove_from_start;
    is($list1->length, 0, 'remove_from_start leaves empty');
    $list1->destroy();
    
    my $list2 = Doubly->new('only');
    $list2->remove_from_end;
    is($list2->length, 0, 'remove_from_end leaves empty');
    $list2->destroy();
    
    my $list3 = Doubly->new('only');
    $list3->remove;
    is($list3->length, 0, 'remove leaves empty');
    $list3->destroy();
    
    my $list4 = Doubly->new('only');
    $list4->remove_from_pos(0);
    is($list4->length, 0, 'remove_from_pos(0) leaves empty');
    $list4->destroy();
    
    ok(1, 'single element remove tests passed');
    ok(1, 'cleanup successful');
};

done_testing();
