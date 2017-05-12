#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/breakpoint.pl');

command_is(['breakpoint_set', '-t', 'line', '-f', 'file://t/scripts/breakpoint.pl', '-n', 4, '-r', 1], {
    state       => 'enabled',
    id          => 0,
});

command_is(['breakpoint_set', '-t', 'line', '-f', 'file://t/scripts/breakpoint.pl', '-n', 7], {
    state       => 'enabled',
    id          => 1,
});

command_is(['breakpoint_get', '-d', 0], {
    breakpoint => {
        id          => 0,
        type        => 'line',
        state       => 'enabled',
        filename    => abs_uri('t/scripts/breakpoint.pl'),
        lineno      => '4',
        expression  => '',
        temporary   => 1,
    },
});

send_command('run');

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/breakpoint.pl'),
            where       => 'main',
            lineno      => '4',
        },
    ],
});

command_is(['breakpoint_get', '-d', 0], {
    breakpoint => {
        id          => 0,
        type        => 'line',
        state       => 'disabled',
        filename    => abs_uri('t/scripts/breakpoint.pl'),
        lineno      => '4',
        expression  => '',
        temporary   => 0,
    },
});

send_command('run');

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/breakpoint.pl'),
            where       => 'main',
            lineno      => '7',
        },
    ],
});

done_testing();
