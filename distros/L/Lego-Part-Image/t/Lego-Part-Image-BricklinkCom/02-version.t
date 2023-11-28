use strict;
use warnings;

use Lego::Part::Image::BricklinkCom;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Lego::Part::Image::BricklinkCom::VERSION, 0.06, 'Version.');
