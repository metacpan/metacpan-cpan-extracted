use strict;
use warnings;

use METS::Files;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($METS::Files::VERSION, 0.03, 'Version.');
