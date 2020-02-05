use strict;
use warnings;

use Image::Random;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Image::Random::VERSION, 0.07, 'Version.');
