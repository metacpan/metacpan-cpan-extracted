# Pragmas.
use strict;
use warnings;

# Modules.
use Indent::Word;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::Word::VERSION, 0.03, 'Version.');
