# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::Print;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::HTTP::Print::VERSION, 0.14, 'Version.');
