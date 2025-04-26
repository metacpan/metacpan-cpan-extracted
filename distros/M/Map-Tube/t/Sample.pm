package Sample;

use v5.14;
use Moo;
use namespace::clean;

has xml => (is => 'ro', default => sub { return File::Spec->catfile('t', 'map-sample.xml') });
with 'Map::Tube';

1;
