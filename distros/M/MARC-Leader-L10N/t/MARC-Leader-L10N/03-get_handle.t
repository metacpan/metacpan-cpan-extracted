use strict;
use warnings;

use MARC::Leader::L10N;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $ret = MARC::Leader::L10N->get_handle('en');
isa_ok($ret, 'MARC::Leader::L10N::en');

# Test.
$ret = MARC::Leader::L10N->get_handle('cs');
isa_ok($ret, 'MARC::Leader::L10N::cs');
