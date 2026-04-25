use strict;
use warnings;

use License::SPDX;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($License::SPDX::VERSION, 0.07, 'Version.');
