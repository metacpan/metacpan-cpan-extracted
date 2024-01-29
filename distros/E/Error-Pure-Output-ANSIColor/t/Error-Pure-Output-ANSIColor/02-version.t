use strict;
use warnings;

use Error::Pure::Output::ANSIColor;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::Output::ANSIColor::VERSION, 0.05, 'Version.');
