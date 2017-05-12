# Copyright (c) 2013 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 10_synopsis.t 13 2013-10-09 20:37:30Z demetri $

# Checking synopsis examples

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/10_synopsis.t'

#########################

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::MyUtils;
BEGIN {
    use_or_bail('Math::BigRat');
    plan tests => 14;
}
use Math::Polynomial::Multivariate;

#########################

my $two = Math::Polynomial::Multivariate->const(2);
my $x   = Math::Polynomial::Multivariate->var('x');
my $xy  = Math::Polynomial::Multivariate->
                monomial(1, {'x' => 1, 'y' => 1});
my $pol = $x**2 + $xy - $two;
is("$pol", '-2 + x^2 + x*y');   # 1

my @mon = $pol->as_monomials;
is_deeply(\@mon, [[-2, {}], [1, {x => 2}], [1, {x => 1, y => 1}]]);     # 2
my $n_terms = $pol->as_monomials;
is($n_terms, '3');      # 3

my $rat = Math::BigRat->new('-1/3');
my $c   = Math::Polynomial::Multivariate->const($rat);
my $y   = $c->var('y');
my $lin = $y - $c;
is("$lin" , '1/3 + y'); # 4

my $zero = $c - $c;           # zero polynomial on rationals
my $null = $c->null;          # dito

my $p = $c->monomial($rat, { 'a' => 2, 'b' => 1 });
is("$p", '-1/3*a^2*b'); # 5
my $f = $p->coefficient({'a' => 2, 'b' => 1});
is("$f", '-1/3');       # 6
my $q = $p->subst('a', $c);
is("$q", '-1/27*b');    # 7
my $v = $p->evaluate({'a' => 6, 'b' => -1});
is("$v", '12'); # 8

my @vars = $pol->variables;
is("@vars", 'x y');     # 9
my @exp = $pol->exponents_of('x');
is("@exp", '0 1 2');    # 10
my $r   = $pol->factor_of('x', 1);
is("$r", 'y');  # 11
my $d = $pol->degree;
is("$d", '2');  # 12
my $z = $zero->degree;
ok($z < -999999999);    # 13

my $pd = $pol->partial_derivative('x');
is("$pd", '2*x + y');   # 14

__END__
