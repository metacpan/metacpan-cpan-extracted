# Copyright (c) 2007-2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 03_expressions.t 64 2009-06-17 20:01:21Z demetri $

# Checking arithmetic operators and expressions.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/03_expressions.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 207 };
use Math::Polynomial 1.000;
ok(1);  # module loaded

#########################

sub has_coeff {
    my $p = shift;
    if (!ref($p) || !$p->isa('Math::Polynomial')) {
        print
            '# expected Math::Polynomial object, got ',
            ref($p)? ref($p): defined($p)? qq{"$p"}: 'undef', "\n";
        return 0;
    }
    my @coeff = $p->coeff;
    if (@coeff != @_ || grep {$coeff[$_] != $_[$_]} 0..$#coeff) {
        print
            '# expected coefficients (',
            join(', ', @_), '), got (', join(', ', @coeff), ")\n";
        return 0;
    }
    return 1;
}

my $p = Math::Polynomial->new(-0.25, 0, 1.25);
my $q = $p->new(-0.25, 0, 0.25);
my $r = $p->new(-1, 2);
my $mr = $p->new(-0.5, 1);
my $s = $p->new(0.5, 0.5);
my $c = $p->new(-0.5);
my $zp = $p->new;

my $bool = !$p;
ok(!$bool);             # !p is false
ok(defined $bool);      # !p is defined

$bool = !$c;
ok(!$bool);             # !c is false
ok(defined $bool);      # !c is defined

ok($zp->degree < 0);    # zp is the zero polynomial
$bool = !$zp;
ok($bool);              # !zp is true

$bool = 0;
while ($p) {
    $bool = 1;
    last;
}
ok($bool);              # p is true;

$bool = 1;
while ($zp) {
    $bool = 0;
    last;
}
ok($bool);              # zp is false;

ok(!$p->is_zero);
ok($p->is_nonzero);
ok($zp->is_zero);
ok(!$zp->is_nonzero);

my $pp = $p->new(-0.25, 0, 1.25);

$bool = $p == $p;
ok($bool);              # p == p
$bool = $p == $pp;
ok($bool);              # p == pp
$bool = $p == $q;
ok(!$bool);             # not p == q
ok(defined $bool);      # defined p == q
$bool = $p == $r;
ok(!$bool);             # not p == r
ok(defined $bool);      # defined p == r

$bool = $p != $p;
ok(!$bool);             # not p != p
ok(defined $bool);      # defined p != p
$bool = $p != $pp;
ok(!$bool);             # not p != pp
ok(defined $bool);      # defined p != pp
$bool = $p != $q;
ok($bool);              # p != q
$bool = $p != $r;
ok($bool);              # p != r

my $qq = -$p;
ok(has_coeff($qq, 0.25, 0, -1.25));     # -p
$qq = -$zp;
ok(has_coeff($qq));                     # -0

$qq = $p + $q;
ok(has_coeff($qq, -0.5, 0, 1.5));       # p + q
$qq = $p + $r;
ok(has_coeff($qq, -1.25, 2, 1.25));     # p + r
$qq = $r + $p;
ok(has_coeff($qq, -1.25, 2, 1.25));     # r + p
$qq = $p + $zp;
ok(has_coeff($qq, -0.25, 0, 1.25));     # p + 0
$qq = $zp + $p;
ok(has_coeff($qq, -0.25, 0, 1.25));     # 0 + p

$qq = $p - $q;
ok(has_coeff($qq, 0, 0, 1));            # p - q
$qq = $p - $pp;
ok(has_coeff($qq));                     # p - p
$qq = $p - $r;
ok(has_coeff($qq, 0.75, -2, 1.25));     # p - r
$qq = $r - $p;
ok(has_coeff($qq, -0.75, 2, -1.25));    # r - p
$qq = $p - $zp;
ok(has_coeff($qq, -0.25, 0, 1.25));     # p - 0
$qq = $zp - $p;
ok(has_coeff($qq, 0.25, 0, -1.25));     # 0 - p

