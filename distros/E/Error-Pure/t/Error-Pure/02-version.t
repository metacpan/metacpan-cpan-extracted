use strict;
use warnings;

use Error::Pure;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::VERSION, 0.34, 'Version.');
