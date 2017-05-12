#!/usr/bin/perl

use Test::More;
use List::Priority;

my $l = List::Priority->new();
$l->insert(0, 2);
is($l->size, 1, "item successfully inserted");
$l->insert(0, 2);
is($l->size, 2, "duplicate item inserted");
$l->insert(0,7);
is($l->size, 3, "different item with same priority inserted");
$l->insert(1,2);
is($l->size, 4, "same item with different priority inserted");

is($l->pop, 2, "Testing items in queue");
is($l->pop, 2, "Items removed in FIFO order");
is($l->pop, 2, "Items removed in FIFO order");
is($l->pop, 7, "Items removed in FIFO order");

done_testing;
