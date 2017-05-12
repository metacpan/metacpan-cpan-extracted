#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/hitcount_breakpoint.pl');

command_is(['breakpoint_set', '-t', 'line', '-f', 't/scripts/hitcount_breakpoint.pl', '-n', 2, '-h', 3, '-o', '>='], {
    state       => 'enabled',
    id          => 0,
});

command_is(['breakpoint_set', '-t', 'line', '-f', abs_path('t/scripts/hitcount_breakpoint.pl'), '-n', 6, '-h', 3, '-o', '=='], {
    state       => 'enabled',
    id          => 1,
});

command_is(['breakpoint_set', '-t', 'line', '-f', 'file://t/scripts/hitcount_breakpoint.pl', '-n', 10, '-h', 2, '-o', '%'], {
    state       => 'enabled',
    id          => 2,
});

breakpoint_list_is([
    {
        id              => 0,
        type            => 'line',
        state           => 'enabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '2',
        hit_value       => 3,
        hit_condition   => '>=',
        hit_count       => 0,
    },
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
    {
        id              => 2,
        type            => 'line',
        state           => 'enabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '10',
        hit_value       => 2,
        hit_condition   => '%',
        hit_count       => 0,
    },
]);

send_command('run');

eval_value_is('$i', 3);

command_is(['breakpoint_get', '-d', 0], {
    breakpoint => {
        id              => 0,
        type            => 'line',
        state           => 'enabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '2',
        hit_value       => 3,
        hit_condition   => '>=',
        hit_count       => 3,
    },
});

send_command('run');

eval_value_is('$i', 4);

command_is(['breakpoint_get', '-d', 0], {
    breakpoint => {
        id              => 0,
        type            => 'line',
        state           => 'enabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '2',
        hit_value       => 3,
        hit_condition   => '>=',
        hit_count       => 4,
    },
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/hitcount_breakpoint.pl'),
            where       => 'main',
            lineno      => '2',
        },
    ],
});

send_command('run');

eval_value_is('$j', 3);

command_is(['breakpoint_get', '-d', 1], {
    breakpoint => {
        id              => 1,
        type            => 'line',
        state           => 'enabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '6',
        hit_value       => 3,
        hit_condition   => '==',
        hit_count       => 3,
    },
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/hitcount_breakpoint.pl'),
            where       => 'main',
            lineno      => '6',
        },
    ],
});

send_command('run');

eval_value_is('$k', 2);

command_is(['breakpoint_get', '-d', 2], {
    breakpoint => {
        id              => 2,
        type            => 'line',
        state           => 'enabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '10',
        hit_value       => 2,
        hit_condition   => '%',
        hit_count       => 2,
    },
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/hitcount_breakpoint.pl'),
            where       => 'main',
            lineno      => '10',
        },
    ],
});

send_command('run');

eval_value_is('$k', 4);

command_is(['breakpoint_get', '-d', 2], {
    breakpoint => {
        id              => 2,
        type            => 'line',
        state           => 'enabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '10',
        hit_value       => 2,
        hit_condition   => '%',
        hit_count       => 4,
    },
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/hitcount_breakpoint.pl'),
            where       => 'main',
            lineno      => '10',
        },
    ],
});

command_is(['breakpoint_update', '-d', 2, '-s', 'disabled'], {
    breakpoint => {
        id              => 2,
        type            => 'line',
        state           => 'disabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '10',
        hit_value       => 2,
        hit_condition   => '%',
        hit_count       => 4,
    },
});

send_command('run');

command_is(['breakpoint_get', '-d', 2], {
    breakpoint => {
        id              => 2,
        type            => 'line',
        state           => 'disabled',
        filename        => abs_uri('t/scripts/hitcount_breakpoint.pl'),
        lineno          => '10',
        hit_value       => 2,
        hit_condition   => '%',
        hit_count       => 4,
    },
});

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/hitcount_breakpoint.pl'),
            where       => 'main',
            lineno      => '15',
        },
    ],
});

done_testing();
