#!/usr/bin/perl

# Copyright (c) 2009 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: runge.pl 4 2009-05-10 22:14:58Z demetri $

# Math::Polynomial usage example: demonstrating Runge's phenomenon
#
# High degree interpolation polynomials fitted through nodes with equidistant
# x-values can oscillate wildly towards the end nodes, which makes them
# unsuitable for approximation purposes.  This script calculates values
# to plot a function and an interpolation polynomial, displaying such
# behaviour, which was described by Carl Runge in a paper of 1901.
#
# The accompanying file "runge_plot.png" demonstrates this visually.

use strict;
use warnings;
use Math::Polynomial 1.000;

sub my_function {
    my ($x) = @_;
    return 1.0 / (1.0 + 25.0*$x*$x);
}

my $INTERVALS = 8;
my $MIN_X = -1.0;
my $MAX_X =  1.0;

my $PLOT_INTERVALS = 40;
my $PLOT_MIN_X = -1.25;
my $PLOT_MAX_X =  1.25;

my @x_values =
    map { $MIN_X + ($MAX_X - $MIN_X) * $_ / $INTERVALS } 0..$INTERVALS;
my @y_values = map { my_function($_) } @x_values;

my $lagrange = Math::Polynomial->interpolate(\@x_values, \@y_values);

foreach my $i (0..$PLOT_INTERVALS) {
    my $x = $PLOT_MIN_X + ($PLOT_MAX_X-$PLOT_MIN_X) * $i / $PLOT_INTERVALS;
    printf
        "%7.4f %10.6f %10.6f\n",
        $x, my_function($x), $lagrange->evaluate($x);
}

__END__
