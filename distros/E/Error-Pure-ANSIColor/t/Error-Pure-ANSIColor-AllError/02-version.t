use strict;
use warnings;

use Error::Pure::ANSIColor::AllError;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::ANSIColor::AllError::VERSION, 0.02, 'Version.');
