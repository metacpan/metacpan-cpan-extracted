use strict;
use warnings;

use MARC::Validator::Plugin::Field500;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field500->new;
is($obj->name, 'field_500', 'Get name of plugin (field_500).');
