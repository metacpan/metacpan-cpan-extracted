#!perl -w

use warnings;
use strict;
use Test::LWP::UserAgent;
use Test::Number::Delta within => 1e-2;
use Test::Most tests => 14;
use Test::Carp;

BEGIN {
	use_ok('Geo::Coder::CA');
}

US: {
	SKIP: {
		if(!-e 't/online.enabled') {
			if(!$ENV{RELEASE_TESTING}) {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 13);
			} else {
				diag('Test requires Internet access');
				skip('Test requires Internet access', 13);
			}
		}

		my $geocoder = new_ok('Geo::Coder::CA');
		my $location = $geocoder->geocode('1600 Pennsylvania Avenue NW, Washington DC');
		delta_ok($location->{latt}, 38.90);
		delta_ok($location->{longt}, -77.04);

		$location = $geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');
		delta_ok($location->{latt}, 38.90);
		delta_ok($location->{longt}, -77.04);

		$location = $geocoder->geocode(location => 'Greene County, Indiana, USA');
		ok(defined($location));
		delta_ok($location->{latt}, 39.04);
		delta_ok($location->{longt}, -86.96);

		# $location = $geocoder->geocode(location => 'Greene, Indiana, USA');
		# ok(defined($location));
		# delta_ok($location->{latt}, 39.04);
		# delta_ok($location->{longt}, -86.96);

		$location = $geocoder->geocode(location => 'XYZZY');
		ok(!defined($location));

		my $address = $geocoder->reverse_geocode('38.9,-77.04');
		is($address->{'prov'}, 'DC', 'test reverse');

		my $ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('geocoder.ca', new_ok('HTTP::Response' => [ '500' ]));

		$geocoder->ua($ua);

		sub f {
			$location = $geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');
		}
		does_croak_that_matches(\&f, qr/ API returned error: 500/);
	}
}
