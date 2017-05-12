# Pragmas.
use strict;
use warnings;

# Modules.
use Image::Select;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Image::Select::VERSION, 0.04, 'Version.');
