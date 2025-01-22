use strict;
use warnings;

use Map::Tube::Sofia;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Sofia::VERSION, 0.1, 'Version.');
