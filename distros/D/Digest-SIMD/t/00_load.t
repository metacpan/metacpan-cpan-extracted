use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok('Digest::SIMD'); }

diag "Testing Digest::SIMD $Digest::SIMD::VERSION";
