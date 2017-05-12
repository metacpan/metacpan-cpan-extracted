# Pragmas.
use strict;
use warnings;

# Modules.
use Indent;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::VERSION, 0.03, 'Version.');
