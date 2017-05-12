use strict;
use warnings;

use Test::More tests => 4;
use Linux::Prctl qw(:constants :functions);

for(1,0) {
    is(set_dumpable($_), 0, "Setting dumpable to $_");
    is(get_dumpable, $_, "Checking whether dumpable is $_");
}
