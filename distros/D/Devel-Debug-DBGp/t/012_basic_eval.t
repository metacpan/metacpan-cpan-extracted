#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

run_debugger('t/scripts/base.pl');

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

command_is(['eval', encode_base64('{a => [1, 2], b => 7}')], {
    command => 'eval',
    result  => {
        name        => '{a => [1, 2], b => 7}',
        fullname    => '{a => [1, 2], b => 7}',
        type        => 'HASH',
        constant    => '0',
        children    => '1',
        numchildren => '2',
        value       => undef,
        childs      => [
            {
                name        => '->{a}',
                fullname    => '{a => [1, 2], b => 7}->{a}',
                type        => 'ARRAY',
                constant    => '0',
                children    => '1',
                numchildren => '2',
                value       => undef,
            },
            {
                name        => '->{b}',
                fullname    => '{a => [1, 2], b => 7}->{b}',
                type        => 'int',
                constant    => '0',
                children    => '0',
                value       => '7',
            },
        ],
    },
});

my $res = send_command('eval', '--', encode_base64('$i +'));
parsed_response_is($res, {
    command => 'eval',
    code    => 206,
    apperr  => 4,
});
like($res->message, qr{^Error in eval: syntax error at \(eval \d+\)\[blib/lib/dbgp-helper/perl5db.pl:\d+\] line 1, at EOF});

done_testing();
