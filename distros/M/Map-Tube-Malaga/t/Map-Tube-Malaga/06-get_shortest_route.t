# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use Map::Tube::Malaga;
use Test::More tests => 5;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Malaga->new;
eval {
	$map->get_shortest_route;
};
like($EVAL_ERROR, qr{^Map::Tube::get_shortest_route\(\): ERROR: Missing Station Name. \(status: 100\)},
	'Either FROM/TO node is undefined.');

# Test.
eval {
	$map->get_shortest_route('Foo');
};
like($EVAL_ERROR, qr{^Map::Tube::get_shortest_route\(\): ERROR: Missing Station Name. \(status: 100\)},
	'Either FROM/TO node is undefined.');

# Test.
eval {
	$map->get_shortest_route('Foo', 'Bar');
};
like(
	$EVAL_ERROR,
	qr{^Map::Tube::get_node_by_name\(\): ERROR: Invalid Station Name \[Foo\]. \(status: 101\)},
	"Received invalid FROM node 'Foo'.",
);

# Test.
eval {
	$map->get_shortest_route('Barbarela', 'Foo');
};
like(
	$EVAL_ERROR,
	qr{^Map::Tube::get_node_by_name\(\): ERROR: Invalid Station Name \[Foo\]. \(status: 101\)},
	"Received invalid TO node 'Foo'.",
);
