# Pragmas.
use strict;
use warnings;

# Modules.
use Image::Random;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Image::Random::VERSION, 0.06, 'Version.');
