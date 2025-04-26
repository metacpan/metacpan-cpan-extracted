package OtherLink;

use Moo;
use namespace::clean;

has xml => (is => 'ro', default => sub { return File::Spec->catfile('t', 'map-other-link.xml') });
with 'Map::Tube';

package main;

use v5.14;
use strict;
use warnings;
use Test::Map::Tube tests => 1;

my $routes =
[
   "Route 1|A1|A3|A1,A2,A3",
   "Route 2|A4|A1|A4,A2,A1",
];

ok_map_routes(OtherLink->new, $routes);
