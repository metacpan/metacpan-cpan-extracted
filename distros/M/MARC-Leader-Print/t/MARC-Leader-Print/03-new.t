use strict;
use warnings;

use MARC::Leader::Print;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $obj = MARC::Leader::Print->new;
isa_ok($obj, 'MARC::Leader::Print');
