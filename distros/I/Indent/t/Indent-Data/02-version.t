use strict;
use warnings;

use Indent::Data;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::Data::VERSION, 0.05, 'Version.');
