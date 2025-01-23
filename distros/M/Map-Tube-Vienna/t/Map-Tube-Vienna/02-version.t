use strict;
use warnings;

use Map::Tube::Vienna;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Vienna::VERSION, 0.09, 'Version.');
