#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/punctuation.pl');

send_command('run');

command_is(['context_get', '-c', 3], {
    command => 'context_get',
    values  => [
        {
            name        => '$!',
            value       => undef,
        },
        {
            name        => '$$',
        },
        {
            name        => '$&',
            value       => undef,
        },
        {
            name        => "\$'",
            value       => undef,
        },
        {
            name        => '@+',
            value       => undef,
        },
        {
            name        => '@-',
            value       => undef,
        },
        {
            name        => '$0',
            value       => 't/scripts/punctuation.pl',
        },
        {
            name        => '$?',
            value       => 0,
        },
        {
            name        => '$@',
            value       => undef,
        },
        {
            name        => '$_',
            value       => 'abc',
        },
        {
            name        => '$`',
            value       => undef,
        },
    ],
});

send_command('run');

command_is(['context_get', '-c', 3], {
    command => 'context_get',
    values  => [
        {
            name        => '$!',
            value       => undef,
        },
        {
            name        => '$$',
        },
        {
            name        => '$&',
            value       => undef,
        },
        {
            name        => "\$'",
            value       => undef,
        },
        {
            name        => '@+',
            value       => undef,
        },
        {
            name        => '@-',
            value       => undef,
        },
        {
            name        => '$0',
            value       => 't/scripts/punctuation.pl',
        },
        {
            name        => '$?',
            value       => 0,
        },
        {
            name        => '$@',
            value       => undef,
        },
        {
            name        => '$_',
            value       => 'abc',
        },
        {
            name        => '$`',
            value       => undef,
        },
    ],
});

send_command('run');

command_is(['context_get', '-c', 3], {
    command => 'context_get',
    values  => [
        {
            name        => '$!',
            value       => undef,
        },
        {
            name        => '$$',
        },
        {
            name        => '$&',
            value       => 'b',
        },
        {
            name        => "\$'",
            value       => 'c',
        },
        {
            name        => '@+',
            value       => undef,
        },
        {
            name        => '@-',
            value       => undef,
        },
        {
            name        => '$0',
            value       => 't/scripts/punctuation.pl',
        },
        {
            name        => '$?',
            value       => 0,
        },
        {
            name        => '$@',
            value       => undef,
        },
        {
            name        => '$_',
            value       => 'abc',
        },
        {
            name        => '$`',
            value       => 'a',
        },
    ],
});

done_testing();
