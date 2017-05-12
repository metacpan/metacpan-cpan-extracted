# Pragmas.
use strict;
use warnings;

# Modules.
use Map::Tube::Text::Table;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Map::Tube::Text::Table::VERSION, 0.04, 'Version.');
