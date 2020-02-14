use strict;
use warnings;

use METS::Parse::Simple;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($METS::Parse::Simple::VERSION, 0.01, 'Version.');
