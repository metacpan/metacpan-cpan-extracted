# Copyright (c) 2007-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Checking compatibility with some non-standard coefficient spaces.
# The particular spaces here are the three- and four-element Galois
# fields GF3 and GF4.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/12_gf3_4.t'

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

{
my @space = map { my $int = $_; bless \$int } 0..2;
my @neg   = (0, 2, 1);
my @add   = ([0, 1, 2], [1, 2, 0], [2, 0, 1]);
my @sub   = ([0, 2, 1], [1, 0, 2], [2, 1, 0]);
my @mul   = ([0, 0, 0], [0, 1, 2], [0, 2, 1]);
my @div   = ([3, 0, 0], [3, 1, 2], [3, 2, 1]);
my @pow   = ([0, 0], [1, 1], [1, 2]);
my @cmp   = ([0, -1, 1], [1, 0, 1], [-1, -1, 0]);

sub new  { $space[$_[1] % 3] }
sub neg  { $space[$neg[${$_[0]}]] }
sub add  { $space[$add[${$_[0]}]->[${$_[1]}]] }
sub sub_ { $space[$sub[${$_[0]}]->[${$_[1]}]] }
sub mul  { $space[$mul[${$_[0]}]->[${$_[1]}]] }
sub div  { $space[$div[${$_[0]}]->[${$_[1]}]] }
sub pow  { $space[$_[1]? $pow[${$_[0]}]->[1 & $_[1]]: 1] }

sub cmp { $cmp[${$_[0]}]->[${$_[1]}] }
}

sub as_string { ('o', 'e', '-e')[${$_[0]}] }

sub card   { 3 }
sub irred3 { 8 }
sub prim3  { 4 }
sub char2  { 0 }

#########################

package GF4;

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

{
my @space = map { my $int = $_; bless \$int } 0..3;
my @neg   = (0, 1, 2, 3);
my @add   = ([0, 1, 2, 3], [1, 0, 3, 2], [2, 3, 0, 1], [3, 2, 1, 0]);
my @mul   = ([0, 0, 0, 0], [0, 1, 2, 3], [0, 2, 3, 1], [0, 3, 1, 2]);
my @div   = ([4, 0, 0, 0], [4, 1, 3, 2], [4, 2, 1, 3], [4, 3, 2, 1]);
my @pow   = ([0, 0, 0], [1, 1, 1], [1, 2, 3], [1, 3, 2]);
my @cmp   = ([0, -1, -1, -1], [1, 0, -1, -1], [1, 1, 0, -1], [1, 1, 1, 0]);

sub new  { $space[$_[1] % 4] }
sub neg  { $space[$neg[${$_[0]}]] }
sub add  { $space[$add[${$_[0]}]->[${$_[1]}]] }
sub sub_ { goto &add; }
sub mul  { $space[$mul[${$_[0]}]->[${$_[1]}]] }
sub div  { $space[$div[${$_[0]}]->[${$_[1]}]] }
sub pow  { $space[$_[1]? $pow[${$_[0]}]->[$_[1] % 3]: 1] }

sub cmp { $cmp[${$_[0]}]->[${$_[1]}] }
}

sub as_string { ${$_[0]} }

sub card   {  4 }
sub irred3 { 20 }
sub prim3  { 12 }
sub char2  {  1 }

#########################

package main;

use strict;
use Test;
BEGIN { plan tests => 35 };
use Math::Polynomial 1.000;
ok(1);  # Math::Polynomial loaded

#########################

sub enum {
    use integer;
    my ($class, $n) = @_;
    my $m = $class->card;
    my @r = ();
    while ($n) {
        push @r, $n % $m;
        $n /= $m;
    }
    return map { $class->new($_) } @r;
}

sub is_primitive {
    my ($p) = @_;
    my $m = $p->coeff_one->card;
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

sub is_in {
    my ($have, @want) = @_;
    foreach my $item (@want) {
        return 1 if $item eq $have;
    }
    return 0;
}

Math::Polynomial->string_config( { fold_sign => 1, leading_plus => '+ ' } );

foreach my $class (GF3::, GF4::) {

my $mod = $class->card;
my $ir3 = $class->irred3;
my $pr3 = $class->prim3;
my $nil = $class->new(0);
my $one = $class->new(1);
my $mi1 = $class->new(-1 % $mod);
my $mo3 = $mod ** 3;
my $ch2 = $class->char2;

my $p = Math::Polynomial->new($nil, $one, $mi1);
ok(is_in("$p", '(- x^2 + x)', '(+ 3 x^2 + x)'));    # new & stringification

my $q = $p->new($one, $mi1, $nil, $mi1, $one);
# new & stringification
ok(is_in("$q", '(+ x^4 - x^3 - x + e)', '(+ x^4 + 3 x^3 + 3 x + 1)'));

my $r = $p->gcd($q)->monize;
ok(is_in("$r", '(+ x - e)', '(+ 1)'));          # gcd & monize

my $mp = $p->mirror;
if ($ch2) {
    ok("$p", "$mp");
    ok($p->is_even);
    ok($p->is_odd);
}
else {
    ok("$p" ne "$mp");
    ok(!$p->is_even);
    ok(!$p->is_odd);
}

my @monic1 = map { Math::Polynomial->new(enum($class, $_)) } $mod..2*$mod-1;
my @monic3 = map { Math::Polynomial->new(enum($class, $_)) } $mo3..2*$mo3-1;
my @irred3 = grep { my $p = $_; !grep { !($p % $_) } @monic1 } @monic3;

ok(0+@irred3, $ir3);                    # number of monic irreducibles

my @prim3 = grep { is_primitive($_) } @irred3;
ok(0+@prim3, $pr3);                     # number of monic primitives

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
my @x = ($nil, $one, $mi1);
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
foreach my $p (map { $gen->new(enum($class, $_)) } 1..$mo3-2) {
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

my $c2 = $c1->new($mi1);
$p = $c2->exp_mod(0);
ok($p->is_zero);
$p = $c2->exp_mod(1);
ok($p->is_zero);
$p = $c2->exp_mod(2);
ok($p->is_zero);

}

__END__
