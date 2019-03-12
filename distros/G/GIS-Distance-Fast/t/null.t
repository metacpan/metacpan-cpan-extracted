#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

use GIS::Distance;

my $gis = GIS::Distance->new( 'GIS::Distance::Fast::Null' );

is(
    # Egypt to Anchorage.
    $gis->distance( 26.185018,   30.047607,  61.147543, -149.81575 ),
    0,
    'exactly zero',
);

done_testing;
