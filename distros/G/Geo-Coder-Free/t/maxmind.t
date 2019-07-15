#!perl -wT

use warnings;
use strict;
use Test::Most tests => 59;
use Test::Carp;
use Test::Deep;
use Test::Number::Delta;
use lib 't/lib';
use MyLogger;
# use Test::Without::Module qw(Geo::libpostal);

BEGIN {
	use_ok('Geo::Coder::Free');
}

MAXMIND: {
	SKIP: {
		if($ENV{AUTHOR_TESTING}) {
			delete $ENV{'OPENADDR_HOME'};
			delete $ENV{'WHOSONFIRST_HOME'};
			diag('This may take some time and consume a lot of memory if the database is not SQLite');

			Geo::Coder::Free::DB::init(logger => new_ok('MyLogger'));

			my $geo_coder = new_ok('Geo::Coder::Free::MaxMind');

			# my $location = $geo_coder->geocode('Woolwich, London, England');
			# ok(defined($location));
			# delta_within($location->{latitude}, 51.47, 1e-2);
			# delta_within($location->{longitude}, 0.20, 1e-2);
			cmp_deeply($geo_coder->geocode('Woolwich, London, England'),
				methods('lat' => num(51.47, 1e-2), 'long' => num(0.20, 1e-2)));

			TODO: {
				local $TODO = "Don't know how to parse 'London, England'";

				eval {
					my $location = $geo_coder->geocode('London, England');
					ok(defined($location));
				};
			}

			my $l = $geo_coder->geocode('Indianapolis, Indiana, USA');
			cmp_deeply($l,
				methods('lat' => num(39.77, 1e-2), 'long' => num(-86.15, 1e-2)));
			cmp_deeply($geo_coder->geocode('Ramsgate, Kent, England'),
				methods('lat' => num(51.33, 1e-2), 'long' => num(1.43, 1e-2)));

			cmp_deeply($geo_coder->geocode('Wokingham, Berkshire, United Kingdom'),
				methods('lat' => num(51.42, 1e-2), 'long' => num(-0.83, 1e-2)));

			cmp_deeply($geo_coder->geocode('Wokingham, Berkshire, UK'),
				methods('lat' => num(51.42, 1e-2), 'long' => num(-0.83, 1e-2)));

			cmp_deeply($geo_coder->geocode('Wokingham, Berkshire, GB'),
				methods('lat' => num(51.42, 1e-2), 'long' => num(-0.83, 1e-2)));

			cmp_deeply($geo_coder->geocode('Wokingham, Berkshire, England'),
				methods('lat' => num(51.42, 1e-2), 'long' => num(-0.83, 1e-2)));


			# FIXME: This finds the Wokingham in England because of a problem in the unitary city handling
			# which actually looks for Wokingham, GB.

			# $location = $geo_coder->geocode('Wokingham, Berkshire, Scotland');
			# ok(!defined($location));

			TODO: {
				local $TODO = 'Minster, Thanet not yet supported';

				my $location = $geo_coder->geocode('Minster, Thanet, Kent, England');
				ok(!defined($location));
			}

			$l = $geo_coder->geocode('Silver Spring, Maryland, USA');
			cmp_deeply($l,
				methods('lat' => num(39.00, 1e-2), 'long' => num(-77.03, 1e-2)));
			check($geo_coder, 'Silver Spring, MD, USA', 38.9905556, -77.0263889);

			cmp_deeply($geo_coder->geocode('Silver Spring, MD, USA'),
				methods('lat' => num(39.00, 1e-2), 'long' => num(-77.03, 1e-2)));

			cmp_deeply($geo_coder->geocode('Silver Spring, Montgomery, MD, USA'),
				methods('lat' => num(39.00, 1e-2), 'long' => num(-77.03, 1e-2)));

			cmp_deeply($geo_coder->geocode('Silver Spring, Montgomery, MD, United States'),
				methods('lat' => num(39.00, 1e-2), 'long' => num(-77.03, 1e-2)));

			$l = $geo_coder->geocode('Silver Spring, Montgomery County, Maryland, United States');
			cmp_deeply($l,
				methods('lat' => num(39.00, 1e-2), 'long' => num(-77.03, 1e-2)));

			$l = $geo_coder->geocode('Montgomery County, Maryland, USA');
			ok(!defined($l));

			cmp_deeply($geo_coder->geocode('St Nicholas-at-Wade, Kent, UK'),
				methods('lat' => num(51.35, 1e-2), 'long' => num(1.25, 1e-2)));

			TODO: {
				local $TODO = "Don't know how to parse counties in the USA";
				my $location = $geo_coder->geocode('Rockville Pike, Rockville, Montgomery County, MD, USA');
				ok(!defined($location));
			}

			# FIXME:  this actually does a look up that fails
			my $location = $geo_coder->geocode('Rockville Pike, Rockville, MD, USA');
			ok(!defined($location));

			cmp_deeply($geo_coder->geocode('Rockville, Montgomery County, MD, USA'),
				methods('lat' => num(39.08, 1e-2), 'long' => num(-77.15, 1e-2)));

			$l = $geo_coder->geocode('Rockville, Montgomery County, Maryland, USA');
			cmp_deeply($l,
				methods('lat' => num(39.08, 1e-2), 'long' => num(-77.15, 1e-2)));

			cmp_deeply($geo_coder->geocode('Temple Ewell, Kent, England'),
				methods('lat' => num(51.15, 1e-2), 'long' => num(1.27, 1e-2)));

			like($geo_coder->reverse_geocode('51.15,1.27'), qr/Ewell,/, 'test reverse');

			# Hatteras Island
			ok(!defined($geo_coder->reverse_geocode('35.2440910277778,-75.6151199166667')));
			like($geo_coder->reverse_geocode('51.5029,-0.1197'), qr/London, GB$/, 'test reverse in London');
			like($geo_coder->reverse_geocode('51.15,1.27'), qr/Ewell,/, 'test reverse');
			like($geo_coder->reverse_geocode('39.0075611111111,-77.0476'), qr/Forest Glen/i, 'test reverse');

			$l = $geo_coder->geocode('Temple Ewell, Kent, England');
			cmp_deeply($l,
				methods('lat' => num(51.15, 1e-2), 'long' => num(1.27, 1e-2)));

			$l = $geo_coder->geocode('Edmonton, Alberta, Canada');
			cmp_deeply($l,
				methods('lat' => num(53.55, 1e-2), 'long' => num(-113.50, 1e-2)));

			my @locations = $geo_coder->geocode(location => 'Temple Ewell, Kent, England');
			ok(defined($locations[0]));
			cmp_deeply($locations[0],
				methods('lat' => num(51.15, 1e-2), 'long' => num(1.27, 1e-2)));

			$l = $geo_coder->geocode('Newport Pagnell, Buckinghamshire, England');
			ok(defined($l));
			cmp_deeply($l,
				methods('lat' => num(52.08, 1e-2), 'long' => num(-0.72, 1e-2)));

			$location = $geo_coder->geocode('Thanet, Kent, England');
			ok(defined($location));

			# The apache database is woefully out of date and has Kent in E5 rather than G5
			# diag(__LINE__);
			# $l = $geo_coder->geocode('Kent, England');
			# ok(defined($l));
			# cmp_deeply($l,
				# methods('lat' => num(51, 1), 'long' => num(0.75, 1e-2)));

			$l = $geo_coder->geocode('Maryland, USA');
			cmp_deeply($l,
				methods('lat' => num(38.25, 1e-2), 'long' => num(-76.74, 1e-2)));

			$location = $geo_coder->geocode('Nebraska, USA');
			ok(defined($location));

			$location = $geo_coder->geocode('Vessels, Misc Ships At sea or abroad, England');
			ok(!defined($location));

			# my $address = $geo_coder->reverse_geocode(latlng => '51.50,-0.13');
			# like($address->{'city'}, qr/^London$/i, 'test reverse');

			does_croak(sub {
				$location = $geo_coder->geocode();
			});

			does_croak(sub {
				$location = $geo_coder->reverse_geocode();
			});

			ok(scalar(keys %Geo::Coder::Free::MaxMind::admin1cache) > 0);
			ok(scalar(keys %Geo::Coder::Free::MaxMind::admin2cache) > 0);
		} else {
			diag('Author tests not required for installation');
			skip('Author tests not required for installation', 58);
		}
	}
}

