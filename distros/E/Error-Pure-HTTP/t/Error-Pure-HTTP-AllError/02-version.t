# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::AllError;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::HTTP::AllError::VERSION, 0.14, 'Version.');
