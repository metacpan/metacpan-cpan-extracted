use strict;
use warnings;

use Lego::Part::Image;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Lego::Part::Image::VERSION, 0.06, 'Version.');
