#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/args.pl');

send_command('run');

command_is(['property_get', '-c', 2, '-n', '$_[0]'], {
    command => 'property_get',
    property  => {
        name        => '$_[0]',
        fullname    => '$_[0]',
        type        => 'string',
        constant    => '0',
        children    => '0',
        value       => 'foo',
    },
});

send_command('run');

command_is(['property_get', '-c', 2, '-n', '$_[1]'], {
    command => 'property_get',
    property  => {
        name        => '$_[1]',
        fullname    => '$_[1]',
        type        => 'int',
        constant    => '0',
        children    => '0',
        value       => 5,
    },
});

command_is(['property_get', '-c', 2, '-d', 1, '-n', '$_[1]'], {
    command => 'property_get',
    property  => {
        name        => '$_[1]',
        fullname    => '$_[1]',
        type        => 'int',
        constant    => '0',
        children    => '0',
        value       => 7,
    },
});

command_is(['property_get', '-c', 2, '-d', 2, '-n', '$_[1]'], {
    command => 'property_get',
    property  => {
        name        => '$_[1]',
        fullname    => '$_[1]',
        type        => 'undef',
        constant    => '0',
        children    => '0',
        value       => undef,
    },
});

send_command('run');

command_is(['property_get', '-c', 2, '-n', '$_[0]'], {
    command => 'property_get',
    property  => {
        name        => '$_[0]',
        fullname    => '$_[0]',
        type        => 'HASH',
        constant    => '0',
        children    => '1',
        numchildren => 1,
        value       => undef,
        childs      => [
            {
                name        => '->{a}',
                fullname    => '$_[0]->{a}',
                type        => 'HASH',
                constant    => '0',
                children    => '1',
                numchildren => '1',
                page        => 0,
                pagesize    => 10,
                value       => undef,
                childs      => [],
            },
        ],
    },
});

command_is(['property_get', '-c', 2, '-n', '$_[0]->{a}'], {
    command => 'property_get',
    property  => {
        name        => '$_[0]->{a}',
        fullname    => '$_[0]->{a}',
        type        => 'HASH',
        constant    => '0',
        children    => '1',
        numchildren => 1,
        value       => undef,
        childs      => [
            {
                name        => '->{b}',
                fullname    => '$_[0]->{a}->{b}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                value       => 3,
            },
        ],
    },
});

command_is(['property_get', '-c', 2, '-n', '$_[0]{a}'], {
    command => 'property_get',
    property  => {
        name        => '$_[0]{a}',
        fullname    => '$_[0]{a}',
        type        => 'HASH',
        constant    => '0',
        children    => '1',
        numchildren => 1,
        value       => undef,
        childs      => [
            {
                name        => '->{b}',
                fullname    => '$_[0]{a}->{b}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                value       => 3,
            },
        ],
    },
});

command_is(['property_get', '-c', 2, '-n', '$_[1]'], {
    command => 'property_get',
    property  => {
        name        => '$_[1]',
        fullname    => '$_[1]',
        type        => 'ARRAY',
        constant    => '0',
        children    => '1',
        numchildren => 2,
        value       => undef,
        childs      => [
            {
                name        => '->[0]',
                fullname    => '$_[1]->[0]',
                type        => 'int',
                constant    => '0',
                children    => '0',
                value       => 1,
            },
            {
                name        => '->[1]',
                fullname    => '$_[1]->[1]',
                type        => 'ARRAY',
                constant    => '0',
                children    => '1',
                numchildren => '1',
                page        => 0,
                pagesize    => 10,
                value       => undef,
                childs      => [],
            },
        ],
    },
});

command_is(['property_get', '-c', 2, '-n', '$_[1]->[1]'], {
    command => 'property_get',
    property  => {
        name        => '$_[1]->[1]',
        fullname    => '$_[1]->[1]',
        type        => 'ARRAY',
        constant    => '0',
        children    => '1',
        numchildren => 1,
        value       => undef,
        childs      => [
            {
                name        => '->[0]',
                fullname    => '$_[1]->[1]->[0]',
                type        => 'int',
                constant    => '0',
                children    => '0',
                value       => 2,
            },
        ],
    },
});

command_is(['property_get', '-c', 2, '-n', '$_[1][1]'], {
    command => 'property_get',
    property  => {
        name        => '$_[1][1]',
        fullname    => '$_[1][1]',
        type        => 'ARRAY',
        constant    => '0',
        children    => '1',
        numchildren => 1,
        value       => undef,
        childs      => [
            {
                name        => '->[0]',
                fullname    => '$_[1][1]->[0]',
                type        => 'int',
                constant    => '0',
                children    => '0',
                value       => 2,
            },
        ],
    },
});

command_is(['property_get', '-c', 2, '-n', '$c[1][1]'], {
    apperr  => 4,
    code    => 300,
    message => 'Property $c[1][1] doesn\'t identify an arg',
    command => 'property_get',
});

done_testing();
