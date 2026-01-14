#!perl -wT

# curl 'geocoder.ca/some_location?locate=9235+Main+St,+Richibucto,+New Brunswick,+Canada&json=1'

use strict;
use warnings;
use LWP;
use Test::Most tests => 17;

eval 'use autodie qw(:all)';	# Test for open/close failures

BEGIN {
	use_ok('Geo::Coder::List');
}

CANADA: {
	SKIP: {
		skip('Test requires Internet access', 16) unless(-e 't/online.enabled');

		if(!require_ok('Geo::Coder::CA')) {
			diag('Geo::Coder::CA not installed - skipping tests');
			skip('Geo::Coder::CA not installed', 15);
		} elsif(!require_ok('Test::Number::Delta')) {
			diag('Test::Number::Delta not installed - skipping tests');
			skip('Test::Number::Delta not installed', 14);
		};

		Geo::Coder::CA->import();
		Test::Number::Delta->import();

		my $geocoderlist = new_ok('Geo::Coder::List');
		my $ca = new_ok('Geo::Coder::CA');
		$geocoderlist->push($ca);

		my $ua = LWP::UserAgent->new();
		$ua->env_proxy(1);
		$geocoderlist->ua($ua);
		ok($ca->ua() eq $ua);

		my $location = $geocoderlist->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada');
		ok(defined($location));
		is(ref($location), 'HASH', 'geocode should return a reference to a HASH');
		delta_within($location->{geometry}{location}{lat}, 46.68, 1e-1);
		delta_within($location->{geometry}{location}{lng}, -64.86, 1e-1);

		sleep(2);	# Be nice to the server

		like($geocoderlist->reverse_geocode('39.00,-77.10'), qr/Bethesda/i, 'test reverse geocode');

		throws_ok( sub { $geocoderlist->geocode() }, qr/^Usage: /, 'No arguments gets usage message');
		ok(!defined($geocoderlist->geocode('')));

		$location = $geocoderlist->geocode(location => 'Allen, Maryland, USA');
		ok(!defined($location));

		if(require_ok('Test::LWP::UserAgent')) {
			Test::LWP::UserAgent->import();
		} else {
			diag('Test::LWP::UserAgent not installed - skipping tests');
			skip('Test::LWP::UserAgent not installed', 2);
		}

		$ua = new_ok('Test::LWP::UserAgent');
		$ua->map_response('geocoder.ca', new_ok('HTTP::Response' => [ '500' ]));
		$geocoderlist->ua($ua);

		# FIXME: this fails - it gets data
		# is($geocoderlist->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada'), undef, 'remote error returns undef');
		# use Data::Dumper;
		# diag(Data::Dumper->new([$location])->Dump());

		$location = $geocoderlist->geocode(location => '9235 Main St, Richibucto, New Brunswick, Canada');
	}
}
