#!/usr/bin/perl

use t::lib::Test;

start_listening();

run_program('t/scripts/connect_after.pl', 'ConnectAtStart=0');
wait_line(); # sync point

start_listening();
send_line(); # sync point

wait_connection();

eval_value_is('$i', 2);

send_command('step_into');
send_command('step_into');
eval_value_is('$i', 3);

done_testing();
