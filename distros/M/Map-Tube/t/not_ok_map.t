package BadSample;

use Moo;
use namespace::clean;

has xml => (is => 'ro', default => sub { return File::Spec->catfile('t', 'map-bad-sample.xml') });
with 'Map::Tube';

package main;

use v5.14;
use strict; use warnings;
use Test::Map::Tube tests => 1;

not_ok_map_data(BadSample->new);
