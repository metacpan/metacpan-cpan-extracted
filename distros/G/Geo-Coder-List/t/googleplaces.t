#!perl -wT

use strict;
use warnings;
use Test::Most tests => 16;
use Test::NoWarnings;
use Test::Number::Delta within => 1e-2;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

GOOGLEPLACES: {
	SKIP: {
		eval {
			require Geo::Coder::GooglePlaces::V3;

			Geo::Coder::GooglePlaces::V3->import;
		};

		if($@) {
			diag('Geo::Coder::GooglePlaces::V3 not installed - skipping tests');
			skip 'Geo::Coder::GooglePlaces::V3 not installed', 14;
		} else {
			diag("Using Geo::Coder::GooglePlaces::V3 $Geo::Coder::GooglePlaces::V3::VERSION");
		}
		my $geocoderlist = new_ok('Geo::Coder::List');
		my $key = $ENV{GMAP_KEY};
		my $geocoder = $key ? new_ok('Geo::Coder::GooglePlaces::V3' => [ key => $key ]) : new_ok('Geo::Coder::GooglePlaces::V3');
		$geocoderlist->push($geocoder);

		if($key) {
			my $location = $geocoderlist->geocode('Silver Spring, MD, USA');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_ok($location->{geometry}{location}{lat}, 38.991);
			delta_ok($location->{geometry}{location}{lng}, -77.026);

			$location = $geocoderlist->geocode('Wisdom Hospice, Rochester, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_ok($location->{geometry}{location}{lat}, 51.372);
			delta_ok($location->{geometry}{location}{lng}, 0.50873);

			$location = $geocoderlist->geocode('St Mary The Virgin, Minster, Thanet, Kent, England');
			ok(defined($location));
			ok(ref($location) eq 'HASH');
			delta_ok($location->{geometry}{location}{lat}, 51.330);
			delta_ok($location->{geometry}{location}{lng}, 1.366);
		} else {
			diag('Set GMAP_KEY to enable more tests');
			skip 'GMAP_KEY not set', 12;
		}
	}
}
