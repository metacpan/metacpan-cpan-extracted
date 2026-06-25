#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use lib 't/';
use File::Spec;
use Sample;
use Test::Map::Tube tests => 1;

my $routes = [ "Route 1|S1|S4|S1,S2,S3,S4" ];

my $map = Sample->new( xml => File::Spec->catfile('t', 'map-line-change.xml') );
ok_map_routes( $map, $routes );
