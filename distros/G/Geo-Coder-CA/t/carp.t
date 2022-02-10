#!perl -wT

use strict;
use warnings;
use Test::Most;
use Geo::Coder::CA;

CARP: {
	eval 'use Test::Carp';

	if($@) {
		plan(skip_all => 'Test::Carp needed to check error messages');
	} else {
		my $g = new_ok('Geo::Coder::CA');
		does_croak_that_matches(sub { my $location = $g->geocode(); }, qr/^Usage: geocode\(/);
		does_croak_that_matches(sub { my $location = $g->geocode(foo => 'bar'); }, qr/^Usage: geocode\(/);
		does_croak_that_matches(sub { my $location = $g->geocode({ xyzzy => 'plugh' }); }, qr/^Usage: geocode\(/);
		done_testing();
	}
}
