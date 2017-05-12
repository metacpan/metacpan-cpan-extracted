#! /usr/bin/env perl 
# vim:filetype=perl

use strict;
use GD::Graph::sparklines;

use Test::More tests => 10;

open CSV, "<data/fxp0.csv" or die "$!";
my @in = map {chomp;(split(/,/,$_,2))[1]} <CSV>;
close CSV;

my @data = @in[-128..-1];

check_graph('clipped_0_16000.png', y_min_clip=>0, y_max_clip=>16000);
check_graph('clipped_0_4000.png', y_min_clip=>0, y_max_clip=>4000);
check_graph('not_clipped.png');
check_graph('noblob.png', y_min_clip=>0, y_max_clip=>16000, no_blob=>1);
check_graph('banded.png', y_band_min=>4000, y_band_max=>6000, y_max_clip=>16000, y_min_clip=>0);


# create a graph with options
sub make_graph {
    my $graph = GD::Graph::sparklines->new(128, 16);
    $graph->set( @_ );
    my $gd = $graph->plot([[0..127], \@data]) or die $graph->error;
    return $gd;
}

# cygwin GD creates slightly different PNGs than linux GD
# so the trivial equality check (comparing the new graph
# with a pre-created one) this used to do was useless
sub check_graph {
    my $file = shift;
    my $graph = make_graph( @_ );

	
    isa_ok($graph, 'GD::Image');
    ok(length($graph->gd()) > 0, 'non-zero length');

    # handy for a visual check, sometimes
    if (my $output = $ENV{'WRITE_TEST_PNGS'}) {
        if ( open N, ">$output/$file" ) {
            binmode N;
            print N $graph->png();
            close N;
        }
    }	
}
