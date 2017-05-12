# Pragmas.
use strict;
use warnings;

# Modules.
use English;
use Map::Tube::Vienna;
use Test::More tests => 4;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Vienna->new;
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
my $ret = $map->get_line_by_name('U-Bahn-Linie U3');
is($ret->id, 'U3', 'Get line for line name.');
