#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/recursion_check.pl', 'RecursionCheckDepth=22');

command_is(['run'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'run',
});
command_is(['stack_depth'], {
    depth   => 22,
});
position_is('t/scripts/recursion_check.pl', 2);
eval_value_is('$_[0]', 49);
send_command('step_over');
eval_value_is('$n', 49); # double-check the frame is consistent

done_testing();
