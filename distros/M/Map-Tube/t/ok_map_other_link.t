#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use lib 't/';
use OtherLink;
use Test::Map::Tube tests => 1;

my $routes =
[
   "Route 1|A1|A3|A1,A2,A3",
   "Route 2|A4|A1|A4,A2,A1",
];

ok_map_routes(OtherLink->new, $routes);
