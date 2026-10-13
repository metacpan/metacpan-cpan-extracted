#!/usr/bin/env perl

use v5.38;
use lib ( '../lib', 'lib' );
use Logic::Relational::Syntax;

logic Network {
	table reachable/2;

	facts {
		edge('A', 'B');
		edge('B', 'C');
		edge('C', 'A');    # cycle
		edge('C', 'D');
	}

	rule reachable($x, $y) {
		edge($x, $y);
	}

	# Left-recursive rule over a cyclic graph
	rule reachable($x, $z) {
		fresh my $y;
		reachable($x, $y);
		edge($y, $z);
	}
}

my $q;
query Network::reachable('A', fresh my $node) -> $q;
my @nodes = $q->all_values($node);    # ('A', 'B', 'C', 'D')

say "('" . join("', '", @nodes) . "')";

