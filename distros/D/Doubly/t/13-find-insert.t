#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Doubly');

# Test find - basic
subtest 'find - basic' => sub {
    plan tests => 5;
    
    my $list = Doubly->new();
    $list->bulk_add(10, 20, 30, 40, 50);
    
    # Find 30
    my $result = $list->find(sub { $_[0] == 30 });
    ok(defined $result, 'find returns result');
    is($list->data, 30, 'current is at found position');
    
    # Find 10 (first)
    $result = $list->find(sub { $_[0] == 10 });
    ok(defined $result, 'find first element');
    is($list->data, 10, 'current is at first');
    
    # Find 50 (last)
    $result = $list->find(sub { $_[0] == 50 });
    is($list->data, 50, 'current is at last');
    
    $list->destroy;
};

# Test find - not found
subtest 'find - not found' => sub {
    plan tests => 2;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3);
    
    my $result = $list->find(sub { $_[0] == 999 });
    ok(!defined $result, 'find returns undef when not found');
    
    # List should still be usable
    is($list->length, 3, 'list still has 3 items');
    
    $list->destroy;
};

# Test find with string data
subtest 'find - string data' => sub {
    plan tests => 2;
    
    my $list = Doubly->new();
    $list->bulk_add('apple', 'banana', 'cherry', 'date');
    
    my $result = $list->find(sub { $_[0] eq 'cherry' });
    ok(defined $result, 'found cherry');
    is($list->data, 'cherry', 'current is at cherry');
    
    $list->destroy;
};

# Test find - complex callback
subtest 'find - complex callback' => sub {
    plan tests => 2;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 4, 9, 16, 25, 36);
    
    # Find first even square
    my $result = $list->find(sub { $_[0] % 2 == 0 });
    ok(defined $result, 'found even number');
    is($list->data, 4, 'first even is 4');
    
    $list->destroy;
};

# Test insert with callback - basic
subtest 'insert - sorted insertion' => sub {
    plan tests => 2;
    
    my $list = Doubly->new();
    $list->bulk_add(10, 20, 40, 50);
    
    # Insert 30 in sorted position
    $list->insert(sub { $_[0] > 30 }, 30);
    
    is($list->length, 5, 'list has 5 items');
    
    # Verify order
    my @vals;
    $list->start;
    push @vals, $list->data;
    while (!$list->is_end) {
        $list->next;
        push @vals, $list->data;
    }
    is_deeply(\@vals, [10, 20, 30, 40, 50], 'list is sorted');
    
    $list->destroy;
};

# Test insert - at start
subtest 'insert - at start' => sub {
    plan tests => 2;
    
    my $list = Doubly->new();
    $list->bulk_add(20, 30, 40);
    
    # Insert 10 at start (first element > 10)
    $list->insert(sub { $_[0] > 10 }, 10);
    
    $list->start;
    is($list->data, 10, 'first element is 10');
    is($list->length, 4, 'list has 4 items');
    
    $list->destroy;
};

# Test insert - not found (appends at end)
subtest 'insert - not found appends' => sub {
    plan tests => 2;
    
    my $list = Doubly->new();
    $list->bulk_add(10, 20, 30);
    
    # Nothing > 100, so append at end
    $list->insert(sub { $_[0] > 100 }, 40);
    
    is($list->length, 4, 'list has 4 items');
    $list->end;
    is($list->data, 40, 'last element is 40');
    
    $list->destroy;
};

# Test insert - chaining
subtest 'insert - chaining' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    $list->add(100);
    
    # Chain multiple inserts
    $list->insert(sub { $_[0] > 10 }, 50)
         ->insert(sub { $_[0] > 10 }, 25)
         ->insert(sub { $_[0] > 10 }, 10);
    
    my @vals;
    $list->start;
    push @vals, $list->data;
    while (!$list->is_end) {
        $list->next;
        push @vals, $list->data;
    }
    is_deeply(\@vals, [10, 25, 50, 100], 'chained inserts in order');
    
    $list->destroy;
};

# Test find on empty list
subtest 'find - empty list' => sub {
    plan tests => 1;
    
    my $list = Doubly->new();
    my $result = $list->find(sub { 1 });
    ok(!defined $result, 'find on empty list returns undef');
    
    $list->destroy;
};

# Test insert on empty list
subtest 'insert - empty list' => sub {
    plan tests => 2;
    
    my $list = Doubly->new();
    $list->insert(sub { 1 }, 42);
    
    is($list->length, 1, 'list has 1 item');
    is($list->data, 42, 'data is 42');
    
    $list->destroy;
};

# Test find with side effects in callback (should work)
subtest 'find - callback with external state' => sub {
    plan tests => 2;
    
    my $list = Doubly->new();
    $list->bulk_add(1, 2, 3, 4, 5);
    
    my $count = 0;
    $list->find(sub { 
        $count++;
        $_[0] == 3;
    });
    
    is($count, 3, 'callback called 3 times before finding');
    is($list->data, 3, 'found correct item');
    
    $list->destroy;
};

done_testing();
