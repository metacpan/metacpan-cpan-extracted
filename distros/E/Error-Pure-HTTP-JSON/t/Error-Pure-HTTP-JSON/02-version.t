# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::JSON;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::HTTP::JSON::VERSION, 0.05, 'Version.');
