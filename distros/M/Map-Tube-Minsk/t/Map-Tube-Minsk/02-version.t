use strict;
use warnings;

use Map::Tube::Minsk;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Minsk::VERSION, 0.06, 'Version.');
