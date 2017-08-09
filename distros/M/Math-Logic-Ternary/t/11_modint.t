# Copyright (c) 2012-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Tests for Math::ModInt conversions of Math::Logic::Ternary::Word

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/11_modint.t'

use strict;
use Test::More;
use Math::BigInt;
use Math::Logic::Ternary qw(:all);

if (!eval { require Math::ModInt; Math::ModInt->import('mod'); 1 }) {
    plan(skip_all => 'Math::ModInt not available');
}
plan tests => 43;

my $w3 = ternary_word(0, mod(14, 27));
isa_ok($w3, 'Math::Logic::Ternary::Word');  # 1
is($w3->as_int, -13);                   # 2
is($w3->Trits + 0, 3);                  # 3

my $mi = $w3->as_modint;
isa_ok($mi, 'Math::ModInt');            # 4
is($mi->signed_residue, -13);           # 5
is($mi->modulus, 27);                   # 6
my $x3 = $w3->convert_modint($mi);
is($x3->as_int, -13);                   # 7

$mi = $w3->as_modint_u;
isa_ok($mi, 'Math::ModInt');            # 8
is($mi->residue, 26);                   # 9
is($mi->modulus, 27);                   # 10
$x3 = $w3->convert_modint_u($mi);
is($x3->as_int_u, 26);                  # 11

$mi = $w3->as_modint_v;
isa_ok($mi, 'Math::ModInt');            # 12
is($mi->residue, 14);                   # 13
is($mi->modulus, 27);                   # 14
$x3 = $w3->convert_modint_v($mi);
is($x3->as_int_v, 14);                  # 15

my $w81 = word81('%_math_logic_ternary_example');
my @bn = map { Math::BigInt->new($_) } qw(
      7924403659155387360664747340120077670
      7949527980713363009967190112668370939
     -4249183491892571091952613622287165761
    443426488243037769948249630619149892803
);

my $mib = $w81->as_modint;
isa_ok($mib, 'Math::ModInt');           # 16
is($mib->signed_residue, $bn[0]);       # 17
is($mib->modulus,        $bn[3]);       # 18
my $x81 = $w81->convert_modint($mib);
is($x81->as_int,         $bn[0]);       # 19

$mib = $w81->as_modint_u;
isa_ok($mib, 'Math::ModInt');           # 20
is($mib->residue,        $bn[1]);       # 21
is($mib->modulus,        $bn[3]);       # 22
$x81 = $w81->convert_modint_u($mib);
is($x81->as_int_u,       $bn[1]);       # 23

$mib = $w81->as_modint_v;
isa_ok($mib, 'Math::ModInt');           # 24
is($mib->signed_residue, $bn[2]);       # 25
is($mib->modulus,        $bn[3]);       # 26
$x81 = $w81->convert_modint_v($mib);
is($x81->as_int_v,       $bn[2]);       # 27

my $t = ternary_trit(mod(2, 3));
isa_ok($t, 'Math::Logic::Ternary::Trit');  # 28
is($t->as_int, -1);                     # 29

my $tmi = $t->as_modint;
isa_ok($tmi, 'Math::ModInt');           # 30
is($tmi->signed_residue, -1);           # 31
is($tmi->modulus, 3);                   # 32
$tmi = false->as_modint;
isa_ok($tmi, 'Math::ModInt');           # 33
is($tmi->signed_residue, -1);           # 34
is($tmi->modulus, 3);                   # 35

my $r;
$r = eval { Math::Logic::Ternary::Trit->from_modint(1) };
ok(!defined $r);                        # 36
like($@, qr/^modular integer with modulus 3 expected /);  # 37
$r = eval { Math::Logic::Ternary::Trit->from_modint(mod(1, 2)) };
ok(!defined $r);                        # 38
like($@, qr/^modular integer with modulus 3 expected /);  # 39

$r = eval { ternary_word(0, mod(1, 2)) };
ok(!defined $r);                        # 40
like($@, qr/^modulus is not a power of 3 /);  # 41
$r = eval { ternary_word(3, mod(1, 9)) };
ok(!defined $r);                        # 42
like($@, qr/^wrong modulus for this size, expected 27 /);  # 43

__END__
