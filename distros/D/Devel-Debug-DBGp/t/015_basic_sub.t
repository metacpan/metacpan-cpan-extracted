#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

run_debugger('t/scripts/function_args_return.pl');

send_command('run');

eval_value_is('$add_1_2', 3);
eval_value_is('$pass_add_2_3', 5);
eval_value_is('$pass_mutate', 4);
eval_value_is('$scalar_context', '');
eval_value_is('$list_context', 1);
eval_value_is('$void_context', undef);

eval_value_is('$scalar_scalar', 42);
command_is(['eval', encode_base64('@scalar_list')], {
    command => 'eval',
    result  => {
        name        => '@scalar_list',
        fullname    => '@scalar_list',
        type        => 'ARRAY',
        constant    => '0',
        children    => '1',
        numchildren => '1',
        value       => undef,
        childs      => [
            {
                name        => '[0]',
                fullname    => '$scalar_list[0]',
                type        => 'int',
                constant    => '0',
                children    => '0',
                value       => '42',
            },
        ],
    },
});

eval_value_is('$array_scalar', 2);
command_is(['eval', encode_base64('@array_list')], {
    command => 'eval',
    result  => {
        name        => '@array_list',
        fullname    => '@array_list',
        type        => 'ARRAY',
        constant    => '0',
        children    => '1',
        numchildren => '2',
        value       => undef,
        childs      => [
            {
                name        => '[0]',
                fullname    => '$array_list[0]',
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => '42',
            },
            {
                name        => '[1]',
                fullname    => '$array_list[1]',
                type        => 'int',
                constant    => '0',
                children    => '0',
                value       => '43',
            },
        ],
    },
});

eval_value_is('$list_scalar', 43);
command_is(['eval', encode_base64('@list_list')], {
    command => 'eval',
    result  => {
        name        => '@list_list',
        fullname    => '@list_list',
        type        => 'ARRAY',
        constant    => '0',
        children    => '1',
        numchildren => '2',
        value       => undef,
        childs      => [
            {
                name        => '[0]',
                fullname    => '$list_list[0]',
                type        => 'int',
                constant    => '0',
                children    => '0',
                numchildren => '0',
                value       => '42',
            },
            {
                name        => '[1]',
                fullname    => '$list_list[1]',
                type        => 'int',
                constant    => '0',
                children    => '0',
                value       => '43',
            },
        ],
    },
});

eval_value_is('$void_scalar', undef);
command_is(['eval', encode_base64('@void_list')], {
    command => 'eval',
    result  => {
        name        => '@void_list',
        fullname    => '@void_list',
        type        => 'ARRAY',
        constant    => '0',
        children    => '0',
        numchildren => '0',
        value       => undef,
        childs      => [],
    },
});

if ($] >= 5.010001) {
    eval_value_is('test_lvalue()', 77);
}

done_testing();
