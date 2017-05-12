#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/args.pl');

send_command('step_into');
send_command('step_into');

position_is('t/scripts/args.pl', 8);
eval_value_is('$_[0]', "foo");
eval_value_is('$_[1]', 7);

done_testing();
