# Pragmas.
use strict;
use warnings;

# Modules.
use Image::Select::Array;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Image::Select::Array::VERSION, 0.04, 'Version.');
