#!/usr/bin/perl

use Test::More qw(
	no_plan
	);

use warnings;
use strict;

use List::oo qw(L Split);

my @methods = (
	qw(
		L
		new
		Split
		grep
		map
		reverse
		splice
		dice
		sort
		push
		pop
		shift
		unshift
		l
		join
		length
	),
	map({'i' . $_} qw(
		push
		pop
		shift
		unshift
	)),
	qw(
		flatten
	),
);

use_ok('List::oo');

foreach my $method (@methods) {
	ok('List::oo'->can($method), $method);
}
