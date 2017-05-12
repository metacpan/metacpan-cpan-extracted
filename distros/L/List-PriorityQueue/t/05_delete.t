#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 17;

use List::PriorityQueue;

my $q = new List::PriorityQueue;

# delete an entry after adding it, ensure that order is correct.
foreach (["a", 1], ["b", 5], ["c", 15], ["d", 20], ["e", 10]) {
	$q->insert($_->[0], $_->[1]);
}
$q->delete("c");
is($q->pop(), "a", "1st retrieved element is a");
is($q->pop(), "b", "2nd retrieved element is b");
is($q->pop(), "e", "3rd retrieved element is e");
is($q->pop(), "d", "4th retrieved element is d");
ok(!defined($q->pop()), "No 5th element exists");

# now do the same, but add a new one with the same priority
foreach (["a", 1], ["b", 5], ["c", 15], ["d", 20], ["e", 10]) {
	$q->insert($_->[0], $_->[1]);
}
$q->delete("c");
$q->insert("x", 15);
is($q->pop(), "a", "1st retrieved element is a");
is($q->pop(), "b", "2nd retrieved element is b");
is($q->pop(), "e", "3rd retrieved element is e");
is($q->pop(), "x", "4th retrieved element is x");
is($q->pop(), "d", "5th retrieved element is d");
ok(!defined($q->pop()), "No 6th element exists");

# the same again, this time add one with a different priority
foreach (["a", 1], ["b", 5], ["c", 15], ["d", 20], ["e", 10]) {
	$q->insert($_->[0], $_->[1]);
}
$q->delete("c");
$q->insert("y", 25);
is($q->pop(), "a", "1st retrieved element is a");
is($q->pop(), "b", "2nd retrieved element is b");
is($q->pop(), "e", "3rd retrieved element is e");
is($q->pop(), "d", "4th retrieved element is d");
is($q->pop(), "y", "5th retrieved element is y");
ok(!defined($q->pop()), "No 6th element exists");

