use strict;
use warnings;

use Error::Pure::ANSIColor::Die;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::ANSIColor::Die::VERSION, 0.27, 'Version.');
