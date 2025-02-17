#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::MockObject;
use HTML::OSM;

# Mock the geocoding method

# Create a mock object
my $mock = Test::MockObject->new();

# Mock successful geocoding response
$mock->mock(
    'geocode',
    sub {
        my ($self, $address) = @_;
        return { lat => 40.7128, lon => -74.0060 } if $address eq 'New York, NY';
        return { lat => 37.7749, lon => -122.4194 } if $address eq 'San Francisco, CA';
        return undef; # Simulate failure for unknown locations
    }
);

my $osm = HTML::OSM->new(geocoder => $mock);

# Test valid address lookup
my @results = $osm->_fetch_coordinates('New York, NY');
is_deeply(\@results, [ 40.7128, -74.0060 ], 'Geocoding returns correct coordinates for New York');

@results = $osm->_fetch_coordinates('San Francisco, CA');
is_deeply(\@results, [ 37.7749, -122.4194 ], 'Geocoding returns correct coordinates for San Francisco');

# Test invalid address lookup (should return undef)
my $result = $osm->_fetch_coordinates('Unknown Place');
is($result, undef, 'Geocoding returns undef for unknown place');

# Test integration: Adding marker with geocoding
ok($osm->add_marker(['New York, NY'], html => 'NY Marker'), 'Adding marker using geocoded address');
is_deeply($osm->{coordinates}->[0], [40.7128, -74.0060, 'NY Marker', undef], 'Marker stored with correct geocoded coordinates');

# Simulate geocoding failure
ok(!$osm->add_marker(['Unknown Place'], html => 'Invalid Marker'), 'Fails to add marker for unknown location');

done_testing();
