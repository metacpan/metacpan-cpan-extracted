# Copyright (c) 2007-2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 04_lagrange.t 36 2009-06-08 11:51:03Z demetri $

# Checking Lagrange interpolation.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/04_lagrange.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 15 };
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

my $p = Math::Polynomial->interpolate([-1..2], [0, 1, 2, -9]);
ok(has_coeff($p, 1, 3, 0, -2));

my $q = $p->interpolate([0..3], [3, 0, 0, 3]);
ok(has_coeff($q, 3, -4.5, 1.5));

my $c = $p->interpolate([0], [1]);
ok(has_coeff($c, 1));

my $z0 = $p->interpolate([], []);
ok(has_coeff($z0));

my $z1 = $p->interpolate([1, 2], [0, 0]);
ok(has_coeff($z1));

my $z2 = Math::Polynomial->interpolate([], []);
ok(has_coeff($z2));

my $r = eval { $p->interpolate([1], [2, 3]) };
ok(!defined $r);
ok($@ =~ /usage/);

$r = eval { $p->interpolate([1], 2) };
ok(!defined $r);
ok($@ =~ /usage/);

$r = eval { $p->interpolate(1, [2]) };
ok(!defined $r);
ok($@ =~ /usage/);

$r = eval { $p->interpolate([1, 1], [2, 2]) };
ok(!defined $r);
ok($@ =~ /x values not disjoint/);

__END__
