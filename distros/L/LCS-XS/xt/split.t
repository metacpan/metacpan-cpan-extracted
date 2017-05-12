#!perl
use 5.006;

use strict;
use warnings;

use Benchmark qw(:all) ;
use Data::Dumper;

my $diffs = join(' ', (map { "$_:$_" } (0..49)));

    timethese( 50_000, {
       'split' => sub {
            my $LCS = [];
            for my $diff ( split ' ', $diffs ) {
                my( $x, $y ) = split ':', $diff;
                #push @$LCS, [$x,$y];
            }
        },
    });
