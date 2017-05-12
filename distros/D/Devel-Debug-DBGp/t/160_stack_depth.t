#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/stack.pl');

command_is(['stack_depth'], {
    depth   => 0,
});

send_command('run');

command_is(['stack_depth'], {
    depth   => 0,
});

for my $i (1 .. 5) {
    send_command('run');
    command_is(['stack_depth'], {
        depth   => $i,
    });
}

send_command('run');

command_is(['stack_depth'], {
    depth   => 0,
});

send_command('run');

command_is(['stack_depth'], {
    depth   => 1,
});

send_command('run');

command_is(['stack_depth'], {
    depth   => 2,
});

send_command('run');

command_is(['stack_depth'], {
    depth   => 1,
});

done_testing();
