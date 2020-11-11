use strict;
use warnings;

use Indent::Word;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::Word::VERSION, 0.07, 'Version.');
