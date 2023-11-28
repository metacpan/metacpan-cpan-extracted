use strict;
use warnings;

use MARC::Leader;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Leader->new;
isa_ok($obj, 'MARC::Leader');
