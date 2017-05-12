#!/usr/bin/perl

use t::lib::Test;

run_debugger('t/scripts/variables.pl');

send_command('run');

command_is(['property_get', '-n', '@foo', '-k', '[2]'], {
    command  => 'property_get',
    property => {
        name        => '[2]',
        fullname    => '$foo[2]',
        type        => 'int',
        constant    => '0',
        children    => '0',
        value       => '3',
    },
});

command_is(['property_get', '-n', '%foo', '-k', '{b}'], {
    command  => 'property_get',
    property => {
        name        => '{b}',
        fullname    => '$foo{b}',
        type        => 'int',
        constant    => '0',
        children    => '0',
        value       => '2',
    },
});

command_is(['property_get', '-n', '$aref', '-k', '->[1]'], {
    command  => 'property_get',
    property => {
        name        => '->[1]',
        fullname    => '$aref->[1]',
        type        => 'int',
        constant    => '0',
        children    => '0',
        value       => '2',
    },
});

command_is(['property_get', '-n', '$aref', '-k', '[1]'], {
    command  => 'property_get',
    property => {
        name        => '->[1]',
        fullname    => '$aref->[1]',
        type        => 'int',
        constant    => '0',
        children    => '0',
        value       => '2',
    },
});

done_testing();
