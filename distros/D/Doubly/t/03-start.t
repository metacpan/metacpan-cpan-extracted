#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Doubly;

# Test start navigation
ok(my $list = Doubly->new(), 'created list');

$list->add(1);
$list->add(2);
$list->add(3);

is($list->length, 3, 'length is 3');

# start() returns to head
ok($list = $list->start, 'called start');
is($list->data, 1, 'at position 1');
ok($list->is_start, 'is_start is true');
ok(!$list->is_end, 'is_end is false');

# Move to next
ok($list = $list->next, 'called next');
is($list->data, 2, 'at position 2');
ok(!$list->is_start, 'is_start is false');
ok(!$list->is_end, 'is_end is false');

# Move to next again
ok($list = $list->next, 'called next again');
is($list->data, 3, 'at position 3');
ok(!$list->is_start, 'is_start is false');
ok($list->is_end, 'is_end is true');

done_testing();
