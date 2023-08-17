#!perl -wT

use strict;
use warnings;
use Test::Most;
use Geo::Coder::List;

CARP: {
	eval 'use Test::Carp';

	if($@) {
		plan(skip_all => 'Test::Carp needed to check error messages');
	} else {
		my $g = new_ok('Geo::Coder::List');
		does_carp_that_matches(sub { my $location = $g->geocode(); }, qr/usage: geocode\(/);
		does_carp_that_matches(sub { my $location = $g->geocode(''); }, qr/usage: geocode\(/);
		does_carp_that_matches(sub { my $location = $g->geocode({ location => '' }); }, qr/usage: geocode\(/);
		does_carp_that_matches(sub { my $location = $g->geocode(location => ''); }, qr/usage: geocode\(/);
		does_carp_that_matches(sub { my $location = $g->geocode(foo => 'bar'); }, qr/usage: geocode\(/);
		does_carp_that_matches(sub { my $location = $g->geocode({ xyzzy => 'plugh' }); }, qr/usage: geocode\(/);
		done_testing();
	}
}
