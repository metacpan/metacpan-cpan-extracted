use strict;
use warnings;

use MARC::Validator::Plugin::Field504;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field504->new;
is($obj->name, 'field_504', 'Get name of plugin (field_504).');
