# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::Output::JSON;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::Output::JSON::VERSION, 0.1, 'Version.');
