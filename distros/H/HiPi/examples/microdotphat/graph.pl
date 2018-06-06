#!/usr/bin/perl
use strict;
use warnings;

use HiPi::Interface::MicroDotPHAT;

my $phat = HiPi::Interface::MicroDotPHAT->new();

print q(Graph
Plots random numbers scross the screen in a bar graph.
Press Ctrl+C to exit.
);

my @graph = ();
my $filled = 1;

while(1) {
    $phat->clear();
    push @graph, int(rand(7));
    
    while( @graph > 45 ) {
        shift @graph;
    }
    
    for (my $x = 0; $x < @graph; $x ++ ) {
        if ($filled ) {
            # bar graph
            $phat->set_col($x + ($phat->width- scalar @graph ), (
                0,
                0b1000000,
                0b1100000,
                0b1110000,
                0b1111000,
                0b1111100,
                0b1111110,
                0b1111111)[$graph[$x]] );
        } else {
            # plot
            $phat->set_col($x, 1 << ( 7 -  $graph[$x] ));
        }
    }

    $phat->show();
    $phat->sleep_milliseconds( 50 );
}

1;
