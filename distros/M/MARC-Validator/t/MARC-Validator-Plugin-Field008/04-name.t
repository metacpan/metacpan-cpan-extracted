use strict;
use warnings;

use MARC::Validator::Plugin::Field008;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field008->new;
is($obj->name, 'field_008', 'Get name of plugin (field_008).');
