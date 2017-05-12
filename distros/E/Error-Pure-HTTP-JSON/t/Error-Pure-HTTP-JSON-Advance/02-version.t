# Pragmas.
use strict;
use warnings;

# Modules.
use Error::Pure::HTTP::JSON::Advance;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::HTTP::JSON::Advance::VERSION, 0.05, 'Version.');
