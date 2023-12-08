use strict;
use warnings;

use Map::Tube::Kharkiv;
use Test::Map::Tube 'tests' => 3;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Kharkiv->new;
ok_map($map, 'Test validity of map.');
ok_map_functions($map, 'Test map functions.');
