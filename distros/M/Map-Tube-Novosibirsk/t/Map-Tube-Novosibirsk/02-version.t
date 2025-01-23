# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Novosibirsk;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Novosibirsk::VERSION, 0.04, 'Version.');
