# Copyright (c) 2007-2010 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02_basics.t 91 2010-09-06 09:57:35Z demetri $

# Checking basic constructors and attribute accessors.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/02_basics.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 40 };
use Math::Polynomial 1.000;
ok(1);  # module loaded

#########################

my @samples = (
    [[],           [],           [0],         ],
    [[0],          [],           [0],         ],
    [[5],          [5],          [5],         ],
    [[5, 0, 0],    [5],          [5],         ],
    [[2, 0, 0, 8], [2, 0, 0, 8], [2, 0, 0, 8],],
);
my ($ok1, $ok2, $ok3, $ok4, $ok5, $ok6) = (1) x 6;
foreach my $sample (@samples) {
    my @arg  = @{$sample->[0]};
    my @res1 = @{$sample->[1]};
    my @res2 = @{$sample->[2]};
    my $p = Math::Polynomial->new(@arg);
    my @c1 = $p->coeff;
    my @c2 = $p->coefficients;
    $ok1 &&= defined $p;
    $ok2 &&= ref $p;
    $ok3 &&= $p->isa('Math::Polynomial');
    $ok4 &&= @arg == grep { $arg[$_] == $p->coeff($_) } 0..$#arg;
    $ok5 &&= @c1 == @res1 && @res1 == grep { $c1[$_] == $res1[$_] } 0..$#res1;
    $ok6 &&= @c2 == @res2 && @res2 == grep { $c2[$_] == $res2[$_] } 0..$#res2;
}
ok($ok1);       # class method new / defined
ok($ok2);       # class method new / ref
ok($ok3);       # class method new / isa
ok($ok4);       # class method new / coeff(i)
ok($ok5);       # class method new / coeff
ok($ok6);       # class method new / coefficients

my $sp = Math::Polynomial->new(-1, 2, 3);
($ok1, $ok2, $ok3, $ok4) = (1) x 4;
foreach my $sample (@samples) {
    my @arg  = @{$sample->[0]};
    my @res1 = @{$sample->[1]};
    my @res2 = @{$sample->[2]};
    my $p = $sp->new(@arg);
    my @c1 = $p->coeff;
    my @c2 = $p->coefficients;
    $ok1 &&= defined $p;
    $ok2 &&= ref $p;
    $ok3 &&= $p->isa('Math::Polynomial');
    $ok4 &&= @arg == grep { $arg[$_] == $p->coeff($_) } 0..$#arg;
    $ok5 &&= @c1 == @res1 && @res1 == grep { $c1[$_] == $res1[$_] } 0..$#res1;
    $ok6 &&= @c2 == @res2 && @res2 == grep { $c2[$_] == $res2[$_] } 0..$#res2;
}
ok($ok1);       # object method new / defined
ok($ok2);       # object method new / ref
ok($ok3);       # object method new / isa
ok($ok4);       # object method new / coeff(i)
ok($ok5);       # object method new / coeff
ok($ok6);       # object method new / coefficients

@samples = (
    [[0],     [1]],
    [[1],     [0, 1]],
    [[4],     [0, 0, 0, 0, 1]],
    [[0, 10], [10]],
    [[1, 11], [0, 11]],
    [[2, 13], [0, 0, 13]],
    [[0, 0],  []],
    [[2, 0],  []],
);
($ok1, $ok2, $ok3, $ok4) = (1) x 4;
foreach my $sample (@samples) {
    my @arg = @{$sample->[0]};
    my @res = @{$sample->[1]};
    my $p = Math::Polynomial->monomial(@arg);
    my @coeff = $p->coeff;
    $ok1 &&= defined $p;
    $ok2 &&= ref $p;
    $ok3 &&= $p->isa('Math::Polynomial');
    $ok4 &&=
        @coeff == @res && @res == grep { $coeff[$_] == $res[$_] } 0..$#res;
}
ok($ok1);       # class method monomial / defined
ok($ok2);       # class method monomial / ref
ok($ok3);       # class method monomial / isa
ok($ok4);       # class method monomial / coeff

($ok1, $ok2, $ok3, $ok4) = (1) x 4;
foreach my $sample (@samples) {
    my @arg = @{$sample->[0]};
    my @res = @{$sample->[1]};
    my $p = $sp->monomial(@arg);
    my @coeff = $p->coeff;
    $ok1 &&= defined $p;
    $ok2 &&= ref $p;
    $ok3 &&= $p->isa('Math::Polynomial');
    $ok4 &&=
        @coeff == @res && @res == grep { $coeff[$_] == $res[$_] } 0..$#res;
}
ok($ok1);       # object method monomial / defined
ok($ok2);       # object method monomial / ref
ok($ok3);       # object method monomial / isa
ok($ok4);       # object method monomial / coeff

ok(0 == $sp->coeff(-1));

ok(0 == $sp->coeff_zero);
ok(1 == $sp->coeff_one);
ok(2 == $sp->degree);
ok(2 == $sp->proper_degree);

my $zp = $sp->new;
ok(0 == $zp->coeff_zero);
ok(1 == $zp->coeff_one);
ok(-1 == $zp->degree);
my @res = $zp->proper_degree;
ok(1 == @res && !defined $res[0]);      # zero polynomial / proper_degree

$sp = $sp->new(-1, -2, 1);
@samples = (
    [-1, 2],
    [0, -1],
    [1, -2],
    [2, -1],
    [3, 2],
);
($ok1, $ok2) = (1) x 2;
foreach my $sample (@samples) {
    $ok1 &&= $sample->[1] == $sp->evaluate($sample->[0]);
    $ok2 &&=            0 == $zp->evaluate($sample->[0]);
}
ok($ok1);       # evaluate non-zero polynomial
ok($ok2);       # evaluate zero polynomial

# diagnostics

$Math::Polynomial::max_degree = 10;

my $q = eval { Math::Polynomial->monomial(10, 20) };
ok($q && $q->isa('Math::Polynomial'));

$q = eval { Math::Polynomial->monomial(11, 1) };
ok(!defined($q) && $@ && $@ =~ /exponent too large/);

$q = eval {
    local $Math::Polynomial::max_degree;
    Math::Polynomial->monomial(11, 1)
};
ok($q && $q->isa('Math::Polynomial'));

$q = eval { $sp->monomial(10, 20) };
ok($q && $q->isa('Math::Polynomial'));

$q = eval { $sp->monomial(11, 1) };
ok(!defined($q) && $@ && $@ =~ /exponent too large/);

$q = eval {
    local $Math::Polynomial::max_degree;
    $sp->monomial(11, 1)
};
ok($q && $q->isa('Math::Polynomial'));

$q = Math::Polynomial->new(0, 1);
my $c = eval { $q->coeff };
ok(
    !defined($c) && $@ &&
    $@ =~ /array context required if called without argument/
);

$c = eval { $q->coefficients };
ok(!defined($c) && $@ && $@ =~ /array context required/);

__END__
