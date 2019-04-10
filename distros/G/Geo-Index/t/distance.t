#!perl

# Note: The distances used in this test are based on the values for spherical 
# haversine calculations and are not accurate to the real world.

use constant test_count => 10;

use strict;
use warnings;
use Test::More tests => test_count;

use_ok( 'Geo::Index' );

my $index = Geo::Index->new();
isa_ok $index, 'Geo::Index', 'Geo::Index object';

my @points = (
               { lat=>78.666667, lon=>16.333333, name=>'Svalbard, Norway' },
               { lat=>52.30,     lon=>13.25,     name=>'Berlin, Germany' }, 
               { lat=>6.09,      lon=>106.49,    name=>'Jakarta, Indonesia' }, 
               { lat=>-36.30,    lon=>-60.00,    name=>'Buenos Aires, Argentina' }
             );

my $distance;

$distance = int $index->Distance( $points[0], $points[1] );
cmp_ok( $distance, 'eq', 2934440, "Distance: Berlin to Svalbard" );

$distance = int $index->Distance( [ 90, 1 ], [ -90, -1 ] );
cmp_ok( int $distance, '==', 20015809, "Distance: Pole to pole" );

$distance = int $index->Distance( [ 0, -180 ], [ 0, 180 ] );
cmp_ok( int $distance, 'eq', 0, "Distance: Equatorial 1" );

$distance = int $index->Distance( [ 0, -90 ], [ 0, 90 ] );
cmp_ok( int $distance, 'eq', 20015809, "Distance: Equatorial 2" );

$distance = int $index->Distance( [ -180, 0 ], [ 0, 0 ] );
cmp_ok( int $distance, 'eq', 20015809, "Distance: Equatorial 3" );

$distance = int $index->Distance( [ 0, 0 ], [ 0, 180 ] );
cmp_ok( int $distance, 'eq', 20015809, "Distance: Equatorial 4" );

my $jakarta_to_svalbard = $index->Distance( $points[2], $points[0] );
my $jakarta_to_berlin   = $index->Distance( $points[2], $points[1] );
cmp_ok( $jakarta_to_svalbard, '<', $jakarta_to_berlin, "Distance comparison 1" );

my $buenos_aires_to_svalbard = $index->Distance( $points[3], $points[0] );
my $buenos_aires_to_berlin   = $index->Distance( $points[3], $points[1] );
cmp_ok( $buenos_aires_to_berlin, '<', $buenos_aires_to_svalbard, "Distance comparison 2" );

done_testing;
