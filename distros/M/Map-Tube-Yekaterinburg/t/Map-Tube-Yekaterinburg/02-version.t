# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Yekaterinburg;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Yekaterinburg::VERSION, 0.05, 'Version.');
