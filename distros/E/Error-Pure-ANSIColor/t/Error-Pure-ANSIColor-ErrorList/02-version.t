use strict;
use warnings;

use Error::Pure::ANSIColor::ErrorList;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::ANSIColor::ErrorList::VERSION, 0.26, 'Version.');
