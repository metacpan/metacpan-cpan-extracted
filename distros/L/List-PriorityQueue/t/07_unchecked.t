#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 15;

use List::PriorityQueue;

my $q = new List::PriorityQueue;
ok(defined($q), "Object created");

# insert some values, ensure they're popped in correct order.
foreach (["a", 2], ["b", 4], ["c", 1], ["d", 5], ["e", -1]) {
	$q->unchecked_insert($_->[0], $_->[1]);
}
is($q->pop(), "e", "1st retrieved element is e");
is($q->pop(), "c", "2nd retrieved element is c");
is($q->pop(), "a", "3rd retrieved element is a");
is($q->pop(), "b", "4th retrieved element is b");
is($q->pop(), "d", "5th retrieved element is d");
ok(!defined($q->pop()), "No 6th element exists");

# multiple elements with the same priority are not guaranteed to come out
# in any specific order, but do ensure they all come out at all.
for ("a".."z") {
	# pidgeonhole principle ensures there will be duplicates
	$q->unchecked_insert($_, int(rand(10)));
}
my @foo;
while ($_ = $q->pop()) {
	push(@foo, $_);
}
is_deeply([sort(@foo)], ["a".."z"], "Elements with same priority come out correctly");

# empty for next test
while ($q->pop()) { }
ok(!defined($q->pop()), "Queue flushed correctly");

# update some elements after inserting, ensure order is fixed.
foreach (["a", 2], ["b", 4], ["c", 1], ["d", 5], ["e", -1]) {
	$q->unchecked_insert($_->[0], $_->[1]);
}
$q->unchecked_update("a", 6);
is($q->pop(), "e", "1st retrieved element is e");
is($q->pop(), "c", "2nd retrieved element is c");
is($q->pop(), "b", "3rd retrieved element is b");
is($q->pop(), "d", "4th retrieved element is d");
is($q->pop(), "a", "5th retrieved element is a");
ok(!defined($q->pop()), "No 6th element exists");

