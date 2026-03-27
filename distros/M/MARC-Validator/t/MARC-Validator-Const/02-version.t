use strict;
use warnings;

use MARC::Validator::Const;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Const::VERSION, 0.14, 'Version.');
