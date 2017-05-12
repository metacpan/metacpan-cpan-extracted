#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/hitcount_breakpoint.pl');

command_is(['breakpoint_set', '-t', 'line', '-f', 'file://t/scripts/hitcount_breakpoint.pl', '-n', 2, '-h', 3, '-o', '>='], {
    state       => 'enabled',
    id          => 0,
});

command_is(['breakpoint_set', '-t', 'line', '-f', 'file://t/scripts/hitcount_breakpoint.pl', '-n', 6, '-h', 3, '-o', '=='], {
    state       => 'enabled',
    id          => 1,
});

command_is(['breakpoint_remove', '-d', 0], {
});

breakpoint_list_is([
    {
        id              => 1,
        type            => 'line',
        state           => 'enabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '6',
        hit_value       => 3,
        hit_condition   => '==',
        hit_count       => 0,
    },
]);

send_command('run');

eval_value_is('$i', undef); # inside second loop
eval_value_is('$j', 3);

done_testing();
