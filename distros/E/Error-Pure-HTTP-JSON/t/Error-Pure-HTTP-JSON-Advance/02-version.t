use strict;
use warnings;

use Error::Pure::HTTP::JSON::Advance;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::HTTP::JSON::Advance::VERSION, 0.06, 'Version.');
