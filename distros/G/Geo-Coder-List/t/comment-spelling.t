#!usr/bin/env perl

use 5.006;
use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs { 'Test::Spelling::Comment' => '0.002' };

Test::Spelling::Comment->import();
Test::Spelling::Comment->new()->add_stopwords(<DATA>)->all_files_ok();

__DATA__
ArcGIS
ARGV
Bing
Broadstairs
DataScienceToolkit
ENV
env
Fairfield
freegeocoder
GeoCodeFarm
GeocodeFarm
geocoder
GeoNames
GoogleMaps
Lingua
Mapbox
OpenCage
OSM
RandMcNalley
TODO
usr
addressMatches
geocoders
io
lon
ovi
xyz
