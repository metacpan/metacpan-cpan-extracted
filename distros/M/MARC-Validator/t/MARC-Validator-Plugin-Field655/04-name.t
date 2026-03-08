use strict;
use warnings;

use MARC::Validator::Plugin::Field655;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Plugin::Field655->new;
is($obj->name, 'field_655', 'Get name of plugin (field_655).');
