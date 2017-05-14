#!perl -wT

use strict;
use warnings;
use Test::Most tests => 24;
use Test::NoWarnings;
use Test::Number::Delta within => 1e-2;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
	use_ok('Geo::Coder::CA');
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

			if($ENV{BMAP_KEY}) {
				require Geo::Coder::Bing;

				Geo::Coder::Bing->import;
			}
		};

		if($@) {
			diag($@);
			diag('Not enough geocoders installed - skipping tests');
			skip 'Not enough geocoders installed', 21;
		}
		my $geocoderlist = new_ok('Geo::Coder::List')
			->push({ regex => qr/(Canada|USA|United States)$/, geocoder => new_ok('Geo::Coder::CA') })
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
		is(ref($location), 'HASH', 'geocode should return a reference to a HASH');
		delta_ok($location->{geometry}{location}{lat}, 38.991);
		delta_ok($location->{geometry}{location}{lng}, -77.026);
		is(ref($location->{'geocoder'}), 'Geo::Coder::CA', 'Verify CA encoder is used');

		$location = $geocoderlist->geocode(location => '8600 Rockville Pike, Bethesda MD, 20894 USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_ok($location->{geometry}{location}{lat}, 39.00);
		delta_ok($location->{geometry}{location}{lng}, -77.10);
		is(ref($location->{'geocoder'}), 'Geo::Coder::CA', 'Verify CA encoder is used');

		$location = $geocoderlist->geocode({ location => 'Rochester, Kent, England' });
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_ok($location->{geometry}{location}{lat}, 51.388);
		delta_ok($location->{geometry}{location}{lng}, 0.50672);
		is(ref($location->{'geocoder'}), 'Geo::Coder::Google::V3', 'Verify Google encoder is used');

		ok(!defined($geocoderlist->geocode()));
		ok(!defined($geocoderlist->geocode('')));
	}
}
