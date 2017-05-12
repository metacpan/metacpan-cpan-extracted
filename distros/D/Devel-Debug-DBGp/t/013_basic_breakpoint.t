#!/usr/bin/perl

use t::lib::Test;

use MIME::Base64 qw(encode_base64);

run_debugger('t/scripts/breakpoint.pl');

# file defaults to current file (not in spec)
command_is(['breakpoint_set', '-t', 'line', '-n', 4], {
    state       => 'enabled',
    id          => 0,
});

command_is(['breakpoint_set', '-t', 'line', '-f', 'file://t/scripts/breakpoint.pl', '-n', 6], {
    apperr  => 4,
    code    => 203,
    message => 'Line 6 isn\'t breakable',
    command => 'breakpoint_set',
});

command_is(['breakpoint_set', '-t', 'conditional', '-f', 'file://t/scripts/breakpoint.pl', '-n', 6, '--', encode_base64('0')], {
    apperr  => 4,
    code    => 203,
    message => 'Line 6 isn\'t breakable',
    command => 'breakpoint_set',
});

command_is(['run'], {
    reason      => 'ok',
    status      => 'break',
    command     => 'run',
    filename    => undef,
    lineno      => undef,
});

done_testing();
