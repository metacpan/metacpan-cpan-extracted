#!perl -w

use warnings;
use strict;
use Test::Number::Delta within => 1e-2;
use Test::Most tests => 11;

BEGIN {
	use_ok('Geo::Coder::XYZ');
}

UK: {
	SKIP: {
		skip 'Test requires Internet access', 10 unless(-e 't/online.enabled');

		require Test::LWP::UserAgent;
		Test::LWP::UserAgent->import();

		require Test::Carp;
		Test::Carp->import();;

		my $geocoder = new_ok('Geo::Coder::XYZ');

		my $location = $geocoder->geocode('10 Downing St., London, UK');
		delta_ok($location->{latt}, 51.50);
		delta_ok($location->{longt}, -0.13);

		$location = $geocoder->geocode('Wokingham, Berkshire, England');
		delta_ok($location->{latt}, 51.41);
		delta_ok($location->{longt}, -0.83);

		$location = $geocoder->geocode(location => '10 Downing St., London, UK');
		delta_ok($location->{latt}, 51.50);
		delta_ok($location->{longt}, -0.13);

		my $address = $geocoder->reverse_geocode(latlng => '51.50,-0.13');
		like($address->{'city'}, qr/^London$/i, 'test reverse');

		my $ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('geocode.xyz', new_ok('HTTP::Response' => [ '500' ]));

		$geocoder->ua($ua);
		eval {
			does_carp_that_matches(sub { 
				$location = $geocoder->geocode('10 Downing St., London, UK');
			}, qr/^geocode.xyz API returned error: 500/);
		};
	}
}
