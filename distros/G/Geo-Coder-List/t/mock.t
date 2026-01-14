#!/usr/bin/env perl

# Tests which do not need the Internet

use strict;
use warnings;

use Test::Mockingbird;
use Test::Most;
use Test::Needs 'Geo::Coder::Bing', 'Geo::Coder::OSM';

BEGIN { use_ok('Geo::Coder::List') }

Test::Mockingbird::mock('Geo::Coder::Bing', 'geocode', sub {
	shift;	# Discard the first argument (typically $self)
	my %args = @_;
	return { lat => 40.7128, lon => -74.0060 } if $args{'location'} eq 'New York, NY';
	return;
});

Test::Mockingbird::mock('Geo::Coder::OSM', 'geocode', sub {
	shift;	# Discard the first argument (typically $self)
	my %args = @_;
	return { lat => 38.8977, lon => -77.0365 } if $args{'location'} eq '1600 Pennsylvania Ave NW, Washington, DC 20500';
	return;
});

# Create a Geo::Coder::List object with mocked geocoders
my $geocoder = Geo::Coder::List->new(
	geocoders => [
		Geo::Coder::Bing->new(key => 'fake_api_key'),
		Geo::Coder::OSM->new(),
	],
);

# Test successful geocoding
my $result = $geocoder->geocode('1600 Pennsylvania Ave NW, Washington, DC 20500');
cmp_ok($result->{'lat'}, '==', 38.8977, 'White House latitude');
cmp_ok($result->{'lon'}, '==', -77.0365);
cmp_ok(ref($result->{'geocoder'}), 'eq', 'Geo::Coder::OSM');

# Test normalization (assuming normalization is part of your geocoder's functionality)
$result = $geocoder->geocode('New York, NY');
cmp_ok($result->{'lat'}, '==', 40.7128, 'New York latitude');
cmp_ok($result->{'lon'}, '==', -74.006);
cmp_ok(ref($result->{'geocoder'}), 'eq', 'Geo::Coder::Bing');

# Test error handling
$result = $geocoder->geocode('An unknown location');
is($result, undef, 'Geocoding of unknown location returns undef');

done_testing();
