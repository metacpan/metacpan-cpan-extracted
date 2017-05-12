#!/usr/bin/perl

# Copyright (c) 2010 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: symbolic.pl 74 2010-08-09 00:37:33Z demetri $

# Math::Polynomial example: convert polynomials to Math::Symbolic trees

use strict;
use warnings;
use Math::Polynomial 1.003;
use Math::Symbolic;
use Math::Symbolic::Derivative qw(partial_derivative);

my $x = Math::Symbolic::Variable->new('x');

my %config = (
    fold_sign  => 1,
    variable   => $x,
    constant   => sub { Math::Symbolic::Constant->new($_[0]) },
    negation   => sub { Math::Symbolic::Operator->new('neg', $_[0]) },
    sum        => sub { Math::Symbolic::Operator->new('+', $_[0], $_[1]) },
    difference => sub { Math::Symbolic::Operator->new('-', $_[0], $_[1]) },
    product    => sub { Math::Symbolic::Operator->new('*', $_[0], $_[1]) },
    power      =>
        sub {
            my $exp = Math::Symbolic::Constant->new($_[1]);
            return Math::Symbolic::Operator->new('^', $_[0], $exp);
        },
);

printf "%-39s %s\n", 'polynomial', 'derivative';
foreach my $a (-1, 0, 1, 2) {
    foreach my $b (-1, 0, 1) {
        foreach my $c (-1, 1) {
            foreach my $d (0, 1) {
                my $p = Math::Polynomial->new($d, $c, $b, $a);
                my $s = $p->as_power_sum_tree(\%config);
                printf "%-39s %s\n",
                    $s->to_string,
                    partial_derivative($s, $x)->simplify->to_string;
            }
        }
    }
}

__END__
