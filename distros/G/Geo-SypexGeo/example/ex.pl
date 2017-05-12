#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.10;

use lib 'lib';

use Geo::SypexGeo;

binmode STDOUT, ':utf8';

my $geo = Geo::SypexGeo->new('data/SxGeoCity.dat');

my $info;

$info = $geo->parse( '87.250.250.203', 'en' )
    or die "Cant parse 87.250.250.203";
say $info->city();

$info = $geo->parse('93.191.14.81') or die "Cant parse 93.191.14.81";
say $info->city();
say $info->country();

my ( $latitude, $longitude ) = $info->coordinates();
say "Latitude: $latitude Longitude: $longitude";

## deprecated method (will be removed in future versions)
say $geo->get_city( '87.250.250.203', 'en' );

## deprecated method (will be removed in future versions)
say $geo->get_city('93.191.14.81');

## deprecated method (will be removed in future versions)
say $geo->get_country('93.191.14.81');
