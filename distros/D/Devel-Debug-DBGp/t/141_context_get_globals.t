#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/globals.pl');

send_command('run');

command_is(['context_get', '-c', 1], {
    command => 'context_get',
    values  => [
        {
            name        => '@fbar',
            fullname    => '@fbar',
            type        => 'ARRAY',
            constant    => '0',
            children    => '1',
            value       => undef,
        },
        {
            name        => '%fbaz',
            fullname    => '%fbaz',
            type        => 'HASH',
            constant    => '0',
            children    => '1',
            value       => undef,
        },
        {
            name        => '$ffoo',
            fullname    => '$ffoo',
            type        => 'int',
            constant    => '0',
            children    => '0',
            value       => 123,
        },
        $] < 5.010 ? () : (
            {
                name        => '$fundef',
                fullname    => '$fundef',
                type        => 'undef',
                constant    => '0',
                children    => '0',
                value       => undef,
            },
        ),
    ],
});

send_command('run');

command_is(['context_get', '-c', 1], {
    command => 'context_get',
    values  => [
    ],
});

done_testing();
