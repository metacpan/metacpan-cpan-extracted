use strict;
use warnings;

use Map::Tube::GraphViz::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::GraphViz::Utils::VERSION, 0.07, 'Version.');
