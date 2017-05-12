#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use Hash::PriorityQueue;

my $q = Hash::PriorityQueue->new();

# multiple elements with the same priority are not guaranteed to come out
# in any specific order, but do ensure they all come out at all.
for ("a".."z") {
	# pidgeonhole principle ensures there will be duplicates
	$q->insert($_, int(rand(10)));
}
my @foo;
while ($_ = $q->pop()) {
	push(@foo, $_);
}
is_deeply([sort(@foo)], ["a".."z"], "Elements with same priority come out correctly");
