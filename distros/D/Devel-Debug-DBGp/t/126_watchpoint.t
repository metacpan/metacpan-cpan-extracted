#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

run_debugger('t/scripts/watchpoint.pl');

command_is(['breakpoint_set', '-t', 'watch', '--', encode_base64('$i')], {
    state       => 'enabled',
    id          => 0,
});

# a watchpoint which is a syntax error will never trigger
command_is(['breakpoint_set', '-t', 'watch', '--', encode_base64('$i +')], {
    state       => 'enabled',
    id          => 1,
});

command_is(['breakpoint_get', '-d', 0], {
    breakpoint => {
        id              => 0,
        type            => 'watch',
        state           => 'enabled',
        expression      => '$i',
    },
});

command_is(['breakpoint_get', '-d', 1], {
    breakpoint => {
        id              => 1,
        type            => 'watch',
        state           => 'enabled',
        expression      => '$i +',
    },
});

send_command('run');

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/watchpoint.pl'),
            where       => 'main',
            lineno      => '2',
        },
    ],
});

eval_value_is('$i', ' ');

send_command('run');

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/watchpoint.pl'),
            where       => 'main',
            lineno      => '3',
        },
    ],
});

eval_value_is('$i', 1);

send_command('run');

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/watchpoint.pl'),
            where       => 'main',
            lineno      => '5',
        },
    ],
});

eval_value_is('$i', 2);

command_is(['breakpoint_remove', '-d', 0], {
});

send_command('run');

command_is(['stack_get', '-d', 0], {
    command => 'stack_get',
    frames  => [
        {
            level       => '0',
            type        => 'file',
            filename    => abs_uri('t/scripts/watchpoint.pl'),
            where       => 'main',
            lineno      => '10',
        },
    ],
});

eval_value_is('$i', 4);

done_testing();
