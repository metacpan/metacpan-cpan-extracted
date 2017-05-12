use strict;
use warnings;

use lib 't/lib';

BEGIN { $ENV{LIST_SOMEUTILS_IMPLEMENTATION} = 'PP' }

use LSU::Test::ab;
LSU::Test::ab->run_tests;

