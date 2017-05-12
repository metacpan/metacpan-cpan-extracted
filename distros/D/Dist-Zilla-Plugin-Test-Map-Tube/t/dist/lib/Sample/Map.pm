package Sample::Map;

# ABSTRACT: Sample Map

use strict;
use warnings;
use File::Share ':all';

use Moo;
use namespace::clean;

has xml => (is => 'ro', default => sub { return dist_file('Sample-Map', 'sample-map.xml') });

with 'Map::Tube';

1;