$qq = $p * $q;
ok(has_coeff($qq, 1/16, 0, -3/8, 0, 5/16));     # p * q
$qq = $q * $p;
ok(has_coeff($qq, 1/16, 0, -3/8, 0, 5/16));     # q * p
$qq = $p * $r;
ok(has_coeff($qq, 0.25, -0.5, -1.25, 2.5));     # p * r
$qq = $r * $p;
ok(has_coeff($qq, 0.25, -0.5, -1.25, 2.5));     # r * p
$qq = $p * $c;
ok(has_coeff($qq, 1/8, 0, -5/8));               # p * c
$qq = $c * $p;
ok(has_coeff($qq, 1/8, 0, -5/8));               # c * p
$qq = $p * $zp;
ok(has_coeff($qq));                     # p * 0
$qq = $zp * $p;
ok(has_coeff($qq));                     # 0 * p

$qq = $p / $q;
ok(has_coeff($qq, 5));                  # p / q
$qq = $p / $r;
ok(has_coeff($qq, 5/16, 5/8));          # p / r
$qq = $p / $mr;
ok(has_coeff($qq, 5/8, 5/4));           # p / mr
$qq = $p / $c;
ok(has_coeff($qq, 0.5, 0, -2.5));       # p / c
$qq = eval { $p / $zp };
ok(!defined $qq);                       # not defined p / 0
ok($@ =~ /division by zero polynomial/);
$qq = $r / $p;
ok(has_coeff($qq));                     # r / p
$qq = $r / $s;
ok(has_coeff($qq, 4));                  # r / s
$qq = $c / $p;
ok(has_coeff($qq));                     # c / p
$qq = $zp / $p;
ok(has_coeff($qq));                     # zp / p
$qq = eval { $zp / $zp };
ok(!defined $qq);                       # not defined 0 / 0
ok($@ =~ /division by zero polynomial/);

$qq = $p % $q;
ok(has_coeff($qq, 1));                  # p % q
$qq = $p % $r;
ok(has_coeff($qq, 1/16));               # p % r
$qq = $p % $mr;
ok(has_coeff($qq, 1/16));               # p % mr
$qq = $p % $c;
ok(has_coeff($qq));                     # p % c
$qq = eval { $p % $zp };
ok(!defined $qq);                       # not defined p % 0
ok($@ =~ /division by zero polynomial/);
$qq = $r % $p;
ok(has_coeff($qq, -1, 2));              # r % p
$qq = $r % $s;
ok(has_coeff($qq, -3));                 # r % s
$qq = $c % $p;
ok(has_coeff($qq, -0.5));               # c % p
$qq = $zp % $p;
ok(has_coeff($qq));                     # zp % p
$qq = eval { $zp % $zp };
ok(!defined $qq);                       # not defined 0 % 0
ok($@ =~ /division by zero polynomial/);

$qq = $p->mmod($q);
ok(has_coeff($qq, 0.25));               # p mmod q
$qq = $p->mmod($r);
ok(has_coeff($qq, 0.25));               # p mmod r
$qq = $p->mmod($mr);
ok(has_coeff($qq, 1/16));               # p mmod mr
$qq = $p->mmod($c);
ok(has_coeff($qq));                     # p mmod c
$qq = eval { $p->mmod($zp) };
ok(!defined $qq);                       # not defined p mmod 0
ok($@ =~ /division by zero polynomial/);
$qq = $r->mmod($p);
ok(has_coeff($qq, -1, 2));              # r mmod p
$qq = $r->mmod($s);
ok(has_coeff($qq, -1.5));               # r mmod s
$qq = $c->mmod($p);
ok(has_coeff($qq, -0.5));               # c mmod p
$qq = $zp->mmod($p);
ok(has_coeff($qq));                     # zp mmod p
$qq = eval { $zp->mmod($zp) };
ok(!defined $qq);                       # not defined 0 mmod 0
ok($@ =~ /division by zero polynomial/);

