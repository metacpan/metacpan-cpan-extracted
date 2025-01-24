use strict;
use warnings;

use Map::Tube::Malaga;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Malaga::VERSION, 0.18, 'Version.');
