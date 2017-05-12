#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 379;

use_ok('Math::Vector::Real::kdTree');

use Sort::Key::Top qw(nhead);
use Math::Vector::Real;
use Math::Vector::Real::Test qw(eq_vector);

sub find_two_nearest_vectors_bruteforce {
    my @best_ix = (undef, undef);
    my $best_d2 = 'inf' + 0;
    for my $i (1..$#_) {
        my $v = $_[$i];
        for my $j (0..$i - 1) {
            my $d2 = Math::Vector::Real::dist2($v, $_[$j]);
            if ($d2 < $best_d2) {
                $best_d2 = $d2;
                @best_ix = ($i, $j);
            }
        }
    }
    (@best_ix, sqrt($best_d2))
}

my %gen = ( num => sub { V(map rand, 1..$_[0]) },
            int => sub { V(map int(rand 10), 1..$_[0]) },
            dia => sub { V((rand) x $_[0]) } );

#srand 318275924;
diag "srand: " . srand;
for my $g (keys %gen) {
    for my $d (1, 2, 3, 4, 5, 6, 10) {
        for my $n (2, 5, 10, 20, 40, 50, 60, 70, 80, 90, 100, 120, 150, 180, 200, 250, 500, 1000) {
            my $id = "gen: $g, d: $d, n: $n";
            my @o = map $gen{$g}->($d), 1..$n;
            my $t = Math::Vector::Real::kdTree->new(@o);
            my ($b1, $b2, $min_d2) = $t->find_two_nearest_vectors;
            my ($b1bf, $b2bf, $min_d2_bf) = find_two_nearest_vectors_bruteforce(@o);
            is($min_d2, $min_d2_bf, "nearest_two_vectors - $id") or do {
                diag "values differ: $min_d2 $min_d2_bf best: $b1, $b2, best_bf: $b1bf, $b2bf\n";
                diag $t->dump_to_string(pole_id => 1, remark => [$b1, $b2, $b1bf, $b2bf]);
                diag "end";
            };
        }
    }
}
