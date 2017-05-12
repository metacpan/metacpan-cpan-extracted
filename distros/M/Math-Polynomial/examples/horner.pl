#!/usr/bin/perl

# Copyright (c) 2010 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: horner.pl 69 2010-08-09 00:16:37Z demetri $

# Math::Polynomial example: write polynomials in the form of a Horner scheme
#
# A Horner scheme is an efficient method to evaluate a polynomial for
# a value of x = x0 by repeatedly adding a coefficient and multiplying
# by x0.  This script uses a tree conversion function turning a polynomial
# into an equivalent Horner-like expression.  It displays the output
# of this function for a couple of simple polynomials.

use strict;
use warnings;
use Math::Polynomial 1.003;

my %config = (
    fold_sign  => 1,
    variable   => 'x',
    constant   => sub { "$_[0]" },
    negation   => sub { "-$_[0]" },
    sum        => sub { "$_[0]+$_[1]" },
    difference => sub { "$_[0]-$_[1]" },
    product    => sub { "$_[0]*$_[1]" },
    power      => sub { "$_[0]^$_[1]" },
    group      => sub { "($_[0])" },
);

foreach my $a (-1, 0, 1, 2) {
    foreach my $b (-1, 0, 1) {
        foreach my $c (0, 1) {
            foreach my $d (0, 1) {
                my $p = Math::Polynomial->new($d, $c, $b, $a);
                print $p->as_horner_tree(\%config), "\n";
            }
        }
    }
}

__END__
