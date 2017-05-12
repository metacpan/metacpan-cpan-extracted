use strict;
no strict 'subs';
use warnings;

use Test::More tests => 7;
use Linux::Prctl qw(:constants :functions);

SKIP: {
    skip "set_mce_kill not available", 7 unless Linux::Prctl->can('set_mce_kill');
    is(get_mce_kill, MCE_KILL_DEFAULT, "Checking default mce_kill value");
    for(MCE_KILL_EARLY, MCE_KILL_LATE, MCE_KILL_DEFAULT) {
        is(set_mce_kill($_), 0, "Setting tsc to $_");
        is(get_mce_kill, $_, "Checking whether tsc is $_");
    }
}
