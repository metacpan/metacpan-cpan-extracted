use strict;
use warnings;

use Indent::Form;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Indent::Form::VERSION, 0.07, 'Version.');
