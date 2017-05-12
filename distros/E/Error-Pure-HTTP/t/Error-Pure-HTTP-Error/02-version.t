# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::Error;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::HTTP::Error::VERSION, 0.14, 'Version.');
