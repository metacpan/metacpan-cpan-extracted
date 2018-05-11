#!/usr/bin/perl

use t::lib::Test;

$ENV{DBGP_PERL_IGNORE_PADWALKER} = 1;

run_debugger('t/scripts/special_values.pl');

send_command('feature_set', '-n', 'max_depth', '-v', '5');
send_command('run');

command_is(['property_get', '-n', '$code'], {
    command  => 'property_get',
    property => {
        name        => '$code',
        fullname    => '$code',
        type        => 'CODE',
        numchildren => '0',
        page        => undef,
        pagesize    => undef,
        value       => undef,
        childs      => [],
    },
});

command_is(['property_get', '-n', '$scalar'], {
    command  => 'property_get',
    property => {
        name        => '$scalar',
        fullname    => '$scalar',
        type        => 'SCALAR',
        numchildren => '1',
        page        => 0,
        pagesize    => 10,
        value       => undef,
        childs      => [
            {
                name        => '->',
                fullname    => '${$scalar}',
                type        => 'string',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => 'a',
            },
        ],
    },
});

command_is(['property_get', '-n', '$ref'], {
    command  => 'property_get',
    property => {
        name        => '$ref',
        fullname    => '$ref',
        type        => 'REF',
        numchildren => '1',
        page        => 0,
        pagesize    => 10,
        value       => undef,
        childs      => [
            {
                name        => '->',
                fullname    => '${$ref}',
                type        => 'SCALAR',
                numchildren => '1',
                page        => 0,
                pagesize    => 10,
                value       => undef,
                childs      => [
                    {
                        name        => '->',
                        fullname    => '${${$ref}}',
                        type        => 'string',
                        constant    => '0',
                        children    => '0',
                        numchildren => '0',
                        value       => 'a',
                    },
                ],
            }
        ],
    },
});

command_is(['property_get', '-n', '$rx'], {
    command  => 'property_get',
    property => {
        name        => '$rx',
        fullname    => '$rx',
        type        => 'Regexp',
        numchildren => 0,
        page        => undef,
        pagesize    => undef,
        value       => $] < 5.014 ? '(?-xism:abc)' : '(?^:abc)',
        childs      => []
    },
});

command_is(['property_get', '-n', '$obj'], {
    command  => 'property_get',
    property => {
        name        => '$obj',
        fullname    => '$obj',
        type        => 'Object',
        numchildren => 1,
        page        => 0,
        pagesize    => 10,
        value       => undef,
        childs      => [
            {
                name        => '->{a}',
                fullname    => '$obj->{a}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => '1',
            },
        ],
    },
});

command_is(['property_get', '-n', '$ovl'], {
    command  => 'property_get',
    property => {
        name        => '$ovl',
        fullname    => '$ovl',
        type        => 'Overload',
        numchildren => 1,
        page        => 0,
        pagesize    => 10,
        value       => undef,
        childs      => [
            {
                name        => '->{b}',
                fullname    => '$ovl->{b}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => '2',
            },
        ],
    },
});

done_testing();
