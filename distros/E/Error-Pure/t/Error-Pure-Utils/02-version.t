use strict;
use warnings;

use Error::Pure::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::Utils::VERSION, 0.27, 'Version.');
