#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Doubly;

# Test chained operations
ok(my $list = Doubly->new(), 'created list');

# Chain add operations
$list->add(1)->add(2)->add(3)->add(4)->add(5);
is($list->length, 5, 'length is 5 after chained adds');

# Chain navigation
$list->start;
is($list->data, 1, 'at start');

$list->next->next;
is($list->data, 3, 'after two nexts');

$list->end->prev;
is($list->data, 4, 'end then prev');

# Mixed operations
ok(my $list2 = Doubly->new("first"), 'created with initial');
$list2->add("second")->add("third");

is($list2->length, 3, 'length is 3');

$list2->start;
is($list2->data, "first", 'first item');

$list2->next;
is($list2->data, "second", 'second item');

$list2->next;
is($list2->data, "third", 'third item');

done_testing();
