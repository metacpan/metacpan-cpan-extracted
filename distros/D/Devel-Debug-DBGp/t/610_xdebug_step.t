#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/base.pl', 'Xdebug=send_position_after_stepping');

command_is(['step_into'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'step_into',
    filename    => abs_uri('t/scripts/base.pl'),
    lineno      => 1,
});

command_is(['step_into'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'step_into',
}) for 1 .. 8;

command_is(['step_into'], {
    reason      => 'ok',
    status      => 'stopping',
    command     => 'step_into',
    # returns the last file/line (same as calling stack_get would)
    filename    => abs_uri('t/scripts/base.pl'),
    lineno      => 8,
});

command_is(['status'], {
    status  => 'stopping',
    reason  => 'ok',
});

done_testing();
