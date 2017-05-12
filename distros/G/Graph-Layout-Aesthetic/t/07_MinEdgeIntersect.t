#!/usr/bin/perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 07_MinEdgeIntersect.t.t'

use strict;
use warnings;
BEGIN { $^W = 1 };
use Test::More "no_plan";

BEGIN { use_ok('Graph::Layout::Aesthetic') };
BEGIN { use_ok('Graph::Layout::Aesthetic::Topology') };

# Check if a value is close to anouther
our $EPS = 1e-8;
sub nearly {
    my $val    = shift;
    my $target = shift;
    my ($low, $high) =
        $target > 0 ? ($target * (1-$EPS), $target * (1+$EPS)) :
        $target < 0 ? ($target * (1+$EPS), $target * (1-$EPS)) :
        (-$EPS, +$EPS);
    if ($low < $val && $val < $high) {
        pass(@_ ? shift: ());
    } else {
        diag("$val is not close to $target");
        fail(@_ ? shift : ());
    }
}

sub deep_nearly($$;$) {
    my $val    = shift;
    my $target = shift;
    eval {
        @$val == @$target || die "array sizes differ\n";
        for my $i (0..$#$val) {
            my $v = $val->[$i];
            my $t = $target->[$i];
            @$v == @$t || die "Array sizes of element $i differ\n";
            for my $j (0..$#$v) {
                my $ta = $t->[$j];
                my ($low, $high) =
                    $ta > 0 ? ($ta * (1-$EPS), $ta * (1+$EPS)) :
                    $ta < 0 ? ($ta * (1+$EPS), $ta * (1-$EPS)) :
                    (-$EPS, +$EPS);
                $low < $v->[$j] && $v->[$j] < $high ||
                    die "value[$i][$j] = $v->[$j] differs too much from target[$i][$j] = $ta\n";
            }
        }
    };
    if ($@) {
        chop $@;
        diag($@);
        fail(@_ ? shift : ());
    } else {
        pass(@_ ? shift: ());
    }
}

my $topo = Graph::Layout::Aesthetic::Topology->new_vertices(4);
$topo->add_edge(0, 1);
$topo->add_edge(2, 3);
$topo->finish;

my $aglo = Graph::Layout::Aesthetic->new($topo, 3);
eval { $aglo->add_force("MinEdgeIntersect") };
like($@, qr!^MinEdgeIntersect only works in 2 dimensions, not 3 at !,
     "Not allowed in three dimensions");
$aglo = Graph::Layout::Aesthetic->new($topo);
$aglo->add_force("MinEdgeIntersect");
my @forces = $aglo->forces;
is(@forces, 1, "Only one force");
isa_ok($forces[0][0], "Graph::Layout::Aesthetic::Force::MinEdgeIntersect");
is($forces[0][1], 1, "Unit weight");
is($forces[0][0]->name, "MinEdgeIntersect", "Right name");

$aglo->all_coordinates([0, -1], [0, 1], [1, -1], [1, 1]);
is_deeply(scalar $aglo->gradient, [([0, 0])x4], "No force if no intersect");
$aglo->all_coordinates([-1, 0], [3, 0], [0, -1], [0, 3]);
deep_nearly($aglo->gradient, [([ sqrt(1/2), -sqrt(1/2)]) x 2,
                              ([-sqrt(1/2),  sqrt(1/2)]) x 2]);
$aglo->all_coordinates([-2, 0], [6, 0], [0, -2], [0, 6]);
deep_nearly($aglo->gradient, [([ sqrt(1/2), -sqrt(1/2)]) x 2,
                              ([-sqrt(1/2),  sqrt(1/2)]) x 2]);
