#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;

use Hash::PriorityQueue;

my $q = Hash::PriorityQueue->new();

# update some elements after inserting, ensure order is fixed.
foreach (["a", 2], ["b", 4], ["c", 1], ["d", 5], ["e", -1]) {
	$q->insert($_->[0], $_->[1]);
}
$q->update("a", 6);
is($q->pop(), "e", "1st retrieved element is e");
is($q->pop(), "c", "2nd retrieved element is c");
is($q->pop(), "b", "3rd retrieved element is b");
is($q->pop(), "d", "4th retrieved element is d");
is($q->pop(), "a", "5th retrieved element is a");
ok(!defined($q->pop()), "No 6th element exists");

