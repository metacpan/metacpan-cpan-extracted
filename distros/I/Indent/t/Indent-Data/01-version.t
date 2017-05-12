# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::Data;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::Data::VERSION, 0.03, 'Version.');
