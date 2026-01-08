use strict;
use warnings;

use MARC::Validator::Plugin::Field264;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Plugin::Field264::VERSION, 0.09, 'Version.');
