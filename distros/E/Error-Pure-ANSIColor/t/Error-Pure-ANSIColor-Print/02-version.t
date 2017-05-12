use strict;
use warnings;

use Error::Pure::ANSIColor::Print;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::ANSIColor::Print::VERSION, 0.01, 'Version.');
