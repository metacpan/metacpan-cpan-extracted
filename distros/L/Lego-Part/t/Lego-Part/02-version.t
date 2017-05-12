# Pragmas.
use strict;
use warnings;

# Modules.
use Lego::Part;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Lego::Part::VERSION, 0.03, 'Version.');
