#!/usr/bin/env perl

use warnings;
use strict;

use Crypt::Rijndael;
use Crypt::Cipher;
use File::KDBX::XS;

use Benchmark qw(:all :hireswallclock);
use Test::More;

my $iterations  = shift // 50;

my $rounds      = 500_000;
my $key         = "\1" x 32;
my $seed        = "\1" x 16;
my $expected    = pack('H*', '3f7dfb512060cc8be094cd259c7ff03c');

sub xs {
    my $result = File::KDBX::KDF::AES::_transform_half_xs($key, $seed, $rounds);
    return $result;
}

sub cryptx {
    my $cipher = Crypt::Cipher->new('AES', $key);
    my $result = $seed;
    for (my $i = 0; $i < $rounds; ++$i) {
        $result = $cipher->encrypt($result);
    }
    return $result;
}

sub crypt_rijndael {
    my $cipher = Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_ECB());
    my $result = $seed;
    for (my $i = 0; $i < $rounds; ++$i) {
        $result = $cipher->encrypt($result);
    }
    return $result;
}

my $r = xs();
is $r, $expected, 'AES KDF transform works' or diag explain unpack('H*', $r);
is $r, cryptx(), 'XS transform agrees with CryptX';
is $r, crypt_rijndael(), 'XS transform agrees with Crypt::Rijndael';

done_testing;

my $timings = timethese($iterations, {
    crypt_rijndael  => \&crypt_rijndael,
    cryptx          => \&cryptx,
    xs              => \&xs,
});
cmpthese($timings);
