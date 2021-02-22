use strict;
use warnings;

use Log::FreeSWITCH::Line;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Log::FreeSWITCH::Line::VERSION, 0.07, 'Version.');
