#!/usr/bin/env perl
# Copyright (c) 2009-2021 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# This example demonstrates solving linear systems of congruences
# with a unique solution, and how Math::ModInt::ChineseRemainder
# can be used to do most calculations with small moduli although
# the final result is given modulo a large number.
#
# A more general way of dealing with modular integer equation systems
# will be the topic of an upcoming extension module.

use strict;
use warnings;
use Math::ModInt qw(mod);
use Math::ModInt::ChineseRemainder qw(cr_combine);

my @int_matrix = (
    [ 1,  5,  11,  36],
    [ 5, 11,  36,  95],
    [11, 36,  95, 281],
    [36, 95, 281, 781],
);
my @int_vector = (95, 281, 781, 2245);

my @moduli = (101, 103, 107);

my @parts = ();
foreach my $modulus (@moduli) {
    my $x = mod(0, $modulus);
    my @matrix = map { [map { $x->new($_) } @{$_}] } @int_matrix;
    my @vector =        map { $x->new($_) }          @int_vector;
    my ($part) = mat_solve(\@matrix, \@vector);
    if ($part) {
        push @parts, $part;
        print "partial solution: @{$part}\n";
    }
    else {
        print "no solution for modulus $modulus\n";
    }
}

my @combined = map {
    my $i = $_;
    cr_combine( map { $_->[$i] } @parts )
} 0..$#{$parts[0]};

my $mod = $combined[0]->modulus;
my @res = map { $_->signed_residue } @combined;
print "solution modulo $mod: @res\n";

# given a non-singular square matrix M and vectors v1, v2, ...,
# find vectors u1, u2, ... satisfying M u1 = v1, M u2 = v2, ...
# M is taken as an arrayref to a list of column vector arrayrefs
# v1, v2, ... are vector arrayrefs
# result is a list of vector arrayrefs, or nothing on failure
sub mat_solve {
    my ($mat, @vec) = @_;
    my @matrix = map { [@{$_}] } @{$mat}, @vec;
    my $dim = @{$matrix[0]};
    my $zero = $matrix[0]->[0]->new(0);
    my $one  = $zero->new(1);
    # step 1: convert matrix to triangle form
    foreach my $col (0..$dim-1) {
        my $pivot = $col;
        while ($pivot < $dim && !$matrix[$col]->[$pivot]) {
            ++$pivot;
        }
        return if $pivot == $dim;
        if ($pivot != $col) {
            foreach my $v (@matrix[$col .. $#matrix]) {
                @{$v}[$col, $pivot] = @{$v}[$pivot, $col];
            }
        }
        if ($matrix[$col]->[$col] != $one) {
            my $q = $matrix[$col]->[$col]->inverse;
            return if !$q->is_defined;
            $matrix[$col]->[$col] = $one;
            foreach my $v (@matrix[$col+1 .. $#matrix]) {
                $v->[$col] *= $q;
            }
        }
        foreach my $row ($col+1 .. $dim-1) {
            if ($matrix[$col]->[$row]) {
                my $q = $matrix[$col]->[$row];
                $matrix[$col]->[$row] = $zero;
                foreach my $v (@matrix[$col+1 .. $#matrix]) {
                    $v->[$row] -= $v->[$col] * $q;
                }
            }
        }
    }
    # step 2: diagonalize
    for (my $col = $dim-1; $col > 0; --$col) {
        foreach my $row (0..$col-1) {
            my $q = $matrix[$col]->[$row];
            if ($q) {
                $matrix[$col]->[$row] = $zero;
                foreach my $v (@matrix[$dim..$#matrix]) {
                    $v->[$row] -= $v->[$col] * $q;
                }
            }
        }
    }
    return @matrix[$dim..$#matrix];
}

__END__
