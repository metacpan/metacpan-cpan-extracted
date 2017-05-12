use strict;
use warnings;

use Test::More tests => 3;
use Linux::Prctl qw(:constants :functions);

is(get_timing, TIMING_STATISTICAL, "Checking default timing");
is(set_timing(TIMING_TIMESTAMP), -1, "Setting timing to timestamp should fail");
is(set_timing(TIMING_STATISTICAL), 0, "Setting timing to statistical should not fail");
