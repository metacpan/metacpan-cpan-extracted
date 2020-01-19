use strict;
use warnings;

use Image::Select::Array;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Image::Select::Array::VERSION, 0.05, 'Version.');
