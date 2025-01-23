use strict;
use warnings;

use Map::Tube::Singapore;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Singapore::VERSION, 0.05, 'Version.');
