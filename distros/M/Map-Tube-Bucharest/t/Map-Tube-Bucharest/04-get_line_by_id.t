use strict;
use warnings;

use English;
use Map::Tube::Bucharest;
use Test::More tests => 4;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Bucharest->new;
eval {
	$map->get_line_by_id;
};
like($EVAL_ERROR, qr{^Map::Tube::get_line_by_id\(\): ERROR: Missing Line ID. \(status: 120\)},
	'Missing line id.');

# Test.
eval {
	$map->get_line_by_id('foo');
};
like($EVAL_ERROR, qr{^Map::Tube::get_line_by_id\(\): ERROR: Invalid Line ID \[foo\]. \(status: 119\)},
	'Get line for bad line id.');

# Test.
my $ret = $map->get_line_by_id('M1');
is($ret->name, 'Linia M1', 'Get line for line id.');
