#!/usr/bin/env perl

use strict;
use warnings;

use Linux::WireGuard;

use Test::More;
use Test::FailWarnings;

my $str = Linux::WireGuard::generate_private_key();
like($str, qr<.>, 'private key generated');

is(
    length($str),
    length( Linux::WireGuard::generate_private_key() ),
    '2 private keys are same length',
);

my $pub = Linux::WireGuard::generate_public_key($str);

is(
    $pub,
    Linux::WireGuard::generate_public_key($str),
    'public key generated the same twice',
);

is( length($pub), length($str), 'public & private are same length' );

{
    my $str = Linux::WireGuard::generate_preshared_key();
    like($str, qr<.>, 'preshared key generated');

    is(
        length($str),
        length( Linux::WireGuard::generate_preshared_key() ),
        '2 preshared keys are same length',
    );
}

done_testing;
