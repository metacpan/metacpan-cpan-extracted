#!/usr/bin/perl

# RSA Encryption example by Phil Massyn (www.massyn.net)
# July 10th 2013

# Modified by Daniel Șuteu (09 January 2017):
#  - `e` is now randomly chosen, such that gcd(e, phi(n)) = 1
#  - simplifications in the encryption/decryption of a message

use 5.010;
use strict;

use lib qw(../lib);

use Math::AnyNum qw(max irand invmod powmod gcd);
use Math::Prime::Util qw(random_strong_prime);

my $message = "Hello, world!";

# == key generation

# We chose the number of bits such that p*q > m
my $bits = max(128, 4 * length($message) + 2);

my $p = random_strong_prime($bits);
my $q = random_strong_prime($bits);

say "p = $p";
say "q = $q";

my $n = $p * $q;
my $phi = ($p - 1) * ($q - 1);

# == choosing `e`
#<<<
    my $e;
    do {
        $e = irand(65537, $n);
    } until (
                $e   <  $phi
        and gcd($e,     $phi  ) == 1
        and gcd($e - 1, $p - 1) == 2
        and gcd($e - 1, $q - 1) == 2
    );
#>>>

say "e = $e";

# == computing `d`
my $d = invmod($e, $phi);    # note that AnyNum understands BigInt

say "d = $d";

# == encryption
my $m = Math::AnyNum->new('1' . unpack('b*', $message), 2);

say "m = $m";

my $c = powmod($m, $e, $n);

say "c = $c";

# == decryption
my $M = powmod($c, $d, $n);

say "M = $M";

my $decoded = pack('b*', substr($M->as_bin, 1));

if ($decoded ne $message) {
    die "Decryption failed: <<$decoded>> != <<$message>>\n";
}

say $decoded;
