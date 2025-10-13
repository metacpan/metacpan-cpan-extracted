use strict;
use warnings;

use MARC::Validator::Plugin::Field040;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field040->new;
is($obj->name, 'field_040', 'Get name of plugin (field_040).');
