use strict;
use warnings;

use DjVu::Detect;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($DjVu::Detect::VERSION, 0.05, 'Version.');
