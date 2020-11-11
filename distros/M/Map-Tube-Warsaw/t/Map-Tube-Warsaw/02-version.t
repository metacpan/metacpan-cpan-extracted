use strict;
use warnings;

use Map::Tube::Warsaw;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Warsaw::VERSION, 0.07, 'Version.');
