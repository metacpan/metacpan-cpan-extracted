#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use File::KDBX::Entry;
use Test::More;

eval { require Pass::OTP } or plan skip_all => 'Pass::OTP required to test one-time-passwords';

my $secret_txt  = 'hello';
my $secret_b32  = 'NBSWY3DP';
my $secret_b64  = 'aGVsbG8=';
my $secret_hex  = '68656c6c6f';
my $when        = 1655488780;

for my $test (
    {
        name  => 'HOTP - Basic',
        input => {otp => "otpauth://hotp/Issuer:user?secret=${secret_b32}&issuer=Issuer"},
        codes => [qw(029578 825147 676217)],
        uri   => 'otpauth://hotp/Issuer:user?secret=NBSWY3DP&issuer=Issuer',
    },
    {
        name  => 'HOTP - Start from 42',
        input => {
            otp => "otpauth://hotp/Issuer:user?secret=${secret_b32}&issuer=Issuer",
            'HmacOtp-Counter' => 42,
        },
        codes => [qw(528783 171971 115730)],
        uri   => 'otpauth://hotp/Issuer:user?secret=NBSWY3DP&issuer=Issuer&counter=42',
    },
    {
        name  => 'HOTP - 7 digits',
        input => {otp => "otpauth://hotp/Issuer:user?secret=${secret_b32}&issuer=Issuer&digits=7"},
        codes => [qw(3029578 9825147 9676217)],
        uri   => 'otpauth://hotp/Issuer:user?secret=NBSWY3DP&issuer=Issuer&digits=7',
    },
    {
        name  => 'HOTP - KeePass 2 storage (Base32)',
        input => {'HmacOtp-Secret-Base32' => $secret_b32},
        codes => [qw(029578 825147 676217)],
        uri   => 'otpauth://hotp/KDBX:none?secret=NBSWY3DP&issuer=KDBX',
    },
    {
        name  => 'HOTP - KeePass 2 storage (Base64)',
        input => {'HmacOtp-Secret-Base64' => $secret_b64},
        codes => [qw(029578 825147 676217)],
        uri   => 'otpauth://hotp/KDBX:none?secret=NBSWY3DP&issuer=KDBX',
    },
    {
        name  => 'HOTP - KeePass 2 storage (Hex)',
        input => {'HmacOtp-Secret-Hex' => $secret_hex},
        codes => [qw(029578 825147 676217)],
        uri   => 'otpauth://hotp/KDBX:none?secret=NBSWY3DP&issuer=KDBX',
    },
    {
        name  => 'HOTP - KeePass 2 storage (Text)',
        input => {'HmacOtp-Secret' => $secret_txt},
        codes => [qw(029578 825147 676217)],
        uri   => 'otpauth://hotp/KDBX:none?secret=NBSWY3DP&issuer=KDBX',
    },
    {
        name  => 'HOTP - KeePass 2, start from 42',
        input => {'HmacOtp-Secret' => $secret_txt, 'HmacOtp-Counter' => 42},
        codes => [qw(528783 171971 115730)],
        uri   => 'otpauth://hotp/KDBX:none?secret=NBSWY3DP&issuer=KDBX&counter=42',
    },
    {
        name  => 'HOTP - Non-default attributes',
        input => {'HmacOtp-Secret' => $secret_txt, Title => 'Website', UserName => 'foo!?'},
        codes => [qw(029578 825147 676217)],
        uri   => 'otpauth://hotp/Website:foo%21%3F?secret=NBSWY3DP&issuer=Website',
    },
) {
    my $entry = File::KDBX::Entry->new;
    $entry->string($_ => $test->{input}{$_}) for keys %{$test->{input}};
    is $entry->hmac_otp_uri, $test->{uri}, "$test->{name}: Valid URI";
    for my $code (@{$test->{codes}}) {
        my $counter = $entry->string_value('HmacOtp-Counter') || 'undef';
        is $entry->hmac_otp, $code, "$test->{name}: Valid OTP ($counter)";
    }
}

