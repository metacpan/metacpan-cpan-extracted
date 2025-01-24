use strict;
use warnings;

use Map::Tube::Kharkiv;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Kharkiv::VERSION, 0.08, 'Version.');
