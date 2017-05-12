# Pragmas.
use strict;
use warnings;

# Modules.
use Lego::Part::Image::LugnetCom;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Lego::Part::Image::LugnetCom::VERSION, 0.05, 'Version.');
