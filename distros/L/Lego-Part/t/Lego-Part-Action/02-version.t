# Pragmas.
use strict;
use warnings;

# Modules.
use Lego::Part::Action;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Lego::Part::Action::VERSION, 0.03, 'Version.');
