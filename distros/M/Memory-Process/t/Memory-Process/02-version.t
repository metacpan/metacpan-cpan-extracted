use strict;
use warnings;

use Memory::Process;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Memory::Process::VERSION, 0.06, 'Version.');
