# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::JSON::Advance;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::JSON::Advance::VERSION, 0.07, 'Version.');
