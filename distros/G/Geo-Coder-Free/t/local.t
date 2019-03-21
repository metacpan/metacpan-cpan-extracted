#!perl -wT

use warnings;
use strict;
use Test::Most tests => 10;
use Test::Number::Delta;
use Test::Carp;
use Test::Deep;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Geo::Coder::Free::Local');
}

LOCAL: {
	my $geo_coder = new_ok('Geo::Coder::Free::Local');

	cmp_deeply($geo_coder->geocode('NCBI, MEDLARS DR, BETHESDA, MONTGOMERY, MD, USA'),
		methods('lat' => num(39.00, 1e-2), 'long' => num(-77.10, 1e-2)));

	cmp_deeply($geo_coder->geocode(location => 'NCBI, MEDLARS DR, BETHESDA, MONTGOMERY, MD, USA'),
		methods('lat' => num(39.00, 1e-2), 'long' => num(-77.10, 1e-2)));

	cmp_deeply($geo_coder->geocode({ location => 'NCBI, MEDLARS DR, BETHESDA, MONTGOMERY, MD, USA' }),
		methods('lat' => num(39.00, 1e-2), 'long' => num(-77.10, 1e-2)));

	TODO: {
		local $TODO = "Can't parse this yet";
		my $location = $geo_coder->geocode('St Mary the Virgin Church, Minster, Thanet, Kent, England');
		ok(defined($location));

		$location = $geo_coder->geocode('St Mary the Virgin Church, Church St, Minster, Thanet, Kent, England');
		ok(defined($location));
		# delta_within($location->{latitude}, 39.00, 1e-2);
		# delta_within($location->{longitude}, -77.10, 1e-2);
	}

	cmp_deeply($geo_coder->geocode('106 Tothill St, Minster, Thanet, Kent, England'),
		methods('lat' => num(51.34, 1e-2), 'long' => num(1.32, 1e-2)));

	cmp_deeply($geo_coder->geocode(location => '106 Tothill St, Minster, Thanet, Kent, England'),
		methods('lat' => num(51.34, 1e-2), 'long' => num(1.32, 1e-2)));

	cmp_deeply($geo_coder->geocode({ location => '106 Tothill St, Minster, Thanet, Kent, England' }),
		methods('lat' => num(51.34, 1e-2), 'long' => num(1.32, 1e-2)));
}
