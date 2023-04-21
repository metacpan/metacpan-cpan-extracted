#!perl -wT

use warnings;
use strict;
use Test::Number::Delta within => 1e-2;
use Test::Most tests => 16;
use Test::Carp;

BEGIN {
	use_ok('Geo::Coder::CA');
}

US: {
	SKIP: {
		if(-e 't/online.enabled') {
			use_ok('Test::LWP::UserAgent');
		} else {
			diag('On-line tests have been disabled');
			skip('On-line tests have been disabled', 15);
		}

		my $geocoder = new_ok('Geo::Coder::CA');
		my $location = $geocoder->geocode('1600 Pennsylvania Avenue NW, Washington DC');
		delta_ok($location->{latt}, 38.90);
		delta_ok($location->{longt}, -77.04);

		sleep(1);	# Don't overload the server

		$location = $geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');
		delta_ok($location->{latt}, 38.90);
		delta_ok($location->{longt}, -77.04);

		TODO: {
			# Test counties
			local $TODO = "geocoder.ca doesn't support counties";

			sleep(1);	# Don't overload the server

			if($location = $geocoder->geocode(location => 'Greene County, Indiana, USA')) {
				# delta_ok($location->{latt}, 39.04);
				# delta_ok($location->{longt}, -86.98);
				pass('Counties unexpectedly pass Lat');
				pass('Counties unexpectedly pass Long');
			} else {
				fail('Counties Lat');
				fail('Counties Long');
			}

			sleep(1);	# Don't overload the server

			if($location = $geocoder->geocode(location => 'Greene, Indiana, USA')) {
				# delta_ok($location->{latt}, 39.04);
				# delta_ok($location->{longt}, -86.96);
				pass('Counties unexpectedly pass Lat');
				pass('Counties unexpectedly pass Long');
			} else {
				fail('Counties Lat');
				fail('Counties Long');
			}
		}

		$location = $geocoder->geocode(location => 'XYZZY');
		ok(!defined($location));

		my $address = $geocoder->reverse_geocode('38.9,-77.04');
		is($address->{'prov'}, 'DC', 'test reverse');
		diag(Data::Dumper->new([$address])->Dump()) if($ENV{'TEST_VERBOSE'});

		# Check API errors are correctly handled
		my $ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('geocoder.ca', new_ok('HTTP::Response' => [ '500' ]));

		$geocoder->ua($ua);

		# See https://github.com/nigelhorne/Geo-Coder-CA/issues/61
		# Can't debug until https://rt.cpan.org/Ticket/Display.html?id=146779 is fixed
		# does_carp_that_matches(sub {
			# $location = $geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA')
		# }, qr/ API returned error: 500/);

		does_carp(sub {
			$location = $geocoder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA')
		});

		# diag(Data::Dumper->new([$location])->Dump());
	}
}
