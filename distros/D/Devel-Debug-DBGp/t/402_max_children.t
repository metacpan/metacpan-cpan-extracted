#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/variables.pl');

command_is(['feature_set', '-n', 'max_children', '-v', '1'], {
    feature => 'max_children',
    success => 1,
});

send_command('run');

command_is(['property_get', '-n', '%foo'], {
    command  => 'property_get',
    property => {
        name        => '%foo',
        fullname    => '%foo',
        type        => 'HASH',
        constant    => '0',
        children    => '1',
        numchildren => '3',
        page        => 0,
        pagesize    => 1,
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
        ],
    },
});

command_is(['property_value', '-n', '@foo'], {
    command     => 'property_value',
    name        => '@foo',
    fullname    => '@foo',
    type        => 'ARRAY',
    constant    => '0',
    children    => '1',
    numchildren => '3',
    page        => 0,
    pagesize    => 1,
    value       => undef,
    childs      => [
        {
            name        => '[0]',
            fullname    => '$foo[0]',
            type        => 'int',
            constant    => '0',
            children    => '0',
            numchildren => '0',
            value       => '1',
        },
    ],
});

done_testing();