for my $test (
    {
        name  => 'TOTP - Basic',
        input => {otp => "otpauth://totp/Issuer:user?secret=${secret_b32}&period=30&digits=6&issuer=Issuer"},
        code  => '875357',
        uri   => 'otpauth://totp/Issuer:user?secret=NBSWY3DP&issuer=Issuer',
    },
    {
        name  => 'TOTP - SHA256',
        input => {otp => "otpauth://totp/Issuer:user?secret=${secret_b32}&period=30&algorithm=SHA256"},
        code  => '630489',
        uri   => 'otpauth://totp/Issuer:user?secret=NBSWY3DP&issuer=Issuer&algorithm=SHA256',
    },
    {
        name  => 'TOTP - 60s period',
        input => {otp => "otpauth://totp/Issuer:user?secret=${secret_b32}&period=60&digits=6&issuer=Issuer"},
        code  => '647601',
        uri   => 'otpauth://totp/Issuer:user?secret=NBSWY3DP&issuer=Issuer&period=60',
    },
    {
        name  => 'TOTP - 7 digits',
        input => {otp => "otpauth://totp/Issuer:user?secret=${secret_b32}&period=30&digits=7&issuer=Issuer"},
        code  => '9875357',
        uri   => 'otpauth://totp/Issuer:user?secret=NBSWY3DP&issuer=Issuer&digits=7',
    },
    {
        name  => 'TOTP - Steam',
        input => {otp => "otpauth://totp/Issuer:user?secret=${secret_b32}&issuer=Issuer&encoder=steam"},
        code  => '55YH2',
        uri   => 'otpauth://totp/Issuer:user?secret=NBSWY3DP&issuer=Issuer&encoder=steam',
    },
    {
        name  => 'TOTP - KeePass 2 storage',
        input => {'TimeOtp-Secret-Base32' => $secret_b32},
        code  => '875357',
        uri   => 'otpauth://totp/KDBX:none?secret=NBSWY3DP&issuer=KDBX',
    },
    {
        name  => 'TOTP - KeePass 2 storage, SHA256',
        input => {'TimeOtp-Secret-Base32' => $secret_b32, 'TimeOtp-Algorithm' => 'HMAC-SHA-256'},
        code  => '630489',
        uri   => 'otpauth://totp/KDBX:none?secret=NBSWY3DP&issuer=KDBX&algorithm=SHA256',
    },
    {
        name  => 'TOTP - KeePass 2 storage, 60s period',
        input => {'TimeOtp-Secret-Base32' => $secret_b32, 'TimeOtp-Period' => '60'},
        code  => '647601',
        uri   => 'otpauth://totp/KDBX:none?secret=NBSWY3DP&issuer=KDBX&period=60',
    },
    {
        name  => 'TOTP - KeePass 2 storage, 7 digits',
        input => {'TimeOtp-Secret-Base32' => $secret_b32, 'TimeOtp-Length' => '7'},
        code  => '9875357',
        uri   => 'otpauth://totp/KDBX:none?secret=NBSWY3DP&issuer=KDBX&digits=7',
    },
    {
        name  => 'TOTP - Non-default attributes',
        input => {'TimeOtp-Secret-Base32' => $secret_b32, Title => 'Website', UserName => 'foo!?'},
        code  => '875357',
        uri   => 'otpauth://totp/Website:foo%21%3F?secret=NBSWY3DP&issuer=Website',
    },
) {
    my $entry = File::KDBX::Entry->new;
    $entry->string($_ => $test->{input}{$_}) for keys %{$test->{input}};
    is $entry->time_otp_uri, $test->{uri}, "$test->{name}: Valid URI";
    is $entry->time_otp(now => $when), $test->{code}, "$test->{name}: Valid OTP";
}

{
    my $entry = File::KDBX::Entry->new;
    $entry->string('TimeOtp-Secret-Base32' => $secret_b32);
    $entry->string('TimeOtp-Secret' => 'wat');
    my $warning = warning { $entry->time_otp_uri };
    like $warning, qr/Found multiple/, 'Alert if redundant secrets'
        or diag 'Warnings: ', explain $warning;
}

done_testing;
