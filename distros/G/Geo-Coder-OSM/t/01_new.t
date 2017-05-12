use strict;
use warnings;
use Test::More tests => 3;
use Geo::Coder::OSM;

new_ok('Geo::Coder::OSM' => []);
new_ok('Geo::Coder::OSM' => [debug => 1]);

can_ok('Geo::Coder::OSM', qw(geocode response ua));
