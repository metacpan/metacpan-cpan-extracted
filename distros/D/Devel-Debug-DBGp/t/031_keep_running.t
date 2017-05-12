#!/usr/bin/perl

use t::lib::Test;

start_listening();
run_program('t/scripts/base.pl');
wait_connection('reject');

is(wait_line(), undef);
is(wait_line(), undef);

run_program('t/scripts/base.pl', 'KeepRunning=1');
wait_connection('reject');

is(wait_line(), "STDOUT 15\n");
is(wait_line(), "STDERR 15\n");

run_program('t/scripts/base.pl', 'KeepRunning=0');
wait_connection('reject');

is(wait_line(), undef);
is(wait_line(), undef);

done_testing();
