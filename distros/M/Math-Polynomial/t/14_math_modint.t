# Copyright (c) 2007-2010 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 14_math_modint.t 94 2010-09-06 10:08:00Z demetri $

# Checking coefficient space compatibility with Math::ModInt.
# Most examples are taken from t/12_gf3.t.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/14_math_modint.t'

use strict;
use Test;
use lib 't/lib';
use Test::MyUtils;
BEGIN {
    use_or_bail('Math::ModInt', undef, ['mod']);
    plan tests => 11;
}
use Math::Polynomial 1.000;
ok(1);  # Math::Polynomial loaded

#########################

sub enum {
    use integer;
    my ($n, $m) = @_;
    my @r = ();
    while ($n) {
        push @r, $n % $m;
        $n /= $m;
    }
    return map { mod($_, $m) } @r;
}

sub is_primitive {
    my ($p, $m) = @_;
    my $n = 1;
    my $one = $p->coeff_one;
    my $max = $m ** $p->degree - 1;
    foreach my $n (grep { !($max % $_) } 1..$max) {
        my $q = $p->monomial($n)->sub_const($one);
        if (!($q % $p)) {
            return $n == $max;
        }
    }
    return 0;
}

Math::Polynomial->string_config({
    convert_coeff => sub {('o', 'e', '-e')[$_[0]->residue]},
    sign_of_coeff => sub {$_[0]->signed_residue},
    fold_sign     => 1,
    leading_plus  => '+ ',
});

my $mod = 3;
my $ir3 = 8;
my $pr3 = 4;
my $nil = mod(0, $mod);
my $one = mod(1, $mod);
my $two = mod(2, $mod);
my $mo3 = $mod ** 3;

my $p = Math::Polynomial->new($nil, $one, $two);
ok("$p", '(- x^2 + x)');                # new & stringification

my $q = $p->new($one, $two, $nil, $two, $one);
ok("$q", '(+ x^4 - x^3 - x + e)');      # new & stringification

my $r = $p->gcd($q)->monize;
ok("$r", '(+ x - e)');                  # gcd & monize

my @monic1 = map { Math::Polynomial->new(enum($_, $mod)) } $mod..2*$mod-1;
my @monic3 = map { Math::Polynomial->new(enum($_, $mod)) } $mo3..2*$mo3-1;
my @irred3 = grep { my $p = $_; !grep { !($p % $_) } @monic1 } @monic3;

ok($ir3 == @irred3);                    # number of monic irreducibles

my @prim3 = grep { is_primitive($_, $mod) } @irred3;
ok($pr3 == @prim3);                     # number of monic primitives

my $ok = 1;
foreach my $gen (@prim3) {
    my $c1  = $gen->new($one);
    my $x   = $gen->new($nil, $one);
    my $exp = $x;
    foreach my $n (1..$mo3-2) {
        $ok &&= $c1 != $exp;
        ($exp *= $x) %= $gen;
    }
    $ok &&= $c1 == $exp;
}
ok($ok);        # primitive-ness

$ok = 1;
my @x = ($nil, $one, $two);
foreach my $y2 (@x) {
    foreach my $y1 (@x) {
        foreach my $y0 (@x) {
            my @y  = ($y0, $y1, $y2);
            my $ip = Math::Polynomial->interpolate(\@x, \@y);
            $ok &&= 3 == grep { $y[$_] == $ip->evaluate($x[$_]) } 0..2;
        }
    }
}
ok($ok);        # interpolations

my ($ok1, $ok2, $ok3) = (1, 1, 1);
my $gen = $prim3[0];
my $c1  = $gen ** 0;
foreach my $p (map { $gen->new(enum($_, $mod)) } 1..$mo3-2) {
    my $q = $p->pow_mod($mo3-2, $gen);
    my $r = $p->mul($q)->mod($gen);
    my $s = eval { $p->inv_mod($gen) };
    my ($d, $f) = ($gen->xgcd($p))[0, 2];
    $ok1 &&= $r->is_equal($c1);
    $ok2 &&= $q->is_equal($f->div($d));
    $ok3 &&= defined($s) && $q->is_equal($s);
}
ok($ok1);       # inverses using Little Fermat
ok($ok2);       # inverses using Chinese Remainder
ok($ok3);       # inverses using inv_mod

__END__
