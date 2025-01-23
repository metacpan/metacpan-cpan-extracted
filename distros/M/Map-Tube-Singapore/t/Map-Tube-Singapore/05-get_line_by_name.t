use strict;
use warnings;

use English;
use Map::Tube::Singapore;
use Test::More tests => 4;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Singapore->new;
eval {
	$map->get_line_by_name;
};
like($EVAL_ERROR, qr{^Map::Tube::get_line_by_name\(\): ERROR: Missing Line Name. \(status: 104\)},
	'Missing line name.');

# Test.
eval {
	$map->get_line_by_name('foo');
};
like($EVAL_ERROR, qr{^Map::Tube::get_line_by_name\(\): ERROR: Invalid Line Name \[foo\]. \(status: 105\)},
	'Get line for bad line name.');

# Test.
my $ret = $map->get_line_by_name('North South MRT Line');
is($ret->id, 'NSL', 'Get line for line name.');
