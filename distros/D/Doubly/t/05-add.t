#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Doubly;

# Test add operation
ok(my $list = Doubly->new(), 'created list');

is($list->length, 0, 'initial length is 0');

# Add first item
ok($list->add(1), 'add returns list');
is($list->length, 1, 'length is 1');

# Add more items
ok($list->add(2), 'added 2');
ok($list->add(3), 'added 3');
ok($list->add(4), 'added 4');

is($list->length, 4, 'length is 4');

# Verify order
ok($list = $list->start, 'go to start');
is($list->data, 1, 'first item is 1');

ok($list = $list->next, 'next');
is($list->data, 2, 'second item is 2');

ok($list = $list->next, 'next');
is($list->data, 3, 'third item is 3');

ok($list = $list->next, 'next');
is($list->data, 4, 'fourth item is 4');

# Test bulk_add
ok(my $list2 = Doubly->new(), 'created second list');
ok($list2->bulk_add(10, 20, 30, 40, 50), 'bulk_add');
is($list2->length, 5, 'length is 5 after bulk_add');

$list2->start;
is($list2->data, 10, 'first item is 10');
$list2->end;
is($list2->data, 50, 'last item is 50');

done_testing();
