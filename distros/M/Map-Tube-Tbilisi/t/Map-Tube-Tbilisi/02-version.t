use strict;
use warnings;

use Map::Tube::Tbilisi;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Tbilisi::VERSION, 0.05, 'Version.');
