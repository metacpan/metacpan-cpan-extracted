#!/usr/bin/env perl
# Copyright (c) 2017-2022 Martin Becker, Blaubeuren.
# This package is free software; you can redistribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# This example generates symmetric polynomials with a given number of
# variables and a given degree.

use strict;
use warnings;
use Math::Polynomial::Multivariate;
use Algorithm::Combinatorics qw(combinations);

my $n = num_arg(0, 4);
my $k = num_arg(1, $n >> 1);

usage() if $k > $n || @ARGV > 2;

my $poly = symmetric_poly($k, gen_vars($n));
print "$poly\n";

sub symmetric_poly {
    my ($k, @vars) = @_;
    my $it = combinations(\@vars, $k);
    my $result = Math::Polynomial::Multivariate->const(0);
    while (my $tuple = $it->next) {
        $result += $result->monomial(1, {map {($_ => 1)} @{$tuple}});
    }
    return $result;
}

sub usage {
    die "usage: symmetric.pl [n [k]]\n";
}

sub num_arg {
    my ($index, $default) = @_;
    return $default if $index >= @ARGV;
    return $1 if $ARGV[$index] =~ /^(\d+)\z/;
    usage();
}

sub gen_vars {
    my ($n) = @_;
    my $var = 'a';
    return map { $var++ } 1 .. $n;
}

__END__
