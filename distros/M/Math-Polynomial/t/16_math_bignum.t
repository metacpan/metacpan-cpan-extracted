# Copyright (c) 2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Checking coefficient space compatibility with Math::BigNum.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/16_math_bignum.t'

#########################

use strict;
use warnings;
use Test;
use lib 't/lib';
use Test::MyUtils qw(:comp report_version use_or_bail);
BEGIN {
    use_or_bail('Math::BigNum');
    plan tests => 8;
}
use Math::Polynomial 1.000;
ok(1);  # modules loaded

init_comp_check(qw(Math::Polynomial Math::BigNum));

my $c0 = Math::BigNum->new('-1/2');
my $c1 = Math::BigNum->new('0');
my $c2 = Math::BigNum->new('3/2');
my $p  = Math::Polynomial->new($c0, $c1, $c2);

my $x1 = Math::BigNum->new('1/2');
my $x2 = Math::BigNum->new('2/3');
my $x3 = Math::BigNum->new('1');
my $y1 = Math::BigNum->new('-1/8');
my $y2 = Math::BigNum->new('1/6');
my $y3 = Math::BigNum->new('1');

comp_ok($y1 == $p->evaluate($x1), 'y1');
comp_ok($y2 == $p->evaluate($x2), 'y2');
comp_ok($y3 == $p->evaluate($x3), 'y3');

my $q = $p->interpolate([$x1, $x2, $x3], [$y1, $y2, $y3]);
comp_ok($p == $q, 'interpolation');

my $x = $p->monomial(1);
my $y = eval { $x - $p->coeff_one };
comp_ok(ref($y) && $y->isa('Math::Polynomial'), 'isa');
comp_ok(1 == $y->degree, 'degree');
comp_ok($p->coeff_zero == $y->evaluate($x3), 'zero value');

#########################

__END__
