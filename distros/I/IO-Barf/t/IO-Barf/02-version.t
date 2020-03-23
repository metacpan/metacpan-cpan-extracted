use strict;
use warnings;

use IO::Barf;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($IO::Barf::VERSION, 0.09, 'Version.');
