use strict;
use warnings;

use Error::Pure::ANSIColor::Error;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::ANSIColor::Error::VERSION, 0.02, 'Version.');
