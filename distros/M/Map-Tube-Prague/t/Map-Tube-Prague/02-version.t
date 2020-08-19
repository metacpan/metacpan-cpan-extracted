use strict;
use warnings;

use Map::Tube::Prague;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Prague::VERSION, 0.15, 'Version.');
