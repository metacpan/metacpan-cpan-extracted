use strict;
use warnings;

use Error::Pure::ANSIColor;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::ANSIColor::VERSION, 0.29, 'Version.');
