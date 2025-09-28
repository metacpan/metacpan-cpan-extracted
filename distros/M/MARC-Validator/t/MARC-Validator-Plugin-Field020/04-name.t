use strict;
use warnings;

use MARC::Validator::Plugin::Field020;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field020->new;
is($obj->name, 'field_020', 'Get name of plugin (field_020).');
