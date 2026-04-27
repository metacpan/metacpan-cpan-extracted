use strict;
use warnings;

use MARC::Field008::L10N::cs;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($MARC::Field008::L10N::cs::VERSION, 0.01, 'Version.');
