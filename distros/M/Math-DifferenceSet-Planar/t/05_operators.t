# Copyright (c) 2022 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 05_operators.t'

#########################

use strict;
use warnings;
use File::Spec;
use Config;
use Math::DifferenceSet::Planar;
use constant MDP => Math::DifferenceSet::Planar::;

use Test::More tests => 72;

#########################

my @elems = (
    [0, 4, 5], [1, 2, 4], [1, 2, 6], [0, 1, 3, 9],
);
my @more = (
    [4], [], [1, 2],
);
my @sets = map { MDP->from_elements(@{$_}) } @elems;
my @fmtd = map { fmt_set(@{$_}) } @elems;

foreach my $i (0 .. $#sets) {
    foreach my $j (0 .. $#sets) {
        my $cmp = $sets[$i]->compare($sets[$j]);
        my $rel = qw( == > < )[$i <=> $j];
        is($cmp, $i <=> $j, "$fmtd[$i] $rel $fmtd[$j]");
    }
}

foreach my $i (0 .. $#sets) {
    foreach my $j (0 .. $#sets) {
        my $sp = $sets[$i]->same_plane($sets[$j]);
        my $ex = ($i + !$i) == ($j + !$j);
        my $rel = qw( nsp sp )[$ex];
        is($sp, $ex, "$fmtd[$i] $rel $fmtd[$j]");
    }
}

foreach my $i (0 .. 3) {
    foreach my $j (0 .. 3) {
        my @ce = $sets[$i]->common_elements($sets[$j]);
        my @ex =
            $i == $j? @{$elems[$i]}:
            $i == 3 || $j == 3? ():
            @{$more[$i+$j-1]};
        my $fex = fmt_set(@ex);
        is("@ce", "@ex", "$fmtd[$i] ce $fmtd[$j] == $fex");
    }
}

my @tlm = (
    [[3, 4, 7, 17, 19], [1, 6, 7, 10, 20]],
    [[7, 9, 14, 15, 18], [1, 4, 5, 10, 12]],
);
foreach my $ab (@tlm) {
    my ($a, $b) = map {set(@{$_})} @{$ab};
    my ($A, $B) = map {set(@{$_})} @{$ab};
    my @ms = $a->find_all_linear_maps($b);
    my %md = map { $_->[0] => $_->[1] } @ms;
    ok(6 == keys(%md), 'solutions');
    my ($f, $d) = $a->find_linear_map($b);
    ok(exists $md{$f}, 'factor');
    is($d, $md{$f}, 'delta');
    is($a->multiply($f)->translate($d)->compare($b), 0, 'map');
    ($f, $d) = $A->find_linear_map($b);
    ok(exists $md{$f}, 'factor');
    is($d, $md{$f}, 'delta');
    is($a->multiply($f)->translate($d)->compare($b), 0, 'map');
    ($f, $d) = $a->find_linear_map($B);
    ok(exists $md{$f}, 'factor');
    is($d, $md{$f}, 'delta');
    is($a->multiply($f)->translate($d)->compare($b), 0, 'map');
}

my $a = set(1, 2, 5, 15, 17);
my $b = set(2, 8, 10, 11);
my @all = $a->find_all_linear_maps($b);
ok(!@all, 'unsolvable');

my $r = eval { $a->find_linear_map($b) };
ok(!defined($r), 'exception raised');
like($@, qr/^sets of same size expected/, 'exception text');

my $c = set(2, 6, 7, 9);
my ($f, $d) = $c->find_linear_map($c);
is($c->multiply($f)->translate($d)->compare($c), 0, 'self reference');

sub set {
    return Math::DifferenceSet::Planar->from_elements( @_ );
}

sub fmt_set { q[{] . join(q[, ], @_) . q[}] }

__END__
