# Pragmas.
use strict;
use warnings;

# Modules.
use Image::Checkerboard;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Image::Checkerboard::VERSION, 0.03, 'Version.');
