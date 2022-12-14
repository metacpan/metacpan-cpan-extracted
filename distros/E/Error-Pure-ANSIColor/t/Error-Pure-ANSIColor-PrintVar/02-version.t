use strict;
use warnings;

use Error::Pure::ANSIColor::PrintVar;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::ANSIColor::PrintVar::VERSION, 0.29, 'Version.');
