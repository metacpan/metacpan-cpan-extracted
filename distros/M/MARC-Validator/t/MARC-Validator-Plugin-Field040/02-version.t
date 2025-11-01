use strict;
use warnings;

use MARC::Validator::Plugin::Field040;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Plugin::Field040::VERSION, 0.06, 'Version.');
