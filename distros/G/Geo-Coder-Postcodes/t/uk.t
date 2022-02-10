#!perl -w

use warnings;
use strict;
use Test::Most tests => 43;

BEGIN {
	use_ok('Geo::Coder::Postcodes');
}

UK: {
	SKIP: {
		if(!-e 't/online.enabled') {
			diag('Online tests disabled');
			skip('Online tests disabled', 42);
		}

		require_ok('Test::LWP::UserAgent');
		Test::LWP::UserAgent->import();

		require_ok('Test::Carp');
		Test::Carp->import();

		eval {
			require_ok('Test::Number::Delta');

			Test::Number::Delta->import();
		};

		if($@) {
			diag('Test::Number::Delta not installed - skipping tests');
			skip('Test::Number::Delta not installed', 34);
		}

		my $geocoder = new_ok('Geo::Coder::Postcodes');

		my $location = $geocoder->geocode('Ramsgate');
		delta_within($location->{latitude}, 51.33, 1e-2);
		delta_within($location->{longitude}, 1.42, 1e-2);
		sleep(1);	# avoid being blacklisted

		$location = $geocoder->geocode('Ramsgate, Kent, England');
		delta_within($location->{latitude}, 51.33, 1e-2);
		delta_within($location->{longitude}, 1.42, 1e-2);
		sleep(1);	# avoid being blacklisted

		# Check we don't get the one in Surrey
		$location = $geocoder->geocode(location => 'Ashford, Kent, England');
		delta_within($location->{latitude}, 51.15, 1e-2);
		delta_within($location->{longitude}, 0.87, 1e-2);
		ok($location->{'county_unitary'} eq 'Kent');
		sleep(1);	# avoid being blacklisted

		# Check we don't get the one in Surrey
		ok(!defined($geocoder->geocode(location => 'Ashford, Yorkshire, England')));
		sleep(1);	# avoid being blacklisted

		$location = $geocoder->geocode('Plumstead, London, England');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{latitude}, 51.48, 1e-2);
		delta_within($location->{longitude}, 0.08, 1e-2);
		sleep(1);	# avoid being blacklisted

		$location = $geocoder->geocode('South Bersted, Sussex, England');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{latitude}, 50.79, 1e-2);
		delta_within($location->{longitude}, -0.67, 1e-2);
		sleep(1);	# avoid being blacklisted

		$location = $geocoder->geocode('Bolton-upon-Dearne, South Yorkshire, England');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{latitude}, 53.52, 1e-2);
		delta_within($location->{longitude}, -1.31, 1e-2);

		$location = $geocoder->geocode('Southend-on-Sea, Essex, England');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{latitude}, 51.54, 1e-2);
		delta_within($location->{longitude}, 0.71, 1e-2);

		my $ua = new_ok('LWP::UserAgent');
		$ua->default_header(accept_encoding => 'gzip,deflate');
		my $geocoder2 = new_ok('Geo::Coder::Postcodes' => [ ua => $ua ]);
		$location = $geocoder2->geocode('Brentford, London, England');
		ok(defined($location));
		ok(ref($location) eq 'HASH');
		delta_within($location->{latitude}, 51.49, 1e-2);
		delta_within($location->{longitude}, -0.31, 1e-2);

		does_croak_that_matches(sub {
			$location = $geocoder->geocode('Windsor Castle, Windsor, Berkshire, England');
		}, qr/^Postcodes.io only supports towns/);
		sleep(1);	# avoid being blacklisted

		does_croak_that_matches(sub {
			$location = $geocoder->geocode();
		}, qr/^Usage: /);
		sleep(1);	# avoid being blacklisted

		does_croak_that_matches(sub {
			$location = $geocoder->reverse_geocode();
		}, qr/^Usage: /);
		sleep(1);	# avoid being blacklisted

		my $address = $geocoder->reverse_geocode(latlng => '51.33,1.42');
		like($address->{'parish'}, qr/Ramsgate/i, 'test reverse city');
		sleep(1);	# avoid being blacklisted

		$ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('api.postcodes.io', new_ok('HTTP::Response' => [ '500' ]));

		$geocoder->ua($ua);
		does_croak_that_matches(sub {
			$location = $geocoder->geocode('Sheffield');
		}, qr/^postcodes.io API returned error: /);

		ok(ref($geocoder->ua) eq 'Test::LWP::UserAgent');
	}
}
