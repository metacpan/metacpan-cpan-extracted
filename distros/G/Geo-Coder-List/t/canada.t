#!perl -wT

use strict;
use warnings;
use LWP;
use Test::Most tests => 11;
use Test::NoWarnings;
use Test::Number::Delta within => 1e-2;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

GOOGLEPLACES: {
	SKIP: {
		eval {
			require Geo::Coder::CA;

			Geo::Coder::CA->import();
		};

		# curl 'geocoder.ca/some_location?locate=9235+Main+St,+Richibucto,+New Brunswick,+Canada&json=1'
		if($@) {
			diag('Geo::Coder::CA not installed - skipping tests');
			skip 'Geo::Coder::CA not installed', 16;
		} else {
			diag("Using Geo::Coder::CA $Geo::Coder::CA::VERSION");
		}
		my $geocoderlist = new_ok('Geo::Coder::List');
		my $ca = new_ok('Geo::Coder::CA');
		$geocoderlist->push($ca);

		my $ua = LWP::UserAgent->new();
		$ua->env_proxy(1);
		$geocoderlist->ua($ua);
		ok($ca->ua() eq $ua);

		my $location = $geocoderlist->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada');
		ok(defined($location));
		is(ref($location), 'HASH', 'geocode should return a reference to a HASH');
		delta_ok($location->{geometry}{location}{lat}, 46.68);
		delta_ok($location->{geometry}{location}{lng}, -64.86);

		ok(!defined($geocoderlist->geocode()));
		ok(!defined($geocoderlist->geocode('')));
	}
}
