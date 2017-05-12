#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

$ENV{DBGP_PERL_IGNORE_PADWALKER} = 1;

run_debugger('t/scripts/variables.pl');

send_command('run');

command_is(['property_get', '-n', '$foo'], {
    command  => 'property_get',
    property => {
        name        => '$foo',
        fullname    => '$foo',
        type        => 'int',
        constant    => '0',
        children    => '0',
        value       => '123',
    },
});

command_is(['property_set', '-n', '$foo', '--', encode_base64('125')], {
    command  => 'property_set',
    success  => 1,
});

command_is(['property_get', '-n', '$foo'], {
    command  => 'property_get',
    property => {
        name        => '$foo',
        fullname    => '$foo',
        type        => 'int',
        constant    => '0',
        children    => '0',
        value       => '125',
    },
});

command_is(['property_set', '-n', '$foo', '--', encode_base64('"abc"')], {
    command  => 'property_set',
    success  => 1,
});

command_is(['property_get', '-n', '$foo'], {
    command  => 'property_get',
    property => {
        name        => '$foo',
        fullname    => '$foo',
        type        => 'string',
        constant    => '0',
        children    => '0',
        value       => 'abc',
    },
});

command_is(['property_set', '-n', '$foo', '-t', 'string', '--', encode_base64('def')], {
    command  => 'property_set',
    success  => 1,
});

command_is(['property_get', '-n', '$foo'], {
    command  => 'property_get',
    property => {
        name        => '$foo',
        fullname    => '$foo',
        type        => 'string',
        constant    => '0',
        children    => '0',
        value       => 'def',
    },
});

command_is(['property_get', '-n', '%foo'], {
    command  => 'property_get',
    property => {
        name        => '%foo',
        fullname    => '%foo',
        type        => 'HASH',
        constant    => '0',
        children    => '1',
        numchildren => '3',
        value       => undef,
        childs      => [
            {
                name        => '{a}',
                fullname    => '$foo{a}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => '1',
            },
            {
                name        => '{b}',
                fullname    => '$foo{b}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => '2',
            },
            {
                name        => '{c}',
                fullname    => '$foo{c}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => '3',
            },
        ],
    },
});

command_is(['property_set', '-n', '%foo', '--', encode_base64('(a => 2, b => 3)')], {
    command  => 'property_set',
    success  => 1,
});

command_is(['property_get', '-n', '%foo'], {
    command  => 'property_get',
    property => {
        name        => '%foo',
        fullname    => '%foo',
        type        => 'HASH',
        constant    => '0',
        children    => '1',
        numchildren => '2',
        value       => undef,
        childs      => [
            {
                name        => '{a}',
                fullname    => '$foo{a}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => '2',
            },
            {
                name        => '{b}',
                fullname    => '$foo{b}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => '3',
            },
        ],
    },
});

command_is(['property_set', '-n', '$foo', '--', encode_base64('(aaa')], {
    apperr  => 4,
    code    => 207,
    message => "syntax error\n",
    command => 'property_set',
});

command_is(['property_set', '-n', '$foo{b}', '--', encode_base64('"def"')], {
    command  => 'property_set',
    success  => 1,
});

command_is(['property_get', '-n', '%foo'], {
    command  => 'property_get',
    property => {
        name        => '%foo',
        fullname    => '%foo',
        type        => 'HASH',
        constant    => '0',
        children    => '1',
        numchildren => '2',
        value       => undef,
        childs      => [
            {
                name        => '{a}',
                fullname    => '$foo{a}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => '2',
            },
            {
                name        => '{b}',
                fullname    => '$foo{b}',
                type        => 'string',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => 'def',
            },
        ],
    },
});

done_testing();