sub check {
	my ($geo_coder, $location, $lat, $long) = @_;

	# ::diag($location);
	my @rc = $geo_coder->geocode({ location => $location });
	# diag(Data::Dumper->new([\@rc])->Dump());
	ok(scalar(@rc) > 0);
	cmp_deeply(@rc,
		methods('lat' => num($lat, 1e-2), 'long' => num($long, 1e-2)));

	@rc = $geo_coder->geocode(location => $location);
	ok(scalar(@rc) > 0);
	cmp_deeply(@rc,
		methods('lat' => num($lat, 1e-2), 'long' => num($long, 1e-2)));

	@rc = $geo_coder->geocode($location);
	ok(scalar(@rc) > 0);
	cmp_deeply(@rc,
		methods('lat' => num($lat, 1e-2), 'long' => num($long, 1e-2)));

	$location = uc($location);
	@rc = $geo_coder->reverse_geocode(lat => $lat, long => $long);
	ok(scalar(@rc) > 0);
	my $found;

	if($location =~ /(.+),\s+USA$/) {
		$location = "$1, US";
	}

	foreach my $loc(@rc) {
		if(uc($loc) eq $location) {
			$found = 1;
			last;
		}
	}

	if(!$found) {
		diag("Failed reverse lookup $location");
		diag(Data::Dumper->new([\@rc])->Dump());
	}
	ok($found);

	@rc = $geo_coder->reverse_geocode({ lat => $lat, long => $long });
	ok(scalar(@rc) > 0);
	$found = 0;

	foreach my $loc(@rc) {
		if(uc($loc) eq $location) {
			$found = 1;
			last;
		}
	}

	if(!$found) {
		diag("Failed reverse lookup $location");
		diag(Data::Dumper->new([\@rc])->Dump());
	}
	ok($found);

	@rc = $geo_coder->reverse_geocode(latlng => "$lat,$long");
	ok(scalar(@rc) > 0);
	$found = 0;

	foreach my $loc(@rc) {
		if(uc($loc) eq $location) {
			$found = 1;
			last;
		}
	}

	if(!$found) {
		diag("Failed reverse lookup $location");
		diag(Data::Dumper->new([\@rc])->Dump());
	}
	ok($found);

	@rc = $geo_coder->reverse_geocode({ latlng => "$lat,$long" });
	ok(scalar(@rc) > 0);
	$found = 0;

	foreach my $loc(@rc) {
		if(uc($loc) eq $location) {
			$found = 1;
			last;
		}
	}

	if(!$found) {
		diag("Failed reverse lookup $location");
		diag(Data::Dumper->new([\@rc])->Dump());
	}
	ok($found);

	@rc = $geo_coder->reverse_geocode("$lat,$long");
	ok(scalar(@rc) > 0);
	$found = 0;

	foreach my $loc(@rc) {
		if(uc($loc) eq $location) {
			$found = 1;
			last;
		}
	}

	if(!$found) {
		diag("Failed reverse lookup $location");
		diag(Data::Dumper->new([\@rc])->Dump());
	}
	ok($found);
}
