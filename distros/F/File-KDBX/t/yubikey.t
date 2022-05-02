#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use Config;
use File::KDBX::Key::YubiKey;
use Test::More;

$^O eq 'MSWin32' and plan skip_all => 'Non-Windows required to test YubiKeys';

@ENV{qw(YKCHALRESP YKCHALRESP_FLAGS)}   = ($Config{perlpath}, testfile(qw{bin ykchalresp}));
@ENV{qw(YKINFO YKINFO_FLAGS)}           = ($Config{perlpath}, testfile(qw{bin ykinfo}));

{
    my ($pre, $post);
    my $key = File::KDBX::Key::YubiKey->new(
        pre_challenge   => sub { ++$pre  },
        post_challenge  => sub { ++$post },
    );
    my $resp;
    is exception { $resp = $key->challenge('foo') }, undef, 'Do not throw during non-blocking response';
    is $resp, "\xf0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", 'Get a non-blocking challenge response';
    is length($resp), 20, 'Response is the proper length';
    is $pre,  1, 'The pre-challenge callback is called';
    is $post, 1, 'The post-challenge callback is called';
}

{
    my $key = File::KDBX::Key::YubiKey->new;
    local $ENV{YKCHALRESP_MOCK} = 'error';
    like exception { $key->challenge('foo') }, qr/Yubikey core error:/i,
        'Throw if challenge-response program errored out';
}

{
    my $key = File::KDBX::Key::YubiKey->new;
    local $ENV{YKCHALRESP_MOCK} = 'usberror';
    like exception { $key->challenge('foo') }, qr/USB error:/i,
        'Throw if challenge-response program had a USB error';
}

{
    my $key = File::KDBX::Key::YubiKey->new(timeout => 0, device => 3, slot => 2);
    local $ENV{YKCHALRESP_MOCK} = 'block';

    like exception { $key->challenge('foo') }, qr/operation would block/i,
        'Throw if challenge would block but we do not want to wait';

    $key->timeout(1);
    like exception { $key->challenge('foo') }, qr/timed out/i,
        'Timeout while waiting for response';

    $key->timeout(-1);
    my $resp;
    is exception { $resp = $key->challenge('foo') }, undef,
        'Do not throw during blocking response';
    is $resp, "\xf0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0\0", 'Get a blocking challenge response';
}

{
    my $key = File::KDBX::Key::YubiKey->new(device => 0, slot => 1);
    is $key->name, 'YubiKey NEO FIDO v2.0.0 [123] (slot #1)',
        'Get name for a new, unscanned key';
    is $key->serial, 123, 'Get the serial number of the new key';
}

{
    my ($key, @other) = File::KDBX::Key::YubiKey->scan;
    is $key->name, 'YubiKey 4/5 OTP v3.0.1 [456] (slot #2)',
        'Find expected YubiKey';
    is $key->serial, 456, 'Get the serial number of the scanned key';
    is scalar @other, 0, 'Do not find any other YubiKeys';
}

{
    local $ENV{YKCHALRESP} = testfile(qw{bin nonexistent});
    local $ENV{YKCHALRESP_FLAGS} = undef;
    my $key = File::KDBX::Key::YubiKey->new;
    like exception { $key->challenge('foo') }, qr/failed to run|failed to receive challenge response/i,
        'Throw if the program failed to run';
}

done_testing;
