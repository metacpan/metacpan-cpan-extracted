#!/usr/bin/perl

use 5.010;

use strict;
use warnings;
no  warnings 'syntax';

use experimental 'signatures';

use Test::More 0.88;

our $r = eval "require Test::NoWarnings; 1";

use Math::Sequence::DeBruijn;

my $N = 4;

sub test ($name, $alphabet) {
    my $set =  ref $alphabet ? $alphabet : [split // => $alphabet];
    my $str = !ref $alphabet ? $alphabet : join ("" => @$alphabet);
    subtest $name, sub {
        for my $what ("string", "arrayref") {
            subtest "Using $what", sub {
                my $seq = debruijn ($what eq 'string' ? $str : $set, $N);
                $seq .= substr $seq, 0, $N - 1;
                foreach my $c1 (@$set) {
                    foreach my $c2 (@$set) {
                        foreach my $c3 (@$set) {
                            foreach my $c4 (@$set) {
                                ok index ($seq, "$c1$c2$c3$c4") >= 0,
                                               "'$c1$c2$c3$c4' present";
                            }
                        }
                    }
                }
                ok $seq !~ /(....).*\1/, "No duplicates";
                is length ($seq), @$set ** $N + $N - 1, "Optimal length";
            }
        }
    }
}
            
test "Small",       "01";
test "Larger",      [1 .. 9];

Test::NoWarnings::had_no_warnings () if $r;

done_testing;
