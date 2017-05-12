use strict;
use warnings;

use lib 't/lib';

BEGIN { $ENV{LIST_SOMEUTILS_IMPLEMENTATION} = 'PP' }

use Test::More 0.96;

use LSU::Test::Import;
LSU::Test::Import->run_tests;

