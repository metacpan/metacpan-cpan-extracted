use strict;
use warnings;

use File::Find::Rule::DMIDecode;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($File::Find::Rule::DMIDecode::VERSION, 0.04, 'Version.');
