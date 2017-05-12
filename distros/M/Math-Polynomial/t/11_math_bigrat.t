# Copyright (c) 2007-2016 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 11_math_bigrat.t 129 2016-08-08 17:27:26Z demetri $

# Checking coefficient space compatibility with Math::BigRat.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/11_math_bigrat.t'

#########################

use strict;
use warnings;
use Test;
use lib 't/lib';
use Test::MyUtils qw(report_version use_or_bail);
BEGIN {
    use_or_bail('Math::BigRat', 0.16);
    report_version('Math::BigInt');
    plan tests => 8;
}
use Math::Polynomial 1.000;
ok(1);  # modules loaded

my $c0 = Math::BigRat->new('-1/2');
my $c1 = Math::BigRat->new('0');
my $c2 = Math::BigRat->new('3/2');
my $p  = Math::Polynomial->new($c0, $c1, $c2);

my $x1 = Math::BigRat->new('1/2');
my $x2 = Math::BigRat->new('2/3');
my $x3 = Math::BigRat->new('1');
my $y1 = Math::BigRat->new('-1/8');
my $y2 = Math::BigRat->new('1/6');
my $y3 = Math::BigRat->new('1');

ok($y1 == $p->evaluate($x1));
ok($y2 == $p->evaluate($x2));
ok($y3 == $p->evaluate($x3));

my $q = $p->interpolate([$x1, $x2, $x3], [$y1, $y2, $y3]);
ok($p == $q);
if ($p != $q) {
    print map { "# $_\n" }
        q[-] x 64,
        'WARNING:  Your Math::BigRat module might need an upgrade.',
        '          Rational arithmetic on your system might be broken.',
        'SEE ALSO: https://rt.cpan.org/Public/Bug/Display.html?id=114004',
        q[-] x 64;
}

my $x = $p->monomial(1);
my $y = eval { $x - $p->coeff_one };
ok(ref($y) && $y->isa('Math::Polynomial'));
ok(1 == $y->degree);
ok($p->coeff_zero == $y->evaluate($x3));

#########################

__END__
