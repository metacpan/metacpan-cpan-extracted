#!/usr/bin/perl
# Copyright (c) 2011-2013 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: tutte.pl 4 2013-06-01 20:56:56Z demetri $

# This example implements a simple generic algorithm to compute the
# Tutte polynomial of a small undirected graph.  A number of other
# graph invariants are then calculated from the Tutte polynomial,
# namely the chromatic polynomial, flow polynomial, reliability
# polynomial, and the number of spanning trees.

use strict;
use warnings;
use Math::Polynomial::Multivariate;

my $one = Math::Polynomial::Multivariate->const(1);
my $x   = $one->var('x');
my $y   = $one->var('y');

my @graph = (
    [0, 1], [1, 2],
    [0, 3], [1, 4], [2, 5],
    [3, 4], [4, 5],
    # [3, 6], [4, 7], [5, 8],
    # [6, 7], [7, 8],
);

my $T = tutte(\@graph);
my $P = $T->subst('y', 0);
my $C = $T->subst('x', 0);
my $R = $T->subst('x', 1);
my $S = $R->subst('y', 1);

print
    "Tutte:        $T\n",
    "Chromatic:    $P\n",
    "Flow:         $C\n",
    "Reliablility: $R\n",
    "Sp. Trees:    $S\n";

# split the edges of a connected graph into three subsets:
# a spanning tree, a set of single-node loops, and the rest
sub spanning_tree {
    my ($graph) = @_;
    my (@tree, @loops, @more) = ();
    my %seen = ();      # maps nodes to arrayref of connected edges
    my $comp = 0;       # counts connected components in %seen
    foreach my $edge (@{$graph}) {
        my ($c0, $c1) = @seen{@{$edge}};
        if ($c0) {
            if (!$c1) {
                push @{$c0}, $edge->[1];
                $seen{$edge->[1]} = $c0;
                push @tree, $edge;
            }
            elsif ($c0 == $c1) {
                if ($edge->[0] == $edge->[1]) {
                    push @loops, $edge;
                }
                else {
                    push @more, $edge;
                }
            }
            else {
                push @{$c0}, @{$c1};
                @seen{@{$c1}} = ($c0) x @{$c1};
                --$comp;
                push @tree, $edge;
            }
        }
        else {
            if ($c1) {
                push @{$c1}, $edge->[0];
                $seen{$edge->[0]} = $c1;
                push @tree, $edge;
            }
            else {
                ++$comp;
                if ($edge->[0] == $edge->[1]) {
                    $seen{$edge->[0]} = [];
                    push @loops, $edge;
                }
                else {
                    @seen{@{$edge}} = ([@{$edge}]) x 2;
                    push @tree, $edge;
                }
            }
        }
    }
    if ($comp != 1) {
        die "assertion failed: graph not connected";
    }
    return (\@tree, \@loops, \@more);
}

sub tutte {
    my ($graph) = @_;
    my ($tree, $loops, $more) = spanning_tree($graph);
    return $x ** @{$tree} * $y ** @{$loops} if !@{$more};
    my $edge = $more->[-1];
    my @cut = grep { $_ != $edge } @{$graph};
    my @ctr = map { [map { $edge->[1] == $_? $edge->[0]: $_ } @{$_}] } @cut;
    return tutte(\@cut) + tutte(\@ctr);
}
