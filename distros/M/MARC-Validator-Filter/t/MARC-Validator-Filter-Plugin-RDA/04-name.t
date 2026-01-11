use strict;
use warnings;

use MARC::Validator::Filter::Plugin::RDA;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Filter::Plugin::RDA->new;
is($obj->name, 'rda', 'Get name of plugin (rda).');
