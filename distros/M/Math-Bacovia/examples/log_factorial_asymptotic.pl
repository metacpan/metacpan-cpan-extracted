#!/usr/bin/perl

# log(n) asymptotic approximation.
# Formula due to N. Batir.

use utf8;
use 5.014;

use Test::More;
plan tests => 2;

use lib qw(../lib);
use Math::Bacovia qw(:all);

my $n = Symbol('n', 10);

my $f = (((((Log(2) * Fraction(1,2)) + ((Log(Log(-1)) * Fraction(1,2)) + (Log(-i) * Fraction(1,2)))) + (Log($n) * $n)) + (-$n)) + (Log((((($n + Fraction(1,6)) + (Fraction(1,72) * Fraction(1,$n))) + (9871/(6531840 * $n**4))) - (((31 * (155520 * $n**3)) + (139 * (6480 * $n**2)))/(1007769600 * ($n**2 * $n**3))))) * Fraction(1,2)))->simple(full => 1);

say $f->numeric;

say $f->pretty;
say $f->simple->pretty;

is($f->numeric, '15.104412572997466273786772796276985827478707948');
is($f->simple->numeric, '15.104412572997466273786772796276985827478707948');

__END__
((-n) + ((1/2) * log(2)) + ((1/2) * log(log(-1))) + ((1/2) * log(-i)) + (log(n) * n) + ((1/2) * log((((1/6) - (((31/6480) * n^-2) + ((139/155520) * n^-3))) + ((1/72) * (1/n)) + ((1/6531840) * n^-4 * 9871) + n))))
((-n) + ((1/2) * log(2)) + ((1/2) * log(log(-1))) + ((1/2) * log(-i)) + (log(n) * n) + ((1/2) * log((((((1/12) + n)/(6 * n)) - (((31/6480) * n^-2) + ((139/155520) * n^-3))) + ((9871/6531840) * n^-4) + n))))
