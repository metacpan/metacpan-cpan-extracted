use strict;
use warnings;

use Encode qw(decode_utf8);
use English;
use Map::Tube::Nanjing;
use Test::More tests => 4;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Nanjing->new;
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
my $ret = $map->get_node_by_id('1-11');
is($ret->name, decode_utf8('中华门'), 'Get node for node id.');
