#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/reconnect.pl');

eval_value_is('$i', undef);

send_command('step_into');
send_command('step_into');
eval_value_is('$i', 0);

send_command('step_into');
eval_value_is('$i', 1);

send_command('detach');
wait_connection();

eval_value_is('$i', 3);

send_command('step_into');
send_command('step_into');
eval_value_is('$i', 4);

done_testing();
