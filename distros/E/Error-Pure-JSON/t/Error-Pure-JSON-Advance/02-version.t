use strict;
use warnings;

use Error::Pure::JSON::Advance;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::JSON::Advance::VERSION, 0.08, 'Version.');
