use strict;
use warnings;

use Encode qw(decode_utf8);
use English;
use Map::Tube::Samara;
use Test::More tests => 2;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Samara->new;
eval {
	$map->get_stations('foo');
};
like($EVAL_ERROR, qr{^Map::Tube::get_stations\(\): ERROR: Invalid Line Name \[foo\]. \(status: 105\)},
	'Invalid line name.');
