# Pragmas.
use strict;
use warnings;

# Modules.
use File::Object;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($File::Object::VERSION, 0.11, 'Version.');
