use strict;
use warnings;

use MARC::Validator::Plugin::Field020;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Validator::Plugin::Field020::VERSION, 0.02, 'Version.');
