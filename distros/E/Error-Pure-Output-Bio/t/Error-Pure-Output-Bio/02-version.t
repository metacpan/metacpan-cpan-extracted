use strict;
use warnings;

use Error::Pure::Output::Bio;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Error::Pure::Output::Bio::VERSION, 0.01, 'Version.');
