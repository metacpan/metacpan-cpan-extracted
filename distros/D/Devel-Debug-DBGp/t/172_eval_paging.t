#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

$ENV{DBGP_PERL_IGNORE_PADWALKER} = 1;

run_debugger('t/scripts/pagination.pl');

send_command('run');

command_is(['eval', '-p', 2, '--', encode_base64('@afoo')], {
    command  => 'eval',
    result   => {
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

command_is(['eval', '-p', 2, '--', encode_base64('$hfoo')], {
    command  => 'eval',
    result   => {
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
