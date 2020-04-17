use strict;
use warnings;

use Java::Release::Obj;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Java::Release::Obj::VERSION, 0.03, 'Version.');
