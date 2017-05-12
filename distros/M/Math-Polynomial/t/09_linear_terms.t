# Copyright (c) 2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 09_linear_terms.t 55 2009-06-10 20:56:13Z demetri $

# Checking methods dealing with linear terms added in version 1.002

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/09_linear_terms.t'

#########################

use strict;
use warnings;
use Test;
use Math::Complex;
BEGIN { plan tests => 38 };
use Math::Polynomial 1.002;
ok(1);  # 1

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

my $p = Math::Polynomial->new(-6, -5, 2, 1);
my $q = $p->mul_const(3);
my $r = $p->new(-6, -3, 3);
my $cp = $p->new(7);
my $zp = $p->new;

my $p1 = Math::Polynomial->from_roots(-1, 2, -3);
ok(has_coeff($p1, -6, -5, 2, 1));       # 2

my $p2 = $p->from_roots();
ok(has_coeff($p2, 1));  # 3

my $p3 = $p->from_roots(-3);
ok(has_coeff($p3, 3, 1));       # 4

my $p4 = $r->mul_root(-3);
ok(has_coeff($p4, -18, -15, 6, 3));     # 5

my $p5 = $cp->mul_root(0);
ok(has_coeff($p5, 0, 7));       # 6

my $p6 = $zp->mul_root(7);
ok(has_coeff($p6));     # 7

my $p7 = eval { $p->div_root(-3) };
ok(has_coeff($p7, -2, -1, 1));  # 8

my $p8 = eval { $p->div_root(-2) };
ok(has_coeff($p8, -5, 0, 1));   # 9

my $p9 = eval { $p->div_root(-3, 1) };
ok(has_coeff($p9, -2, -1, 1));  # 10

my $p10 = eval { $p->div_root(-2, 1) };
ok(!defined $p10);      # 11
ok($@ =~ /non-zero remainder/); # 12

my $p11 = eval { $q->div_root(-3) };
ok(has_coeff($p11, -6, -3, 3)); # 13

my $p12 = eval { $q->div_root(-3, 1) };
ok(has_coeff($p12, -6, -3, 3)); # 14

my $p13 = eval { $q->div_root(-2) };
ok(has_coeff($p13, -15, 0, 3)); # 15

my $p14 = eval { $q->div_root(-2, 1) };
ok(!defined $p14);      # 16
ok($@ =~ /non-zero remainder/); # 17

my $p15 = eval { $cp->div_root(-3) };
ok(has_coeff($p15));    # 18

my $p16 = eval { $cp->div_root(-3, 1) };
ok(!defined $p16);      # 19
ok($@ =~ /non-zero remainder/); # 20

my $p17 = eval { $zp->div_root(-3) };
ok(has_coeff($p17));    # 21

my $p18 = eval { $zp->div_root(-3, 1) };
ok(has_coeff($p18));    # 22

my ($p19, $p20) = eval { $p->divmod_root(-3) };
ok(has_coeff($p19, -2, -1, 1)); # 23
ok(has_coeff($p20));    # 24

my ($p21, $p22) = eval { $p->divmod_root(-2) };
ok(has_coeff($p21, -5, 0, 1));  # 25
ok(has_coeff($p22, 4)); # 26

my ($p23, $p24) = eval { $q->divmod_root(-3) };
ok(has_coeff($p23, -6, -3, 3)); # 27
ok(has_coeff($p24));    # 28

my ($p25, $p26) = eval { $q->divmod_root(-2) };
ok(has_coeff($p25, -15, 0, 3)); # 29
ok(has_coeff($p26, 12));        # 30

my ($p27, $p28) = eval { $cp->divmod_root(-3) };
ok(has_coeff($p27));    # 31
ok(has_coeff($p28, 7)); # 32

my ($p29, $p30) = eval { $zp->divmod_root(-3) };
ok(has_coeff($p29));    # 33
ok(has_coeff($p30));    # 34

my $p31 = eval { $p->divmod_root(-3) };
ok(!defined $p31);      # 35
ok($@ =~ /array context required/);     # 36

my $p32 = Math::Polynomial->from_roots();
ok(has_coeff($p32, 1)); # 37

my $p33 = Math::Polynomial->from_roots(1+0*i, 0+1*i, -1+0*i, 0-1*i);
ok(has_coeff($p33, -1, 0, 0, 0, 1));    # 38

__END__
