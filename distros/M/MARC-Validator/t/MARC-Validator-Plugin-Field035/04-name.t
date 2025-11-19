use strict;
use warnings;

use MARC::Validator::Plugin::Field035;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field035->new;
is($obj->name, 'field_035', 'Get name of plugin (field_035).');
