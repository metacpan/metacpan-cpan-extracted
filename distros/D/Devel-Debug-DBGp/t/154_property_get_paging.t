#!/usr/bin/perl

use t::lib::Test;

$ENV{DBGP_PERL_IGNORE_PADWALKER} = 1;

run_debugger('t/scripts/pagination.pl');

send_command('run');

command_is(['property_get', '-n', '@afoo'], {
    command  => 'property_get',
    property => {
        name        => '@afoo',
        fullname    => '@afoo',
        type        => 'ARRAY',
        numchildren => '26',
        page        => 0,
        pagesize    => 10,
        value       => undef,
        childs      => [map
            +{
                name        => sprintf('[%d]', $_),
                fullname    => sprintf('$afoo[%d]', $_),
                type        => 'string',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => chr(ord('a') + $_),
            }, (0 .. 9),
        ],
    },
});

command_is(['property_get', '-n', '@afoo', '-p', 2], {
    command  => 'property_get',
    property => {
        name        => '@afoo',
        fullname    => '@afoo',
        type        => 'ARRAY',
        numchildren => '26',
        page        => 2,
        pagesize    => 10,
        value       => undef,
        childs      => [map
            +{
                name        => sprintf('[%d]', $_),
                fullname    => sprintf('$afoo[%d]', $_),
                type        => 'string',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => chr(ord('a') + $_),
            }, (20 .. 25),
        ],
    },
});

command_is(['property_get', '-n', '@afoo', '-p', 3], {
    command  => 'property_get',
    property => {
        name        => '@afoo',
        fullname    => '@afoo',
        type        => 'ARRAY',
        numchildren => '26',
        page        => 3,
        pagesize    => 10,
        value       => undef,
        childs      => [],
    },
});

command_is(['property_get', '-n', '$afoo', '-p', 2], {
    command  => 'property_get',
    property => {
        name        => '$afoo',
        fullname    => '$afoo',
        type        => 'ARRAY',
        numchildren => '26',
        page        => 2,
        pagesize    => 10,
        value       => undef,
        childs      => [map
            +{
                name        => sprintf('->[%d]', $_),
                fullname    => sprintf('$afoo->[%d]', $_),
                type        => 'string',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => chr(ord('a') + $_),
            }, (20 .. 25),
        ],
    },
});

command_is(['property_get', '-n', '%hfoo'], {
    command  => 'property_get',
    property => {
        name        => '%hfoo',
        fullname    => '%hfoo',
        type        => 'HASH',
        numchildren => '26',
        page        => 0,
        pagesize    => 10,
        value       => undef,
        childs      => [map
            +{
                name        => sprintf('{%s}', chr($_ + ord('a'))),
                fullname    => sprintf('$hfoo{%s}', chr($_ + ord('a'))),
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => $_,
            }, (0 .. 9),
        ],
    },
});

command_is(['property_get', '-n', '%hfoo', '-p', 2], {
    command  => 'property_get',
    property => {
        name        => '%hfoo',
        fullname    => '%hfoo',
        type        => 'HASH',
        numchildren => '26',
        page        => 2,
        pagesize    => 10,
        value       => undef,
        childs      => [map
            +{
                name        => sprintf('{%s}', chr($_ + ord('a'))),
                fullname    => sprintf('$hfoo{%s}', chr($_ + ord('a'))),
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => $_,
            }, (20 .. 25),
        ],
    },
});

command_is(['property_get', '-n', '%hfoo', '-p', 3], {
    command  => 'property_get',
    property => {
        name        => '%hfoo',
        fullname    => '%hfoo',
        type        => 'HASH',
        numchildren => '26',
        page        => 3,
        pagesize    => 10,
        value       => undef,
        childs      => [],
    },
});

command_is(['property_get', '-n', '$hfoo', '-p', 2], {
    command  => 'property_get',
    property => {
        name        => '$hfoo',
        fullname    => '$hfoo',
        type        => 'HASH',
        numchildren => '26',
        page        => 2,
        pagesize    => 10,
        value       => undef,
        childs      => [map
            +{
                name        => sprintf('->{%s}', chr($_ + ord('a'))),
                fullname    => sprintf('$hfoo->{%s}', chr($_ + ord('a'))),
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => $_,
            }, (20 .. 25),
        ],
    },
});

done_testing();
