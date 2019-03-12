#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;

BEGIN { $ENV{GIS_DISTANCE_PP} = 1 }
use Geo::Distance;

my $geo = Geo::Distance->new();
my $dist = $geo->distance( 'mile', "-81.044","35.244", "-80.8272","35.1935" );
is( int($dist), 12, 'measure a distance by mile' );

done_testing;
