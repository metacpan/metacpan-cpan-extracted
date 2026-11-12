#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use lib 't/';
use File::Spec;
use Sample;
use Test::Map::Tube tests => 2;

my $routes = [ "Route 1|S1|S5|S1,S11,S12,S13,S14,S5" ];

my $map = Sample->new( xml => File::Spec->catfile('t', 'map-line-change-penalty.xml') );
ok_map_routes( $map, $routes, 'Default line change penalty' );

$routes = [ "Route 2|S1|S5|S1,S2,S3,S4,S5" ];
$map->line_change_penalty(0.0);
ok_map_routes( $map, $routes, 'Line change penalty 0' );