my $rr;
($qq, $rr) = $p->divmod($q);
ok(has_coeff($qq, 5));                  # p / q
ok(has_coeff($rr, 1));                  # p % q
($qq, $rr) = $p->divmod($r);
ok(has_coeff($qq, 5/16, 5/8));          # p / r
ok(has_coeff($rr, 1/16));               # p % r
($qq, $rr) = $p->divmod($mr);
ok(has_coeff($qq, 5/8, 5/4));           # p / mr
ok(has_coeff($rr, 1/16));               # p % mr
($qq, $rr) = $p->divmod($c);
ok(has_coeff($qq, 0.5, 0, -2.5));       # p / c
ok(has_coeff($rr));                     # p % c
($qq, $rr) = eval { $p->divmod($zp) };
ok(!defined $qq);                       # not defined p / 0
ok(!defined $rr);                       # not defined p % 0
ok($@ =~ /division by zero polynomial/);
($qq, $rr) = $r->divmod($p);
ok(has_coeff($qq));                     # r / p
ok(has_coeff($rr, -1, 2));              # r % p
($qq, $rr) = $r->divmod($s);
ok(has_coeff($qq, 4));                  # r / s
ok(has_coeff($rr, -3));                 # r % s
($qq, $rr) = $c->divmod($p);
ok(has_coeff($qq));                     # c / p
ok(has_coeff($rr, -0.5));               # c % p
($qq, $rr) = $zp->divmod($p);
ok(has_coeff($qq));                     # zp / p
ok(has_coeff($rr));                     # zp % p
($qq, $rr) = eval { $zp->divmod($zp) };
ok(!defined $qq);                       # not defined 0 / 0
ok(!defined $rr);                       # not defined 0 % 0
ok($@ =~ /division by zero polynomial/);

$qq = $p->add_const(0);
ok(has_coeff($qq, -0.25, 0, 1.25));     # p + 0
$qq = $p->add_const(1);
ok(has_coeff($qq, 0.75, 0, 1.25));      # p + 1
$qq = eval { $p + 1 };
ok(has_coeff($qq, 0.75, 0, 1.25));      # p + 1
$qq = eval { 1 + $p };
ok(has_coeff($qq, 0.75, 0, 1.25));      # 1 + p

$qq = $p->sub_const(0);
ok(has_coeff($qq, -0.25, 0, 1.25));     # p - 0
$qq = $p->sub_const(1);
ok(has_coeff($qq, -1.25, 0, 1.25));     # p - 1
$qq = eval { $p - 1 };
ok(has_coeff($qq, -1.25, 0, 1.25));     # p - 1
$qq = eval { 1 - $p };
ok(has_coeff($qq, 1.25, 0, -1.25));     # 1 - p
$qq = $zp->sub_const(1);
ok(has_coeff($qq, -1));                 # 0 - 1

$qq = $p->mul_const(0);
ok(has_coeff($qq));                     # p * 0
$qq = $p->mul_const(1);
ok(has_coeff($qq, -0.25, 0, 1.25));     # p * 1
$qq = $p->mul_const(2);
ok(has_coeff($qq, -0.5, 0, 2.5));       # p * 2

$qq = eval { $p->div_const(0) };
ok(!defined $qq);                       # not defined p / 0
ok($@ =~ /division by zero/);
$qq = $p->div_const(1);
ok(has_coeff($qq, -0.25, 0, 1.25));     # p / 1
$qq = $p->div_const(2);
ok(has_coeff($qq, -1/8, 0, 5/8));       # p / 2

$qq = $p ** 0;
ok(has_coeff($qq, 1));                  # p ** 0
$qq = $p ** 1;
ok(has_coeff($qq, -0.25, 0, 1.25));     # p ** 1
$qq = $p ** 2;
ok(has_coeff($qq, 1/16, 0, -5/8, 0, 25/16));    # p ** 2
$qq = $p ** 3;
ok(has_coeff($qq, -1/64, 0, 15/64, 0, -75/64, 0, 125/64));      # p ** 3
$qq = $c ** 0;
ok(has_coeff($qq, 1));                  # c ** 0
$qq = $c ** 1;
ok(has_coeff($qq, -0.5));               # c ** 1
$qq = $c ** 2;
ok(has_coeff($qq, 0.25));               # c ** 2
$qq = $c ** 3;
ok(has_coeff($qq, -1/8));               # c ** 3
$qq = $zp ** 0;
ok(has_coeff($qq, 1));                  # 0 ** 0
$qq = $zp ** 1;
ok(has_coeff($qq));                     # 0 ** 1
$qq = $zp ** 2;
ok(has_coeff($qq));                     # 0 ** 2
$qq = $zp ** 3;
ok(has_coeff($qq));                     # 0 ** 3
$qq = eval { 3 ** $p };
ok(!defined $qq);                       # not defined 3 ** p
ok($@ =~ /wrong operand type/);
$qq = eval { $p ** 0.5 };
ok(!defined $qq);                       # not defined p ** 0.5
ok($@ =~ /non-negative integer argument expected/);
$qq = eval { $p ** $p };
ok(!defined $qq);                       # not defined p ** p
ok($@ =~ /non-negative integer argument expected/);

