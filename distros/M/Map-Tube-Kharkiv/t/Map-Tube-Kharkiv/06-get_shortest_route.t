use strict;
use warnings;

use Encode qw(decode_utf8);
use English;
use Map::Tube::Kharkiv;
use Test::More tests => 5;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Kharkiv->new;
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
	$map->get_shortest_route(decode_utf8('Київська'), 'Foo');
};
like(
	$EVAL_ERROR,
	qr{^Map::Tube::get_node_by_name\(\): ERROR: Invalid Station Name \[Foo\]. \(status: 101\)},
	"Received invalid TO node 'Foo'.",
);
