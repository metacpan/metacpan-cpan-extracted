use strict;
use warnings;

use MARC::Validator::Plugin::Field260;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Plugin::Field260::VERSION, 0.06, 'Version.');
