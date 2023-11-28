use strict;
use warnings;

use Error::Pure::HTTP::Error;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::HTTP::Error::VERSION, 0.16, 'Version.');
