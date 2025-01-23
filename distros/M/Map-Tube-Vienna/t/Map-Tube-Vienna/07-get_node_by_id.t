use strict;
use warnings;

use English;
use Map::Tube::Vienna;
use Test::More tests => 4;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Vienna->new;
eval {
	$map->get_node_by_id;
};
like($EVAL_ERROR, qr{^Map::Tube::get_node_by_id\(\): ERROR: Missing Station ID. \(status: 102\)},
	'Missing station id.');

# Test.
eval {
	$map->get_node_by_id('foo');
};
like($EVAL_ERROR, qr{^Map::Tube::get_node_by_id\(\): ERROR: Invalid Station ID \[foo\]. \(status: 103\)},
	'Get node for bad node id..');

# Test.
my $ret = $map->get_node_by_id('1-13');
is($ret->name, 'Nestroyplatz', 'Get node for node id.');
