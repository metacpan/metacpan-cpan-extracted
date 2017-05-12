# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::Utils;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::Utils::VERSION, 0.03, 'Version.');
