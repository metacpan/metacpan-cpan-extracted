# Copyright (c) 2009-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Basic tests.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/01_basics.t'

#########################

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed looks_like_number);
use Math::BigInt;
BEGIN { plan tests => 45 };
use Math::ModInt qw(mod divmod);
ok(1);          # module loaded

#########################

sub check_mod {
    my ($obj, $r, $mod) = @_;
    my $ref = ref $obj;
    my $got =
        !defined $obj?              'undef':
        !$ref &&
        looks_like_number($obj)?    "number $obj":
        !$ref?                      qq{scalar "$obj"}:
        !blessed($obj)?             "unblessed $ref ref":
        !$obj->isa('Math::ModInt')? "alien $ref object":
        !$obj->is_defined?          'Math::ModInt->undefined':
        $mod != $obj->modulus ||
        $r   != $obj->residue?      "$obj":
        '';
    if ('' ne $got) {
        print "# expected mod($r, $mod), got $got\n";
        return 0;
    }
    return 1;
}

my $a = mod(32, 127);
ok(check_mod($a, 32, 127));

my $b = $a->new(99);
ok(check_mod($b, 99, 127));

my $bb = $b;
$bb += 1;
ok(check_mod($bb, 100, 127));
ok($bb != $b);

my $c = $a + $b;
ok(check_mod($c, 4, 127));

my $d = $a**2 - $b/$a;
ok(check_mod($d, 120, 127));

my $e = $d + 0;
ok(check_mod($e, 120, 127));
my $bi = Math::BigInt->new('4');
my $bool;

ok($d == $e);
$bool = $d != $e;
ok(!$bool);
ok($c != $d);
ok($c == 4);
ok($c == 131);
ok(4 == $c);
ok($c != 5);
ok($c != 132);
ok(5 != $c);
ok($c == $bi);
ok($bi != $d);

my $f = mod(4, 128);
ok($c != $f);
$bool = $c == $f;
ok(!$bool);

++$f;
ok(check_mod($f, 5, 128));
ok($e != $f);
$bool = $e == $f;
ok(!$bool);

$f = $d->inverse;
ok(check_mod($f, 18, 127));

if ($f) {
    $bool = 1;
}
else {
    $bool = 0;
}
ok($bool);
$bool = !$f;
ok(!$bool);

$f = mod(0, 127);
if ($f) {
    $bool = 1;
}
else {
    $bool = 0;
}
ok(!$bool);
$bool = !$f;
ok($bool);

my $m = $d->modulus;
ok(127 == $m);

my $r = $d->residue;
ok(120 == $r);

my $s = $c->signed_residue;
ok(4 == $s);
$s = $d->signed_residue;
ok(-7 == $s);

my $t = "$a";
ok('mod(32, 127)' eq $t);

my @sr = map { mod($_, 100)->signed_residue } 49, 50, 51;
is("@sr", '49 -50 -49');

my @cr = map { mod($_, 100)->centered_residue } 49, 50, 51;
is("@cr", '49 50 -49');

my @qr = divmod(123, 45);
is(0+@qr, 2);
is($qr[0], 2);
ok(check_mod($qr[1], 33, 45));

@qr = $qr[1]->new2(-123);
is(0+@qr, 2);
is($qr[0], -3);
ok(check_mod($qr[1], 12, 45));

@qr = Math::ModInt->new2(45, 6);
is(0+@qr, 2);
is($qr[0], 7);
ok(check_mod($qr[1], 3, 6));

__END__
