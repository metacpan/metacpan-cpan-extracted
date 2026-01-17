#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Doubly;

# Test end navigation
ok(my $list = Doubly->new(), 'created list');

$list->add(1);
$list->add(2);
$list->add(3);

is($list->length, 3, 'length is 3');

# end() goes to tail
ok($list = $list->end, 'called end');
is($list->data, 3, 'at position 3');
ok($list->is_end, 'is_end is true');
ok(!$list->is_start, 'is_start is false');

# Move to prev
ok($list = $list->prev, 'called prev');
is($list->data, 2, 'at position 2');
ok(!$list->is_start, 'is_start is false');
ok(!$list->is_end, 'is_end is false');

# Move to prev again
ok($list = $list->prev, 'called prev again');
is($list->data, 1, 'at position 1');
ok($list->is_start, 'is_start is true');
ok(!$list->is_end, 'is_end is false');

done_testing();
