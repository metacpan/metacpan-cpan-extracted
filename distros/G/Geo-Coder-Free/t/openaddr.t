#!perl -wT

use warnings;
use strict;
use Test::Most tests => 100;
use Test::Number::Delta;
use Test::Carp;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Geo::Coder::Free');
}

OPENADDR: {
	SKIP: {
		if($ENV{'OPENADDR_HOME'}) {
			Geo::Coder::Free::DB::init(logger => new_ok('MyLogger'));

			my $geo_coder = new_ok('Geo::Coder::Free' => [ openaddr => $ENV{'OPENADDR_HOME'} ]);

			if($ENV{AUTHOR_TESTING}) {
				diag('This will take some time and memory');

				my $location = $geo_coder->geocode('Medlars Drive, Bethesda, MD, USA');
				ok(defined($location));
				delta_within($location->{latitude}, 39.00, 1e-2);
				delta_within($location->{longitude}, -77.10, 1e-2);

				$location = $geo_coder->geocode('Indiana, USA');
				ok(defined($location));
				delta_within($location->{latitude}, 40.07, 1e-2);
				delta_within($location->{longitude}, -86.27, 1e-2);

				$location = $geo_coder->geocode('Indianapolis, Indiana, USA');
				ok(defined($location));
				if($ENV{'WHOSONFIRST_HOME'}) {
					delta_within($location->{latitude}, 39, 1);
					delta_within($location->{longitude}, -86.1, 1e-1);
				} else {
					delta_within($location->{latitude}, 39.81, 1e-2);
					delta_within($location->{longitude}, -86.10, 1e-2);
				}

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

				$location = $geo_coder->geocode('1363 Kelly Road, Coal City, Owen, Indiana, USA');
				delta_within($location->{latitude}, 39.27, 1e-2);
				delta_within($location->{longitude}, -87.03, 1e-2);

				$location = $geo_coder->geocode(location => '6502 SW. 102nd Avenue, Bushnell, Florida, USA');
				delta_within($location->{latitude}, 28.61, 1e-2);
				delta_within($location->{longitude}, -82.21, 1e-2);

				# This place does exist, but isn't in Openaddresses
				my $ogeocoder = new_ok('Geo::Coder::Free::OpenAddresses' => [ openaddr => $ENV{'OPENADDR_HOME'} ]);
				TODO: {
					local $TODO = "Not in the database";

					eval {
						$location = $ogeocoder->geocode('105 S. West Street, Spencer, Owen, Indiana, USA');
						ok(defined($location));
					};
				}

				$location = $geo_coder->geocode(location => 'Greene County, Indiana, USA');
				ok(defined($location));
				ok(ref($location) eq 'HASH');

				delta_within($location->{latitude}, 39.05, 1e-2);
				delta_within($location->{longitude}, -87.04, 1e-2);

				$location = $ogeocoder->geocode('Boswell, Somerset, Pennsylvania, USA');
				ok(defined($location));
				ok(ref($location) eq 'HASH');

				$location = $ogeocoder->geocode('106 Wells Street, Fort Wayne, Allen, Indiana, USA');
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				delta_within($location->{latitude}, 41.09, 1e-2);
				delta_within($location->{longitude}, -85.14, 1e-2);

				$location = $geo_coder->geocode({location => 'Harrison Mills, British Columbia, Canada'});
				ok(defined($location));
				ok(ref($location) eq 'HASH');

				$location = $geo_coder->geocode({location => 'Westmorland, New Brunswick, Canada'});
				ok(defined($location));
				ok(ref($location) eq 'HASH');

				# Clay township isn't in Openaddresses
				$location = $ogeocoder->geocode(location => 'Clay City, Owen, Indiana, USA');
				ok(defined($location));
				ok(ref($location) eq 'HASH');

				$location = $geo_coder->geocode(location => 'Edmonton, Alberta, Canada');
				ok(defined($location));
				if($ENV{'WHOSONFIRST_HOME'}) {
					delta_within($location->{latitude}, 53, 1);
					delta_within($location->{longitude}, -113, 1);
				} else {
					delta_within($location->{latitude}, 53.55, 1e-2);
					delta_within($location->{longitude}, -113.53, 1e-2);
				}

				$location = $geo_coder->geocode('London, England');
				TODO: {
					local $TODO = "Can't parse 'London, England'";

					ok(!defined($location));
				}


				$location = $geo_coder->geocode('Silver Spring, Maryland, USA');
				ok(defined($location));
				delta_within($location->{latitude}, 39, 1);
				delta_within($location->{longitude}, -77.02, 1e-2);

				$location = $geo_coder->geocode('Silver Spring, MD, USA');
				ok(defined($location));
				delta_within($location->{latitude}, 39, 1);
				delta_within($location->{longitude}, -77.02, 1e-2);

				$location = $geo_coder->geocode('Silver Spring, Montgomery, MD, USA');
				ok(defined($location));
				delta_within($location->{latitude}, 39, 1);
				delta_within($location->{longitude}, -77.02, 1e-2);

				$location = $geo_coder->geocode('Silver Spring, Maryland, United States');
				ok(defined($location));
				delta_within($location->{latitude}, 39, 1);
				delta_within($location->{longitude}, -77.02, 1e-2);

				$location = $geo_coder->geocode('Silver Spring, Montgomery County, Maryland, USA');
				ok(defined($location));
				delta_within($location->{latitude}, 39.0, 1e-1);
				delta_within($location->{longitude}, -77.02, 1e-2);

				$location = $geo_coder->geocode('Rockville Pike, Rockville, Montgomery County, MD, USA');
				ok(defined($location));
				delta_within($location->{latitude}, 39.07, 1e-2);
				delta_within($location->{longitude}, -77.13, 1e-2);

				$location = $geo_coder->geocode('Rockville Pike, Rockville, MD, USA');
				ok(defined($location));
				delta_within($location->{latitude}, 39.07, 1e-2);
				delta_within($location->{longitude}, -77.13, 1e-2);

				$location = $geo_coder->geocode('8600 Rockville Pike, Bethesda, MD 20894, USA');
				ok(defined($location));
				delta_within($location->{latitude}, 39.00, 1e-2);
				delta_within($location->{longitude}, -77.10, 1e-2);

				$location = $geo_coder->geocode('8600 Rockville Pike Bethesda MD 20894 USA');
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				delta_within($location->{latitude}, 39.00, 1e-2);
				delta_within($location->{longitude}, -77.10, 1e-2);

				$location = $geo_coder->geocode({ location => 'Rockville, Montgomery County, MD, USA' });
				ok(defined($location));
				delta_within($location->{latitude}, 39, 1e-1);
				delta_within($location->{longitude}, -77, 1);

				$location = $geo_coder->geocode(location => 'Rockville, Montgomery County, Maryland, USA');
				ok(defined($location));
				delta_within($location->{latitude}, 39, 1);
				delta_within($location->{longitude}, -77, 1);

				$location = $geo_coder->geocode(location => '1600 Pennsylvania Avenue NW, Washington DC, USA');
				delta_within($location->{latitude}, 38.90, 1e-2);
				delta_within($location->{longitude}, -77.04, 1e-2);

				$location = $geo_coder->geocode('548 4th Street, San Francisco, CA, USA');
				delta_within($location->{latitude}, 37.778907, 1e-2);
				delta_within($location->{longitude}, -122.39760, 1e-2);

				$location = $geo_coder->geocode('Wisconsin, USA');
				delta_within($location->{latitude}, 44.19, 1e-2);
				delta_within($location->{longitude}, -89.57, 1e-2);

				$location = $geo_coder->geocode('At sea or abroad');
				ok(!defined($location));

				$location = $ogeocoder->geocode('Vessels, Misc Ships At sea or abroad, England');
				# ok((!defined($location)) || ($location eq ''));
				ok(!defined($location));

				$location = $geo_coder->geocode({ location => 'St. Louis, Missouri, USA' });
				ok(defined($location));
				delta_within($location->{latitude}, 38.63, 1e-2);
				delta_within($location->{longitude}, -90, 1);

				$location = $geo_coder->geocode({ location => 'St Louis, Missouri, USA' });
				delta_within($location->{latitude}, 38.63, 1e-2);
				delta_within($location->{longitude}, -90.2, 1e-1);

				$location = $geo_coder->geocode({ location => 'Saint Louis, Missouri, USA' });
				delta_within($location->{latitude}, 38.64, 1e-2);
				delta_within($location->{longitude}, -90.44, 1e-2);

				$location = $geo_coder->geocode('716 Yates Street, Victoria, British Columbia, Canada');
				ok(defined($location));
				ok(ref($location) eq 'HASH');
				delta_within($location->{latitude}, 48.43, 1e-2);
				delta_within($location->{longitude}, -123.36, 1e-2);

				$location = $geo_coder->geocode(location => 'Caboolture, Queensland, Australia');
				delta_within($location->{latitude}, -27.09, 1e-2);
				delta_within($location->{longitude}, 152.96, 1e-2);

				$location = $geo_coder->geocode(location => 'Whitley, Indiana, USA');
				ok(defined($location));
				ok(ref($location) eq 'HASH');

				# RT#127140
				# $location = $geo_coder->geocode({ location => '131 107th St, Manhattan, New York, New York, USA' });
				# ok(defined($location));
				# ok(ref($location) eq 'HASH');

			} else {
				diag('Author tests not required for installation');
				skip('Author tests not required for installation', 97);
			}

			# my $address = $geo_coder->reverse_geocode(latlng => '51.50,-0.13');
			# like($address->{'city'}, qr/^London$/i, 'test reverse');

			my $location;
			does_croak(sub {
				$location = $geo_coder->geocode();
			});

			does_croak(sub {
				$location = $geo_coder->reverse_geocode();
			});

			does_carp(sub {
				$geo_coder = new_ok('Geo::Coder::Free' => [ openaddr => 'not/there' ]);
			});
		} else {
			diag('Set OPENADDR_HOME to enable openaddresses.io testing');
			skip('Set OPENADDR_HOME to enable openaddresses.io testing', 99);
		}
	}
}
