use strict;
use warnings;

use MARC::Validator::Abstract;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Validator::Abstract->new;
isa_ok($obj, 'MARC::Validator::Abstract');
