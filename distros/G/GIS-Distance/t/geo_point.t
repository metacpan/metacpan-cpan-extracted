#!/usr/bin/env perl
use 5.008001;
use strictures 2;
use Test2::V0;

use Test2::Require::Module 'Geo::Point';
use Geo::Point;
use GIS::Distance;

my $gis = GIS::Distance->new('GIS::Distance::Haversine');

is(
    $gis->distance(
        Geo::Point->latlong(34.202361,-118.601875),
        Geo::Point->latlong(37.752258,-122.441254),
    )->km(),
    $gis->distance(
        34.202361, -118.601875,
        37.752258, -122.441254,
    )->km(),
    'Geo::Point objects work',
);

done_testing;
