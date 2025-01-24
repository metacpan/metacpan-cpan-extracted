use strict;
use warnings;

use Map::Tube::Novosibirsk;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Novosibirsk::VERSION, 0.05, 'Version.');
