use strict;
use warnings;

use Error::Pure::Error;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::Error::VERSION, 0.3, 'Version.');
