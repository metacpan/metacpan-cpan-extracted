#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use lib 't/';
use Sample;
use Test::Map::Tube tests => 1;

my $routes =
[
   "Route 1|A1|A3|A1,A2,A3",
   "#Route 2|A1|A3|A1,A3",
];

ok_map_routes(Sample->new, $routes);
