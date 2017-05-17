#!perl -wT

use strict;
use warnings;
use Test::Most tests => 18;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

GOOGLEPLACES: {
	SKIP: {
		skip 'Test requires Internet access', 16 unless(-e 't/online.enabled');

		eval {
			require Geo::Coder::US;

			Geo::Coder::US->import();

			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Geo::Coder::US not installed - skipping tests');
			skip 'Geo::Coder::US not installed', 16;
		} else {
			diag("Using Geo::Coder::US $Geo::Coder::US::VERSION");
		}
		my $geocoderlist = new_ok('Geo::Coder::List');
		my $geocoder = new_ok('Geo::Coder::US');
		$geocoderlist->push($geocoder);

		my $location = $geocoderlist->geocode(location => '8600 Rockville Pike, Bethesda MD, 20894 USA');
		ok(defined($location));
		is(ref($location), 'HASH', 'geocode should return a reference to a HASH');
		delta_within($location->{geometry}{location}{lat}, 39.00, 1e-1);
		delta_within($location->{geometry}{location}{lng}, -77.10, 1e-1);

		ok(!defined($geocoderlist->geocode()));
		ok(!defined($geocoderlist->geocode('')));
	}
}
