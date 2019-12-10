# Copyright (c) 2007-2019 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Checking coefficient space compatibility with Math::Complex.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/10_math_complex.t'

#########################

use strict;
use warnings;
use Test;
use lib 't/lib';
use Test::MyUtils qw(:comp :DEFAULT);
BEGIN {
    use_or_bail('Math::Complex');
    plan tests => 2;
}
use Math::Polynomial 1.000;
ok(1);  # 1

#########################

init_comp_check(qw(Math::Polynomial Math::Complex));

my $c0 = Math::Complex->new(0, 3);
my $c1 = Math::Complex->new(2, 1);
my $c2 = Math::Complex->new(1, -2);
my $x  = Math::Complex->new(-1, 1);
my $y  = Math::Complex->new(-7, 2);
my $p  = Math::Polynomial->new($c0, $c1, $c2);
comp_ok($p->evaluate($x) == $y);        # 2

__END__
