# Copyright (c) 2007-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Checking compatibility with some non-standard coefficient space.
# The particular space here is the three-element Galois field GF3.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/12_gf3.t'

package GF3;

use strict;
use warnings;

use overload
    'neg' => \&neg,
    '+'   => \&add,
    '-'   => \&sub_,
    '*'   => \&mul,
    '/'   => \&div,
    '**'  => \&pow,
    '""'  => \&as_string,
    '<=>' => \&cmp,
    fallback => undef;

my @space = map { my $int = $_; bless \$int } 0..2;
my @neg   = (0, 2, 1);
my @add   = ([0, 1, 2], [1, 2, 0], [2, 0, 1]);
my @sub   = ([0, 2, 1], [1, 0, 2], [2, 1, 0]);
my @mul   = ([0, 0, 0], [0, 1, 2], [0, 2, 1]);
my @div   = ([3, 0, 0], [3, 1, 2], [3, 2, 1]);
my @pow   = ([0, 0, 3], [1, 1, 3], [1, 2, 3]);
my @cmp   = ([0, -1, 1], [1, 0, 1], [-1, -1, 0]);

sub new  { $space[$_[1] % 3] }
sub neg  { $space[$neg[${$_[0]}]] }
sub add  { $space[$add[${$_[0]}]->[${$_[1]}]] }
sub sub_ { $space[$sub[${$_[0]}]->[${$_[1]}]] }
sub mul  { $space[$mul[${$_[0]}]->[${$_[1]}]] }
sub div  { $space[$div[${$_[0]}]->[${$_[1]}]] }
sub pow  { $space[$_[1]? $pow[${$_[0]}]->[1 & $_[1]]: 1] }

sub cmp { $cmp[${$_[0]}]->[${$_[1]}] }

sub as_string { ('o', 'e', '-e')[${$_[0]}] }

#########################

package main;

use strict;
use Test;
BEGIN { plan tests => 15 };
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
    return map { GF3->new($_) } @r;
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

Math::Polynomial->string_config( { fold_sign => 1, leading_plus => '+ ' } );

my $mod = 3;
my $ir3 = 8;
my $pr3 = 4;
my $nil = GF3->new(0);
my $one = GF3->new(1);
my $two = GF3->new(2);
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

$ok = 1;
$p = $c1;
foreach my $n (0 .. $mo3) {
    $q = $gen->exp_mod($n);
    $ok &&= $p->is_equal($q);
    $p = ($p << 1) % $gen;
}
ok($ok);        # exp_mod method in general

my $c2 = $c1->new($two);
$p = $c2->exp_mod(0);
ok($p->is_zero);
$p = $c2->exp_mod(1);
ok($p->is_zero);
$p = $c2->exp_mod(2);
ok($p->is_zero);

__END__
