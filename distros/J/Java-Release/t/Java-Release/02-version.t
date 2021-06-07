use strict;
use warnings;

use Java::Release;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Java::Release::VERSION, 0.06, 'Version.');
