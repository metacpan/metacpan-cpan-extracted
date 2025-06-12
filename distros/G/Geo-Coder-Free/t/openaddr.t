#!perl -w

use warnings;
use strict;

use Test::Carp;
use Test::Deep;
use Test::DescribeMe qw(extended);	# This can use a lot of resources
use Test::Most;
use Test::Number::Delta;

use lib 't/lib';
use MyLogger;
# use Test::Without::Module qw(Geo::libpostal);

BEGIN { use_ok('Geo::Coder::Free') }

OPENADDR: {
	if($ENV{'OPENADDR_HOME'}) {
		if($ENV{'TEST_VERBOSE'}) {
			Database::Abstraction::init(logger => MyLogger->new());
		}

		my $geo_coder = new_ok('Geo::Coder::Free' => [ openaddr => $ENV{'OPENADDR_HOME'} ]);

		diag('This will take some time and memory');

		my $location = $geo_coder->geocode('Medlars Drive, Bethesda, MD, USA');
		ok(defined($location), 'Medlars Drive, Bethesda, MD, USA');
		diag(Data::Dumper->new([$location])->Dump()) if($ENV{'TEST_VERBOSE'});
		cmp_deeply($location,
			methods('lat' => num(39.00, 1e-2), 'long' => num(-77.10, 1e-2)));

		$location = $geo_coder->geocode('Indiana, USA');
		cmp_deeply($location,
			methods('lat' => num(39.5, 1), 'long' => num(-86, 1)));

		$location = $geo_coder->geocode('Indianapolis, Indiana, USA');
		ok(defined($location));
		cmp_deeply($location,
			methods('lat' => num(39.71, 1e-1), 'long' => num(-86.2, 1e-1)));

		# $location = $geo_coder->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada');
		# delta_ok($location->{latt}, 46.67);
		# delta_ok($location->{longt}, -64.87);

		TODO: {
			local $TODO = 'Not in the database';

			eval {
				$location = $geo_coder->geocode({ location => 'Osceola, Polk, Nebraska, USA' });
				ok(defined($location));
			};
		}

		if($ENV{'WHOSONFIRST_HOME'}) {
			$location = $geo_coder->geocode(location => '6502 SW. 102nd Avenue, Bushnell, Florida, USA');
			ok(defined($location));
			cmp_deeply($location,
				methods('lat' => num(28.61, 1e-2), 'long' => num(-82.21, 1e-2)));
		}

		# This place does exist, but isn't in Openaddresses
		my $o_geo_coder = new_ok('Geo::Coder::Free::OpenAddresses' => [ openaddr => $ENV{'OPENADDR_HOME'} ]);
		TODO: {
			local $TODO = "Not in the database";

			eval {
				$location = $o_geo_coder->geocode('105 S. West Street, Spencer, Owen, Indiana, USA');
				ok(defined($location));
			};
		}

		$location = $geo_coder->geocode(location => 'Greene, Indiana, USA');
		ok(defined($location));
		diag(Data::Dumper->new([$location])->Dump()) if($ENV{'TEST_VERBOSE'});
		cmp_deeply($location,
			methods('lat' => num(40, 1), 'long' => num(-86, 2)));

		$location = $o_geo_coder->geocode('Boswell, Somerset, Pennsylvania, USA');
		ok(defined($location));

		# $location = $geo_coder->geocode({location => 'Westmorland, New Brunswick, Canada'});
		# ok(defined($location));

		$location = $geo_coder->geocode({location => 'Harrison Mills, British Columbia, Canada'});
		ok(defined($location));

		# Clay township isn't in Openaddresses
		$location = $o_geo_coder->geocode(location => 'Clay City, Owen, Indiana, USA');
		ok(defined($location));

		$location = $geo_coder->geocode(location => 'Edmonton, Alberta, Canada');
		ok(defined($location));
		cmp_deeply($location,
			methods('lat' => num(53.5, 1e-1), 'long' => num(-113.4, 1)));

		$location = $geo_coder->geocode('London, England');
		TODO: {
			local $TODO = "Can't parse 'London, England'";

			ok(!defined($location));
		}


		$location = $geo_coder->geocode('Silver Spring, Maryland, USA');
		cmp_deeply($location,
			methods('lat' => num(39, 1), 'long' => num(-77.02, 1e-2)));

		$location = $geo_coder->geocode('Silver Spring, MD, USA');
		cmp_deeply($location,
			methods('lat' => num(39, 1), 'long' => num(-77.02, 1e-2)));

		$location = $geo_coder->geocode('Silver Spring, Montgomery, MD, USA');
		cmp_deeply($location,
			methods('lat' => num(39, 1), 'long' => num(-77.02, 1e-2)));

		$location = $geo_coder->geocode('Silver Spring, Maryland, United States');
		cmp_deeply($location,
			methods('lat' => num(39, 1), 'long' => num(-77.02, 1e-2)));

		$location = $geo_coder->geocode('Silver Spring, Montgomery County, Maryland, USA');
		cmp_deeply($location,
			methods('lat' => num(39, 1), 'long' => num(-77.02, 1e-2)));

		if($ENV{'WHOSONFIRST_HOME'}) {
			$location = $geo_coder->geocode('Rockville Pike, Rockville, Montgomery County, MD, USA');
			cmp_deeply($location,
				methods('lat' => num(39.07, 1e-2), 'long' => num(-77.13, 1e-1)));

			$location = $geo_coder->geocode('Rockville Pike, Rockville, MD, USA');
			ok(defined($location));
			cmp_deeply($location,
				methods('lat' => num(39.07, 1e-1), 'long' => num(-77.13, 1e-2)));

			$location = $geo_coder->geocode('8600 Rockville Pike, Bethesda, MD 20894, USA');
			cmp_deeply($location,
				methods('lat' => num(39.00, 1e-1), 'long' => num(-77.10, 1e-2)));

			$location = $geo_coder->geocode('8600 Rockville Pike Bethesda MD 20894 USA');
			cmp_deeply($location,
				methods('lat' => num(39.00, 1e-1), 'long' => num(-77.10, 1e-2)));
		}

		$location = $geo_coder->geocode({ location => 'Rockville, Montgomery County, MD, USA' });
		cmp_deeply($location,
			methods('lat' => num(39, 1), 'long' => num(-77, 1)));

		$location = $geo_coder->geocode(location => 'Rockville, Montgomery County, Maryland, USA');
		cmp_deeply($location,
			methods('lat' => num(39, 1), 'long' => num(-77, 1)));

		if($ENV{'WHOSONFIRST_HOME'}) {
			$location = $geo_coder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');
			cmp_deeply($location,
				methods('lat' => num(38.90, 1e-2), 'long' => num(-77.04, 1e-2)));
		}

		$location = $geo_coder->geocode('Wisconsin, USA');
		cmp_deeply($location,
			methods('lat' => num(44, 1), 'long' => num(-90, 1)));

		$location = $geo_coder->geocode('At sea or abroad');
		ok(!defined($location));

		$location = $o_geo_coder->geocode('Vessels, Misc Ships At sea or abroad, England');
		# ok((!defined($location)) || ($location eq ''));
		ok(!defined($location));

		$location = $geo_coder->geocode({ location => 'St. Louis, Missouri, USA' });
		cmp_deeply($location,
			methods('lat' => num(38.63, 1e-2), 'long' => num(-90.20, 1e-1)));

		$location = $geo_coder->geocode({ location => 'St Louis, Missouri, USA' });
		cmp_deeply($location,
			methods('lat' => num(38.63, 1e-2), 'long' => num(-90.20, 1e-1)));

		$location = $geo_coder->geocode({ location => 'Saint Louis, Missouri, USA' });
		cmp_deeply($location,
			methods('lat' => num(38.63, 1e-2), 'long' => num(-90.2, 1e-1)));

		if($ENV{'WHOSONFIRST_HOME'}) {
			$location = $geo_coder->geocode('716 Yates Street, Victoria, British Columbia, Canada');
			cmp_deeply($location,
				methods('lat' => num(48.43, 1e-2), 'long' => num(-123.37, 1e-2)));
		}

		$location = $geo_coder->geocode(location => 'Caboolture, Queensland, Australia');
		ok(defined($location));
		cmp_deeply($location,
			methods('lat' => num(-27.0, 1e-1), 'long' => num(152.9, 1e-1)));

		$location = $geo_coder->geocode(location => 'Whitley, Indiana, USA');
		ok(defined($location));
		ok(ref($location) eq 'Geo::Location::Point');

		# RT#127140
		# $location = $geo_coder->geocode({ location => '131 107th St, Manhattan, New York, New York, USA' });
		# ok(defined($location));
		# ok(ref($location) eq 'HASH');

		# my $address = $geo_coder->reverse_geocode(latlng => '51.50,-0.13');
		# like($address->{'city'}, qr/^London$/i, 'test reverse');

		does_croak(sub {
			$location = $geo_coder->geocode();
		});

		does_croak(sub {
			$location = $geo_coder->reverse_geocode();
		});

		does_croak(sub {
			# This breaks does_croak
			# $geo_coder = new_ok('Geo::Coder::Free' => [ openaddr => 'not/there' ]);
			$geo_coder = Geo::Coder::Free->new(openaddr => 'not/there');
		});

		eval 'use Test::Memory::Cycle';
		if(!$@) {
			memory_cycle_ok($geo_coder);
		}
	} else {
		diag('Set OPENADDR_HOME to enable openaddresses.io testing');
	}
	done_testing();
}