$qq = $p->pow_mod(0, $q);
ok(has_coeff($qq, 1));                  # p ** 0 % q
$qq = $p->pow_mod(1, $q);
ok(has_coeff($qq, 1));                  # p ** 1 % q
$qq = $p->pow_mod(2, $q);
ok(has_coeff($qq, 1));                  # p ** 2 % q
$qq = $p->pow_mod(3, $q);
ok(has_coeff($qq, 1));                  # p ** 3 % q
$qq = $p->pow_mod(0, $r);
ok(has_coeff($qq, 1));                  # p ** 0 % r
$qq = $p->pow_mod(1, $r);
ok(has_coeff($qq, 1/16));               # p ** 1 % r
$qq = $p->pow_mod(2, $r);
ok(has_coeff($qq, 1/256));              # p ** 2 % r
$qq = $p->pow_mod(0, $c);
ok(has_coeff($qq));                     # p ** 0 % c
$qq = $p->pow_mod(1, $c);
ok(has_coeff($qq));                     # p ** 1 % c
$qq = $p->pow_mod(2, $c);
ok(has_coeff($qq));                     # p ** 2 % c
$qq = eval { $p->pow_mod(0, $zp) };
ok(!defined $qq);                       # not defined p ** 0 % 0
ok($@ =~ /division by zero polynomial/);
$qq = eval { $p->pow_mod(1, $zp) };
ok(!defined $qq);                       # not defined p ** 1 % 0
ok($@ =~ /division by zero polynomial/);
$qq = eval { $p->pow_mod(2, $zp) };
ok(!defined $qq);                       # not defined p ** 2 % 0
ok($@ =~ /division by zero polynomial/);
$qq = $r->pow_mod(0, $q);
ok(has_coeff($qq, 1));                  # r ** 0 % q
$qq = $r->pow_mod(1, $q);
ok(has_coeff($qq, -1, 2));              # r ** 1 % q
$qq = $r->pow_mod(2, $q);
ok(has_coeff($qq, 5, -4));              # r ** 2 % q
$qq = $r->pow_mod(3, $q);
ok(has_coeff($qq, -13, 14));            # r ** 3 % q
$qq = $c->pow_mod(0, $q);
ok(has_coeff($qq, 1));                  # c ** 0 % q
$qq = $c->pow_mod(1, $q);
ok(has_coeff($qq, -0.5));               # c ** 1 % q
$qq = $c->pow_mod(2, $q);
ok(has_coeff($qq, 0.25));               # c ** 2 % q
$qq = $zp->pow_mod(0, $q);
ok(has_coeff($qq, 1));                  # 0 ** 0 % q
$qq = $zp->pow_mod(1, $q);
ok(has_coeff($qq));                     # 0 ** 1 % q
$qq = $zp->pow_mod(2, $q);
ok(has_coeff($qq));                     # 0 ** 2 % q
$qq = eval { $zp->pow_mod(0, $zp) };
ok(!defined $qq);                       # not defined 0 ** 0 % 0
ok($@ =~ /division by zero polynomial/);
$qq = eval { $zp->pow_mod(1, $zp) };
ok(!defined $qq);                       # not defined 0 ** 1 % 0
ok($@ =~ /division by zero polynomial/);
$qq = eval { $zp->pow_mod(2, $zp) };
ok(!defined $qq);                       # not defined 0 ** 2 % 0
ok($@ =~ /division by zero polynomial/);

