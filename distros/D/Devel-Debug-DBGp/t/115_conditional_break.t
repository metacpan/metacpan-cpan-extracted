#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

run_debugger('t/scripts/breakpoint.pl');

command_is(['breakpoint_set', '-t', 'line', '-f', 'file://t/scripts/breakpoint.pl', '-n', 12], {
    state       => 'enabled',
    id          => 0,
});

command_is(['breakpoint_set', '-t', 'conditional', '-f', 'file://t/scripts/breakpoint.pl', '-n', 4, '--', encode_base64('should_break()')], {
    state       => 'enabled',
    id          => 1,
});

command_is(['breakpoint_set', '-t', 'conditional', '-f', 'file://t/scripts/breakpoint.pl', '-n', 20, '--', encode_base64('$_[0] > 7')], {
    state       => 'enabled',
    id          => 2,
});

command_is(['breakpoint_set', '-t', 'conditional', '-f', 'file://t/scripts/breakpoint.pl', '-n', 4], {
    apperr      => 4,
    code        => 3,
    message     => 'Condition required for setting a conditional breakpoint.',
});

breakpoint_list_is([
    {
        id          => 0,
        type        => 'line',
        state       => 'enabled',
        filename    => abs_uri('t/scripts/breakpoint.pl'),
        lineno      => '12',
        expression  => '',
    },
    {
        id          => 1,
        type        => 'line',
        state       => 'enabled',
        filename    => abs_uri('t/scripts/breakpoint.pl'),
        lineno      => '4',
        expression  => 'should_break()',
    },
    {
        id          => 2,
        type        => 'line',
        state       => 'enabled',
        filename    => abs_uri('t/scripts/breakpoint.pl'),
        lineno      => '20',
        expression  => '$_[0] > 7',
    },
]);

command_is(['breakpoint_get', '-d', 1], {
    breakpoint => {
        id          => 1,
        type        => 'line',
        state       => 'enabled',
        filename    => abs_uri('t/scripts/breakpoint.pl'),
        lineno      => '4',
        expression  => 'should_break()',
    },
});

command_is(['run'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'run',
    filename    => undef,
    lineno      => undef,
});

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

command_is(['eval', encode_base64('$i')],{
    command => 'eval',
    result  => {
        type        => 'int',
        value       => '10',
    },
});

send_command('run');

command_is(['stack_get'], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/breakpoint.pl'),
            where       => 'main::arg_break',
            lineno      => '20',
        },
        {
            level       => '1',
            type        => 'file',
            filename    => abs_uri('t/scripts/breakpoint.pl'),
            where       => 'main',
            lineno      => '9',
        },
    ],
});

done_testing();
