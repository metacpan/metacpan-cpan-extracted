#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

use GIS::Distance;

my $gis = GIS::Distance->new( 'GIS::Distance::Null' );

is(
    # Canoga Park to San Francisco.
    $gis->distance( 34.202361, -118.601875,  37.752258, -122.441254 ),
    0,
    'the hyperloop is working',
);

done_testing;
