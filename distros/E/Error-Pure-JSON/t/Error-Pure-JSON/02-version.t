# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::JSON;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::JSON::VERSION, 0.07, 'Version.');
