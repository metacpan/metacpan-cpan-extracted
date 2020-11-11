use strict;
use warnings;

use Indent::Block;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::Block::VERSION, 0.07, 'Version.');
