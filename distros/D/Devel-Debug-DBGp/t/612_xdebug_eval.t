#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

run_debugger('t/scripts/base.pl', 'Xdebug=property_without_value_tag');

command_is(['eval', encode_base64('$i')], {
    command => 'eval',
    result  => {
        name        => '$i',
        fullname    => '$i',
        type        => 'undef',
        constant    => '0',
        children    => '0',
        value       => undef,
    },
});

command_is(['eval', encode_base64('""')], {
    command => 'eval',
    result  => {
        name        => '""',
        fullname    => '""',
        type        => 'string',
        constant    => '0',
        children    => '0',
        value       => undef, # needs to be fixed in the client
    },
});

command_is(['eval', encode_base64('"a"')], {
    command => 'eval',
    result  => {
        name        => '"a"',
        fullname    => '"a"',
        type        => 'string',
        constant    => '0',
        children    => '0',
        value       => 'a',
    },
});

command_is(['eval', encode_base64('$i + 0')], {
    command => 'eval',
    result  => {
        name        => '$i + 0',
        fullname    => '$i + 0',
        type        => 'int',
        constant    => '0',
        children    => '0',
        value       => '0',
    },
});

done_testing();