$qq = $p << 3;
ok(has_coeff($qq, 0, 0, 0, -0.25, 0, 1.25));    # p << 3
$qq = $c << 3;
ok(has_coeff($qq, 0, 0, 0, -0.5));      # c << 3
$qq = $zp << 3;
ok(has_coeff($qq));                     # 0 << 3
$qq = $p << 0;
ok(has_coeff($qq, -0.25, 0, 1.25));     # p << 0
$qq = $zp << 0;
ok(has_coeff($qq));                     # 0 << 0

$qq = $p >> 3;
ok(has_coeff($qq));                     # p >> 3
$qq = $p >> 2;
ok(has_coeff($qq, 1.25));               # p >> 2
$qq = $p >> 0;
ok(has_coeff($qq, -0.25, 0, 1.25));     # p >> 0
$qq = $zp >> 2;
ok(has_coeff($qq));                     # 0 >> 0
$qq = $zp >> 0;
ok(has_coeff($qq));                     # 0 >> 0

$pp = $p->new(11, 22, 33, 44, 55);
my $ok = 1;
foreach my $w (0..6) {
    foreach my $b (0..6) {
        my @c = grep {defined $_} (11, 22, 33, 44, 55)[$b..$b+$w-1];
        $qq = $pp->slice($b, $w);
        $ok ||= has_coeff($qq, @c);
    }
}
ok($ok);                                # slice

$qq = $p->nest($q);
ok(has_coeff($qq, -11/64, 0, -5/32, 0, 5/64));  # p(q)
$qq = $q->nest($p);
ok(has_coeff($qq, -15/64, 0, -5/32, 0, 25/64)); # q(p)
$qq = $p->nest($zp);
ok(has_coeff($qq, -0.25));              # q(0)
$qq = $zp->nest($p);
ok(has_coeff($qq));                     # 0(p)

$bool = $q->is_monic;
ok(!$bool);                             # q is not monic
$pp = $q->monize;
ok(has_coeff($pp, -1, 0, 1));           # monize q
$bool = $pp->is_monic;
ok($bool);                              # x**2-1 is monic
$qq = $pp->monize;
ok($qq == $pp);                         # monize monic pp
$qq = $c->monize;
ok(has_coeff($qq, 1));                  # monize c
$qq = eval { $zp->monize };
ok(has_coeff($qq));                     # monize 0
$bool = $zp->is_monic;
ok(defined $bool);                      # is_monic defined for zp
ok(!$bool);                             # zp is not monic

# assignment operators

$pp = Math::Polynomial->new(1, 10);
$qq = $pp;
$pp += $pp;
ok(has_coeff($pp, 2, 20));              # += working
ok(has_coeff($qq, 1, 10));              # += no side effects

$pp = $p && $q;
ok($pp == $q);                          # && operator long path

$pp = $zp && $q;
ok($pp == $zp);                         # && operator short path

$pp = $p || $q;
ok($pp == $p);                          # || operator short path

$pp = $zp || $q;
ok($pp == $q);                          # || operator long path

# diagnostics

ok(10_000 == $Math::Polynomial::max_degree);

$Math::Polynomial::max_degree = 9;

$pp = $p->new(0, -1, 0, 1);
$qq = eval { $pp ** 3 };
ok(has_coeff($qq, 0, 0, 0, -1, 0, 3, 0, -3, 0, 1));
$pp = $p->new(0, 4, 0, -5, 0, 1);
$qq = eval { $pp ** 2 };
ok(!defined($qq) && $@ && $@ =~ /exponent too large/);
$qq = eval {
    local $Math::Polynomial::max_degree;
    $pp ** 2
};
ok(defined($qq) && $q->isa('Math::Polynomial'));

$qq = eval { $pp << 4 };
ok(has_coeff($qq, 0, 0, 0, 0, 0, 4, 0, -5, 0, 1));
$qq = eval { $pp << 5 };
ok(!defined($qq) && $@ && $@ =~ /exponent too large/);
$qq = eval {
    local $Math::Polynomial::max_degree;
    $pp << 5
};
ok(defined($qq) && $q->isa('Math::Polynomial'));

$qq = eval { $p->divmod($p) };
ok(!defined($qq) && $@ && $@ =~ /array context required/);

__END__
