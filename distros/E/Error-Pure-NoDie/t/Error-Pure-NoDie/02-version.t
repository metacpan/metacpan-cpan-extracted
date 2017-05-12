# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::NoDie;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::NoDie::VERSION, 0.04, 'Version.');
