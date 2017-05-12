#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Basename;
use List::MoreUtils 'uniq';
use Data::Dumper;

BEGIN {
    use_ok('Geo::PostalCode::NoDB');
}

my $csvfile =
  File::Spec->catfile( dirname(__FILE__), '..', 'data',
    'zipcodes-csv-10-Aug-2004', 'zipcode.csv' );

my $gp = Geo::PostalCode::NoDB->new( csvfile => $csvfile );

ok( defined $gp, '$gp defined' );

my $r = $gp->lookup_postal_code( postal_code => '11237' );

ok( defined $r, 'record for 11237 is defined' );

is( $r->{state}, 'NY',        '11237 state' );
is( $r->{lat},   '40.703355', '11237 latitude' );
is( $r->{city},  'BROOKLYN',  '11237 city' );
is( $r->{lon},   '-73.91993', '11237 longitude' );

is( int $gp->calculate_distance( postal_codes => [ '11237', '90210' ] ),
    '2455', 'from home to Hollywood!' );

is( $gp->calculate_distance( postal_codes => [ '10010', '10001' ] ),
    '1.10840222844998', 'from work to gym!' );

my @postal_codes = sort @{
    $gp->nearby_postal_codes(
        lat      => $r->{lat},
        lon      => $r->{lon},
        distance => 3
    )
  };

my @expected =
  qw!11104 11205 11206 11207 11211 11212 11213 11216 11221 11222 11233 11237 11238 11377 11378 11379 11385!;

is_deeply( \@expected, \@postal_codes );

@postal_codes = sort @{
    $gp->nearby_postal_codes(
        lat      => $r->{lat},
        lon      => $r->{lon},
        distance => 25
    )
  };

is( @postal_codes, 706, '706 zipcodes near 25 miles' );

my $postal_codes = $gp->query_postal_codes(
    lat      => $r->{lat},
    lon      => $r->{lon},
    distance => 100,
    select   => [ 'distance', 'city', 'state', 'lat', 'lon' ],
    order_by => 'distance'
);

my @states = uniq map { $_->{state} } @$postal_codes;

@expected = qw(NY NJ PA CT);

eq_array( \@states, \@expected, 'the only states nearby' );

$r = $gp->lookup_city_state( city => 'Jersey City', state => 'NJ' );

is_deeply(
    $r->{postal_codes},
    [
        qw(07097 07301 07302 07303 07304 07305 07306 07307 07308 07309 07310 07311 07399)
    ],
    'postal codes for Jersey City'
);

is( $r->{lat}, '40.72908', 'latitude for Jersey City' );
is( $r->{lon}, '-74.06528', 'longitude for Jersey City' );

$r = $gp->lookup_city_state( city => 'New York', state => 'NY' );

$postal_codes = $gp->query_postal_codes(
    lat      => $r->{lat},
    lon      => $r->{lon},
    distance => 26,
    select   => [ 'distance', 'lat', 'lon' ],
    order_by => 'distance'
);

my @a =
  map { $_->{postal_code} } grep { int( $_->{distance} ) == 25 } @$postal_codes;
my @b =
  map { $_->{postal_code} } grep { int( $_->{distance} ) > 26 } @$postal_codes;

is( @b, 0 );

$postal_codes = $gp->query_postal_codes(
    lat      => $r->{lat},
    lon      => $r->{lon},
    distance => 60,
    select   => [ 'distance', 'lat', 'lon' ],
    order_by => 'distance'
);

my @c =
  map { $_->{postal_code} } grep { int( $_->{distance} ) == 25 } @$postal_codes;
@b =
  map { $_->{postal_code} } grep { int( $_->{distance} ) > 60 } @$postal_codes;

is_deeply( \@a, \@c );
is( @b, 0 );

$r = $gp->lookup_city_state( city => 'Flushing', state => 'NY' );

$postal_codes = $gp->query_postal_codes(
    lat      => $r->{lat},
    lon      => $r->{lon},
    distance => 60,
    select   => [ 'distance', 'lat', 'lon' ],
    order_by => 'distance'
);
@b = grep { int( $_->{distance} ) > 60 } @$postal_codes;
is( @b, 0 );

done_testing();

