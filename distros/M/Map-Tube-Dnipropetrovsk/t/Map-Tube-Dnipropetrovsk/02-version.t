use strict;
use warnings;

use Map::Tube::Dnipropetrovsk;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Dnipropetrovsk::VERSION, 0.08, 'Version.');
