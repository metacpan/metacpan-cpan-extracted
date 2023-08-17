use strict;
use warnings;

use Error::Pure::JSON;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::JSON::VERSION, 0.08, 'Version.');
