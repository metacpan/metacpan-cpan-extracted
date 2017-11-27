# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Vienna;
use Test::Map::Tube 'tests' => 3;
use Test::NoWarnings;

# Test.
my $map = Map::Tube::Vienna->new;
ok_map($map, 'Test validity of map.');
ok_map_functions($map, 'Test map functions.');
