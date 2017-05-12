#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/args.pl');

send_command('run');

command_is(['context_get', '-c', 2], {
    command => 'context_get',
    values  => [
        {
            name    => '$_[0]',
            value   => 'foo',
        },
        {
            name    => '$_[1]',
            value   => 7,
        },
    ],
});

send_command('run');

command_is(['context_get', '-c', 2], {
    command => 'context_get',
    values  => [
        {
            name    => '$_[0]',
            value   => 'bar',
        },
        {
            name    => '$_[1]',
            value   => 5,
        },
    ],
});

command_is(['context_get', '-c', 2, '-d', 1], {
    command => 'context_get',
    values  => [
        {
            name    => '$_[0]',
            value   => 'foo',
        },
        {
            name    => '$_[1]',
            value   => 7,
        },
    ],
});

command_is(['context_get', '-c', 2, '-d', 2], {
    command => 'context_get',
    values  => [
    ],
});

send_command('run');

command_is(['context_get', '-c', 2], {
    command => 'context_get',
    values  => [
        {
            name        => '$_[0]',
            fullname    => '$_[0]',
            type        => 'HASH',
            constant    => '0',
            children    => '1',
            numchildren => '1',
            page        => 0,
            pagesize    => 10,
            value       => undef,
            childs      => [],
        },
        {
            name        => '$_[1]',
            fullname    => '$_[1]',
            type        => 'ARRAY',
            constant    => '0',
            children    => '1',
            numchildren => '2',
            page        => 0,
            pagesize    => 10,
            value       => undef,
            childs      => [],
        },
    ],
});

send_command('run');

command_is(['context_get', '-c', 2], {
    command => 'context_get',
    values  => [
    ],
});

done_testing();
