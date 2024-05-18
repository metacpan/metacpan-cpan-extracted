use strict;
use warnings;

use Error::Pure::PrintVar;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::PrintVar::VERSION, 0.34, 'Version.');
