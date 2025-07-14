#!perl -wT

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Geo::Coder::XYZ') }

CARP: {
	my $g = new_ok('Geo::Coder::XYZ');

	throws_ok { my $location = $g->geocode(); } qr/^Usage: /, 'No args dies';
	lives_ok { my $location = $g->geocode(\'New Brunswick, Canada'); } 'Passing just a location is fine';

	done_testing();
}
