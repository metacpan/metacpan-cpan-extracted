use strict;
use warnings;

use Error::Pure::HTTP::AllError;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::HTTP::AllError::VERSION, 0.16, 'Version.');
