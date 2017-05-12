#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/hitcount_breakpoint.pl');

command_is(['breakpoint_set', '-t', 'line', '-f', 'file://t/scripts/hitcount_breakpoint.pl', '-n', 10, '-h', 1, '-o', '>='], {
    state       => 'enabled',
    id          => 0,
});

breakpoint_list_is([
    {
        id              => 0,
        type            => 'line',
        state           => 'enabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '10',
        hit_value       => 1,
        hit_condition   => '>=',
        hit_count       => 0,
    },
]);

send_command('run');

eval_value_is('$k', 1);

command_is(['breakpoint_update', '-d', 0, '-h', 2, '-o', '%'], {
    breakpoint => {
        id              => 0,
        type            => 'line',
        state           => 'enabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '10',
        hit_value       => 2,
        hit_condition   => '%',
        hit_count       => 0,
    },
});

send_command('run');

eval_value_is('$k', 3);

command_is(['breakpoint_update', '-d', 0, '-s', 'disabled'], {
    breakpoint => {
        id              => 0,
        type            => 'line',
        state           => 'disabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '10',
        hit_value       => 2,
        hit_condition   => '%',
        hit_count       => 2,
    },
});

send_command('run');

command_is(['breakpoint_update', '-d', 0, '-s', 'disabled'], {
    breakpoint => {
        id              => 0,
        type            => 'line',
        state           => 'disabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '10',
        hit_value       => 2,
        hit_condition   => '%',
        hit_count       => 2,
    },
});

eval_value_is('$k', undef); # outside of the loop

done_testing();
