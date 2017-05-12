#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;

use Hash::PriorityQueue;

my $q = Hash::PriorityQueue->new();
ok(defined($q), "Object created");

# insert some values, ensure they're popped in correct order.
foreach (["a", 2], ["b", 4], ["c", 1], ["d", 5], ["e", -1]) {
	$q->insert($_->[0], $_->[1]);
}
is($q->pop(), "e", "1st retrieved element is e");
is($q->pop(), "c", "2nd retrieved element is c");
is($q->pop(), "a", "3rd retrieved element is a");
is($q->pop(), "b", "4th retrieved element is b");
is($q->pop(), "d", "5th retrieved element is d");
ok(!defined($q->pop()), "No 6th element exists");

