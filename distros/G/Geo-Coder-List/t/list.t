#!perl -wT

use strict;
use warnings;
use Test::Most tests => 32;
use Test::NoWarnings;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

LIST: {
	SKIP: {
		skip 'Test requires Internet access', 30 unless(-e 't/online.enabled');

		eval {
			require Test::Number::Delta;

			Test::Number::Delta->import;

			require Geo::Coder::CA;

			Geo::Coder::CA->import;

			require Geo::Coder::Google::V3;

			Geo::Coder::Google::V3->import;

			if($ENV{GMAP_KEY}) {
				require Geo::Coder::GooglePlaces::V3;

				Geo::Coder::GooglePlaces::V3->import;
			}

			require Geo::Coder::OSM;

			Geo::Coder::OSM->import;

			require Geo::Coder::XYZ;

			Geo::Coder::XYZ->import;

			if(my $key = $ENV{BMAP_KEY}) {
				require Geo::Coder::Bing;

				Geo::Coder::Bing->import;
			}
		};

		if($@) {
			diag($@);
			diag('Not enough geocoders installed - skipping tests');
			skip 'Not enough geocoders installed', 30;
		}
		my $geocoderlist = new_ok('Geo::Coder::List')
			->push({ regex => qr/(Canada|USA|United States)$/, geocoder => new_ok('Geo::Coder::CA') })
			->push(new_ok('Geo::Coder::XYZ'))
			->push(new_ok('Geo::Coder::Google::V3'))
			->push(new_ok('Geo::Coder::OSM'));

		if(my $key = $ENV{GMAP_KEY}) {
			$geocoderlist->push(Geo::Coder::GooglePlaces::V3->new(key => $key));
		}
		if(my $key = $ENV{BMAP_KEY}) {
			$geocoderlist->push(Geo::Coder::Bing->new(key => $key));
		}

		my $location = $geocoderlist->geocode('Silver Spring, MD, USA');
		ok(defined($location));
		is(ref($location), 'HASH', 'geocode should return a reference to a HASH');
		delta_within($location->{geometry}{location}{lat}, 38.99, 1e-2);
		delta_within($location->{geometry}{location}{lng}, -77.03, 1e-2);
		is(ref($location->{'geocoder'}), 'Geo::Coder::CA', 'Verify CA encoder is used');
		sleep(1);	# play nicely

		$location = $geocoderlist->geocode('Wokingham, Berkshire, England');
		delta_within($location->{geometry}{location}{lat}, 51.42, 1e-2);
		delta_within($location->{geometry}{location}{lng}, -0.83, 1e-2);
		is(ref($location->{'geocoder'}), 'Geo::Coder::XYZ', 'Verify XYZ encoder is used');
		sleep(1);	# play nicely

		$location = $geocoderlist->geocode(location => '8600 Rockville Pike, Bethesda MD, 20894 USA');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{geometry}{location}{lat}, 38.99, 1e-1);
		delta_within($location->{geometry}{location}{lng}, -77.03, 1e-1);
		is(ref($location->{'geocoder'}), 'Geo::Coder::CA', 'Verify CA encoder is used');
		sleep(1);	# play nicely

		$location = $geocoderlist->geocode({ location => 'Rochester, Kent, United Kingdom' });
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{geometry}{location}{lat}, 51.40, 1e-2);
		delta_within($location->{geometry}{location}{lng}, 0.49, 1e-2);
		is(ref($location->{'geocoder'}), 'Geo::Coder::XYZ', 'Verify XYZ encoder is used');
		sleep(1);	# play nicely

		$location = $geocoderlist->geocode({ location => 'Rochester, Kent, England' });
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{geometry}{location}{lat}, 51.40, 1e-2);
		delta_within($location->{geometry}{location}{lng}, 0.49, 1e-2);
		is(ref($location->{'geocoder'}), 'Geo::Coder::XYZ', 'Verify XYZ encoder is used');

		ok(!defined($geocoderlist->geocode()));
		ok(!defined($geocoderlist->geocode('')));
	}
}
