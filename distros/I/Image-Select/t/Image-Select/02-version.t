use strict;
use warnings;

use Image::Select;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Image::Select::VERSION, 0.05, 'Version.');
