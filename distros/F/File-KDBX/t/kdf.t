#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Constants qw(:kdf);
use File::KDBX::KDF;
use Test::More;

subtest 'AES KDF' => sub {
    my $kdf1 = File::KDBX::KDF->new(uuid => KDF_UUID_AES, seed => "\1" x 32, rounds => 10);
    my $result1 = $kdf1->transform("\2" x 32);
    is $result1, "\342\234cp\375\\p\253]\213\f\246\345\230\266\260\r\222j\332Z\204:\322 p\224mhm\360\222",
        'AES KDF basically works';

    like exception { $kdf1->transform("\2" x 33) }, qr/raw key must be 32 bytes/i,
        'Transformation requires valid arguments';
};

subtest 'Argon2 KDF' => sub {
    my $kdf1 = File::KDBX::KDF->new(
        uuid        => KDF_UUID_ARGON2D,
        salt        => "\2" x 32,
        iterations  => 2,
        parallelism => 2,
    );
    my $r1 = $kdf1->transform("\2" x 32);
    is $r1, "\352\333\247\347+x#\"C\340\224\30\316\350\3068E\246\347H\263\214V\310\5\375\16N.K\320\255",
        'Argon2D KDF works';

    my $kdf2 = File::KDBX::KDF->new(
        uuid        => KDF_UUID_ARGON2ID,
        salt        => "\2" x 32,
        iterations  => 2,
        parallelism => 3,
    );
    my $r2 = $kdf2->transform("\2" x 32);
    is $r2, "S\304\304u\316\311\202^\214JW{\312=\236\307P\345\253\323\313\23\215\247\210O!#F\16\1x",
        'Argon2ID KDF works';
};

done_testing;
