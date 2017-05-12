# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::HTTP::VERSION, 0.14, 'Version.');
