#!perl -wT

use strict;
use warnings;
use Test::Most tests => 14;
use Test::NoWarnings;
use Test::Number::Delta within => 1e-2;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

LIST: {
	SKIP: {
		eval {
			require Geo::Coder::Google::V3;

			Geo::Coder::Google::V3->import;

			if($ENV{GMAP_KEY}) {
				require Geo::Coder::GooglePlaces::V3;

				Geo::Coder::GooglePlaces::V3->import;
			}

			require Geo::Coder::OSM;

			Geo::Coder::OSM->import;

			if($ENV{GMAP_KEY}) {
				require Geo::Coder::Bing;

				Geo::Coder::Bing->import;
			}
		};

		if($@) {
			diag($@);
			diag('Not enough geocoders installed - skipping tests');
			skip 'Not enough geocoders installed', 12;
		}
		my $geocoderlist = new_ok('Geo::Coder::List')
			->push(new_ok('Geo::Coder::Google::V3'))
			->push(new_ok('Geo::Coder::OSM'));

		if(my $key = $ENV{GMAP_KEY}) {
			$geocoderlist->push(new_ok('Geo::Coder::GooglePlaces::V3' => [ key => $key ]));
		}
		if(my $key = $ENV{BMAP_KEY}) {
			$geocoderlist->push(new_ok('Geo::Coder::Bing' => [ key => $key ]));
		}

		my $location = $geocoderlist->geocode('Silver Spring, MD, USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_ok($location->{geometry}{location}{lat}, 38.991);
		delta_ok($location->{geometry}{location}{lng}, -77.026);

		$location = $geocoderlist->geocode(location => 'St Mary The Virgin, Minster, Thanet, Kent, England');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_ok($location->{geometry}{location}{lat}, 51.330);
		delta_ok($location->{geometry}{location}{lng}, 1.366);

		ok(!defined($geocoderlist->geocode()));
	}
}
