# Copyright (c) 2019 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01_basics.t'

use strict;
use warnings;
use Math::Polynomial;
use Math::Polynomial::Cyclotomic qw(:all);

use Test::More tests => 17;

my $p1 = cyclo_poly(1);
is($p1->as_string, '(x - 1)');

my $p3 = cyclo_poly(3);
is($p3->as_string, '(x^2 + x + 1)');

my $p6 = cyclo_poly(6);
is($p6->as_string, '(x^2 - x + 1)');

my $p15 = cyclo_poly(15);
is($p15->as_string, '(x^8 - x^7 + x^5 - x^4 + x^3 - x + 1)');

my @f15 = cyclo_factors(15);
ok(4 == @f15 && $f15[-1] == $p15);

my $it = cyclo_poly_iterate();
is($it->()->as_string, '(x - 1)');
is($it->()->as_string, '(x + 1)');
is($it->()->as_string, '(x^2 + x + 1)');
is($it->()->as_string, '(x^2 + 1)');
is($it->()->as_string, '(x^4 + x^3 + x^2 + x + 1)');
is($it->()->as_string, '(x^2 - x + 1)');

$it = cyclo_factors_iterate();
my @f1 = $it->();
ok(@f1 == 1 && $f1[0] == $p1);
my @f2 = $it->();
ok(@f2 == 2 && $f2[0] == $p1);

my $p27 = $p3->cyclotomic(27);
ok($p27->degree == 18 && $p27->evaluate(1) == 3);

my @f27 = $p3->cyclo_factors(27);
ok(4 == @f27 && $f27[-1] == $p27);

$it = $p3->cyclo_poly_iterate(20);
my $p20 = $it->();
is($p20->degree, 8);

$it = $p3->cyclo_factors_iterate(20);
my @f20 = $it->();
ok(6 == @f20 && $f20[-1] == $p20);

__END__
