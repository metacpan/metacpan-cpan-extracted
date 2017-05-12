# Pragmas.
use strict;
use warnings;

# Modules.
use Lego::Part::Transfer;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Lego::Part::Transfer::VERSION, 0.03, 'Version.');
