package Sample;

use 5.006;
use Moo;
use namespace::clean;

has xml => (is => 'ro', default => sub { return File::Spec->catfile('t', 'sample.xml') });
with 'Map::Tube';

1;
