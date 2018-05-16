#!perl -w

use warnings;
use strict;
use Test::Most tests => 72;
use Test::Number::Delta;
use Test::Carp;
use lib 't/lib';
use MyLogger;

BEGIN {
	use_ok('Geo::Coder::Free');
}

LOOKUP: {
	diag('This may take some time and consume a lot of memory if the database is not SQLite');

	Geo::Coder::Free::DB::init(logger => new_ok('MyLogger'));

	my $geocoder = new_ok('Geo::Coder::Free');

	my $location = $geocoder->geocode('Woolwich, London, England');
	ok(defined($location));
	delta_within($location->{latitude}, 51.47, 1e-2);
	delta_within($location->{longitude}, 0.20, 1e-2);

	TODO: {
		local $TODO = "Don't know how to parse 'London, England'";

		eval {
			$location = $geocoder->geocode('London, England');
			ok(defined($location));
		};
	}

	$location = $geocoder->geocode('Lambeth, London, England');
	ok(defined($location));
	delta_within($location->{latitude}, 51.49, 1e-2);
	delta_within($location->{longitude}, -0.12, 1e-2);

	$location = $geocoder->geocode('Indianapolis, Indiana, USA');
	ok(defined($location));
	delta_within($location->{latitude}, 39.77, 1e-2);
	delta_within($location->{longitude}, -86.16, 1e-2);

	$location = $geocoder->geocode('Ramsgate, Kent, England');
	ok(defined($location));
	delta_within($location->{latitude}, 51.33, 1e-2);
	delta_within($location->{longitude}, 1.43, 1e-2);

	$location = $geocoder->geocode('Wokingham, Berkshire, United Kingdom');
	ok(defined($location));
	delta_within($location->{latitude}, 51.42, 1e-2);
	delta_within($location->{longitude}, -0.84, 1e-2);

	$location = $geocoder->geocode('Wokingham, Berkshire, UK');
	ok(defined($location));
	delta_within($location->{latitude}, 51.42, 1e-2);
	delta_within($location->{longitude}, -0.84, 1e-2);

	$location = $geocoder->geocode('Wokingham, Berkshire, GB');
	ok(defined($location));
	delta_within($location->{latitude}, 51.42, 1e-2);
	delta_within($location->{longitude}, -0.84, 1e-2);

	$location = $geocoder->geocode('Wokingham, Berkshire, England');
	ok(defined($location));
	delta_within($location->{latitude}, 51.42, 1e-2);
	delta_within($location->{longitude}, -0.84, 1e-2);

	# FIXME: This finds the Wokingham in England because of a problem in the unitary city handling
	# which actually looks for Wokingham, GB.

	# $location = $geocoder->geocode('Wokingham, Berkshire, Scotland');
	# ok(!defined($location));

	$location = $geocoder->geocode('Minster, Thanet, Kent, England');
	TODO: {
		local $TODO = 'Minster, Thanet not yet supported';

		ok(!defined($location));
	}

	$location = $geocoder->geocode('Silver Spring, Maryland, USA');
	ok(defined($location));
	delta_within($location->{latitude}, 38.99, 1e-2);
	delta_within($location->{longitude}, -77.03, 1e-2);

	$location = $geocoder->geocode('Silver Spring, MD, USA');
	ok(defined($location));
	delta_within($location->{latitude}, 38.99, 1e-2);
	delta_within($location->{longitude}, -77.03, 1e-2);

	$location = $geocoder->geocode('Silver Spring, Montgomery, MD, USA');
	ok(defined($location));
	delta_within($location->{latitude}, 38.99, 1e-2);
	delta_within($location->{longitude}, -77.03, 1e-2);

	$location = $geocoder->geocode('Silver Spring, Maryland, United States');
	ok(defined($location));
	delta_within($location->{latitude}, 38.99, 1e-2);
	delta_within($location->{longitude}, -77.03, 1e-2);

	$location = $geocoder->geocode('Silver Spring, Montgomery County, Maryland, USA');
	ok(defined($location));
	delta_within($location->{latitude}, 38.99, 1e-2);
	delta_within($location->{longitude}, -77.03, 1e-2);

	$location = $geocoder->geocode('Montgomery County, Maryland, USA');
	ok(!defined($location));

	$location = $geocoder->geocode('St Nicholas-at-Wade, Kent, UK');
	ok(defined($location));
	delta_within($location->{latitude}, 51.35, 1e-2);
	delta_within($location->{longitude}, 1.25, 1e-2);

	$location = $geocoder->geocode('Rockville Pike, Rockville, Montgomery County, MD, USA');
	TODO: {
		local $TODO = "Don't know how to parse counties in the USA";
		ok(!defined($location));
	}

	# FIXME:  this actually does a look up that fails
	$location = $geocoder->geocode('Rockville Pike, Rockville, MD, USA');
	ok(!defined($location));

	$location = $geocoder->geocode({ location => 'Rockville, Montgomery County, MD, USA' });
	ok(defined($location));
	delta_within($location->{latitude}, 39.08, 1e-2);
	delta_within($location->{longitude}, -77.15, 1e-2);

	$location = $geocoder->geocode(location => 'Rockville, Montgomery County, Maryland, USA');
	ok(defined($location));
	delta_within($location->{latitude}, 39.08, 1e-2);
	delta_within($location->{longitude}, -77.15, 1e-2);

	$location = $geocoder->geocode(location => 'Temple Ewell, Kent, England');
	ok(defined($location));
	delta_within($location->{latitude}, 51.15, 1e-2);
	delta_within($location->{longitude}, 1.27, 1e-2);

	$location = $geocoder->geocode(location => 'Edmonton, Alberta, Canada');
	ok(defined($location));
	delta_within($location->{latitude}, 53.55, 1e-2);
	delta_within($location->{longitude}, -113.5, 1e-2);

	my @locations = $geocoder->geocode(location => 'Temple Ewell, Kent, England');
	ok(defined($locations[0]));
	delta_within($locations[0]->{latitude}, 51.15, 1e-2);
	delta_within($locations[0]->{longitude}, 1.27, 1e-2);

	$location = $geocoder->geocode(location => 'Newport Pagnell, Buckinghamshire, England');
	ok(defined($location));
	delta_within($location->{latitude}, 52.08, 1e-2);
	delta_within($location->{longitude}, -0.72, 1e-2);

	$location = $geocoder->geocode('Thanet, Kent, England');
	ok(defined($location));

	$location = $geocoder->geocode('Vessels, Misc Ships At sea or abroad, England');
	ok(!defined($location));

	# my $address = $geocoder->reverse_geocode(latlng => '51.50,-0.13');
	# like($address->{'city'}, qr/^London$/i, 'test reverse');

	does_croak(sub {
		$location = $geocoder->geocode();
	});

	does_croak(sub {
		$location = $geocoder->reverse_geocode();
	});
}
