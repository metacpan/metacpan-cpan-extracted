# Copyright (c) 2013 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 03_bigrat.t 4 2013-06-01 20:56:56Z demetri $

# Checking synopsis examples

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/03_bigrat.t'

#########################

use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::MyUtils;
BEGIN {
    use_or_bail('Math::BigRat');
    plan tests => 6;
}
use Math::Polynomial::Multivariate;

#########################

my $one = Math::BigRat->new('1');
my $c   = Math::Polynomial::Multivariate->const($one);
my $x   = $c->var('x');
my $p   = ($x - $c) * ($x + $c);
is("$p", '-1 + x^2');                   # 1

my $q = ($x + $one) * ($x - $one) * $one - $p;
is("$q", '0');                          # 2

my $b;
$b = $c == $one;
is($b, !0);                             # 3
$b = $c != $one;
is($b, !1);                             # 4
$b = $c == $p;
is($b, !1);                             # 5
$b = $c != $p;
is($b, !0);                             # 6

__END__
