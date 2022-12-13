use strict;
use warnings;

use Log::FreeSWITCH::Line::Data;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
is($Log::FreeSWITCH::Line::Data::VERSION, 0.08, 'Version.');
