#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/step.pl');

position_is('t/scripts/step.pl', 1);

command_is(['breakpoint_set', '-t', 'line', '-f', 't/scripts/step.pl', '-n', 4, '-h', 15, '-o', '=='], {
    state   => 'enabled',
    id      => 0,
});

send_command('run');
position_is('t/scripts/step.pl', 4);
stack_depth_is(17);

send_command('step_out');
position_is('t/scripts/step.pl', 11);
stack_depth_is(16);

send_command('step_into');
position_is('t/scripts/step.pl', 17);
stack_depth_is(15);

send_command('step_out');
position_is('t/scripts/step.pl', 18);
stack_depth_is(14);

send_command('step_out');
position_is('t/scripts/step.pl', 18);
stack_depth_is(13);

done_testing();
