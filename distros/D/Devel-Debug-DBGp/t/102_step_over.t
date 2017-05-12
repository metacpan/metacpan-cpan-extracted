#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/step.pl');

position_is('t/scripts/step.pl', 1);

# fake first step
send_command('step_over');
position_is('t/scripts/step.pl', 1);

send_command('step_over');
position_is('t/scripts/step.pl', 21);

# basic step over functionality
send_command('step_into');
position_is('t/scripts/step.pl', 15);

send_command('step_over');
position_is('t/scripts/step.pl', 16);

send_command('step_into');
position_is('t/scripts/step.pl', 9);

send_command('step_over');
position_is('t/scripts/step.pl', 10);

send_command('step_over');
position_is('t/scripts/step.pl', 11);

send_command('step_over');
position_is('t/scripts/step.pl', 17);

# step over + breakpoint + run
send_command('step_into');
position_is('t/scripts/step.pl', 15);

send_command('step_over');
position_is('t/scripts/step.pl', 16);

command_is(['breakpoint_set', '-t', 'line', '-f', 't/scripts/step.pl', '-n', 4, '-r', 1], {
    state   => 'enabled',
    id      => 0,
});

send_command('step_over');
position_is('t/scripts/step.pl', 4);

send_command('run');
position_is('t/scripts/step.pl', 17);

done_testing();
