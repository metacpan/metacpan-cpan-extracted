use strict;
use warnings;

use Test::More;
use Linux::CPUAffinity;

cmp_ok(Linux::CPUAffinity->num_processors(), '>', 0);

done_testing;
