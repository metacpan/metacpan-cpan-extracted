#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/output.pl');

command_is(['stdout', '-c', 2], { success => 1 });
command_is(['stdout', '-c', 2], { success => 1 }); # check it actually is a noop
command_is(['stderr', '-c', 1], { success => 1 });

command_is(['step_into'], { status => 'break' }) for 1 .. 4;
dbgp_stdout_is('');
dbgp_stderr_is('');

command_is(['step_into'], { status => 'break' });
dbgp_stdout_is('i = 1, ');
dbgp_stderr_is('');

command_is(['step_into'], { status => 'break' });
dbgp_stdout_is('i = 1, ');
dbgp_stderr_is('I = 1, ');

command_is(['stdout', '-c', 0], { success => 1 });
command_is(['stderr', '-c', 1], { success => 1 });

command_is(['step_into'], { status => 'break' }) for 1 .. 3;
dbgp_stdout_is('i = 1, ');
dbgp_stderr_is('I = 1, I = 3, ');

command_is(['stdout', '-c', 1], { success => 1 });
command_is(['stderr', '-c', 0], { success => 1 });

command_is(['step_into'], { status => 'break' }) for 1 .. 3;
dbgp_stdout_is('i = 1, i = 6, ');
dbgp_stderr_is('I = 1, I = 3, ');

done_testing();
