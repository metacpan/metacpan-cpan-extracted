# Pragmas.
use strict;
use warnings;

# Modules.
use Encode qw(decode_utf8);
use English;
use Map::Tube::Vienna;
use Test::More tests => 3;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Vienna->new;
eval {
	$map->get_stations;
};
like($EVAL_ERROR, qr{^Map::Tube::get_stations\(\): ERROR: Missing Line Name. \(status: 104\)},
	'Missing line name.');

# Test.
eval {
	$map->get_stations('foo');
};
like($EVAL_ERROR, qr{^Map::Tube::get_stations\(\): ERROR: Invalid Line Name \[foo\]. \(status: 105\)},
	'Invalid line name.');
