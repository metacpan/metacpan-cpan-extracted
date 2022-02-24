use strict;
use warnings;

use File::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($File::Object::VERSION, 0.15, 'Version.');
