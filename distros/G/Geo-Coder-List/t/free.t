#!perl -wT

use strict;
use warnings;
use Test::Most tests => 14;
use Test::NoWarnings;
use Test::Deep;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

FREE: {
	SKIP: {
		eval {
			require Geo::Coder::Free;

			Geo::Coder::Free->import();

			require Geo::Coder::Free::Local;

			Geo::Coder::Free::Local->import();

			require Test::Number::Delta;

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Geo::Coder::Free not installed - skipping tests');
			skip 'Geo::Coder::Free not installed', 12;
		} else {
			diag("Using Geo::Coder::Free $Geo::Coder::Free::VERSION",
				"/Geo::Coder::Free::Local $Geo::Coder::Free::Local::VERSION");
		}

		my $cache;

		eval {
			require CHI;

			CHI->import();
		};

		if($@) {
			diag('CHI not installed');
		} else {
			diag("Using CHI $CHI::VERSION");
			my $hash = {};
			$cache = CHI->new(driver => 'Memory', datastore => $hash);
		}

		my $geo_coder_list;
		if($cache) {
			$geo_coder_list = new_ok('Geo::Coder::List' => [ 'cache' => $cache ]);
		} else {
			$geo_coder_list = new_ok('Geo::Coder::List');
		}
		my $geo_coder_free = new_ok('Geo::Coder::Free');

		$geo_coder_list->push({ regex => qr/,\s*(USA|US|United States|Canada|Australia)\s*$/, geocoder => $geo_coder_free })
			->push({ regex => qr/^[\w\s\-]+?,[\w\s]+,[\w\s]+?$/, geocoder => $geo_coder_free })
			# E.g. 'Nebraska, USA'
			->push({ regex => qr/^[\w\s]+,\s*(UK|England|Canada|USA|US|United States)$/i, geocoder => $geo_coder_free })
			->push({ regex => qr/^[\w\s]+,\s*[\w\s],\s*(UK|England|Wales|Scotland)$/i, geocoder => $geo_coder_free })
			->push(new_ok('Geo::Coder::Free::Local'));

		ok(!defined($geo_coder_list->geocode()));

		cmp_deeply($geo_coder_list->geocode('NCBI, MEDLARS DR, BETHESDA, MONTGOMERY, MD, USA'),
			methods('lat' => num(39.00, 1e-2), 'long' => num(-77.10, 1e-2)));

		my $location = $geo_coder_list->geocode('1363 Kelly Road, Coal City, Owen, Indiana, USA');
		ok(defined($location));
		cmp_deeply($location,
			methods('lat' => num(39.27, 1e-2), 'long' => num(-87.03, 1e-2)));

		$location = $geo_coder_list->geocode('Woolwich, London, England');
		cmp_deeply($location,
			methods('lat' => num(51.47, 1e-2), 'long' => num(0.20, 1e-2)));

		$location = $geo_coder_list->geocode(location => 'Margate, Kent, England');
		ok(defined($location));
		cmp_deeply($location,
			methods('lat' => num(51.38, 1e-2), 'long' => num(1.39, 1e-2)));

		# Check cache
		$location = $geo_coder_list->geocode('Woolwich, London, England');
		cmp_deeply($location,
			methods('lat' => num(51.47, 1e-2), 'long' => num(0.20, 1e-2)));

		my @locations = $geo_coder_list->geocode(location => 'Herne Bay, Kent, England');
		cmp_deeply($locations[0],
			methods('lat' => num(51.38, 1e-2), 'long' => num(1.13, 1e-2)));
	}
}
