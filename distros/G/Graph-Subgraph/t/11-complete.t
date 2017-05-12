#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

use Graph::Subgraph;

my $K6 = Graph->new(directed => 0, vertices => [1..6]);

my $K3_3 = $K6->complete->subgraph ([1..3], [4..6]);
note $K3_3;

foreach my $i (1..3) {
	foreach my $j (4..6) {
		$K6->add_edge($i, $j);
	};
};
note $K6;

is ($K3_3, $K6, "K3,3: creating edges == subgraph of K6");
