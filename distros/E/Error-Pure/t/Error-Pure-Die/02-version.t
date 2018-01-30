# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Die;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::Die::VERSION, 0.25, 'Version.');
