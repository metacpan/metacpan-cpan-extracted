use strict;
no strict 'subs';
use warnings;

use Test::More tests => 3;
use Linux::Prctl qw(:constants :functions);

SKIP: {
    skip "set_timerslack not available", 3 unless Linux::Prctl->can('set_timerslack');
    is(get_timerslack, 50000, "Checking default timerslack value");
    is(set_timerslack(75000), 0, "Setting new timerslack value");
    is(get_timerslack, 75000, "Checking new timerslack value");
}
