#!/usr/bin/perl
use strict;
use warnings;

use HiPi::Interface::MicroDotPHAT;

my $phat = HiPi::Interface::MicroDotPHAT->new();

print q(Advanced Scrolling
Advanced scrolling example which displays a message line-by-line
and then skips back to the beginning.
Press Ctrl+C to exit.
);

my $rewind = 1;
my $delay = 30;

my $line_height = $phat->height + 2;
my $offset_left = 0;

my @lines = ("Fifteen men on the dead man's chest",
         "Yo ho ho, and a bottle of rum!",
         "Drink and the devil had done for the rest",
         "Yo ho ho, and a bottle of rum!",
         "But one man of her crew alive,",
         "Yo ho ho, and a bottle of rum!",
         "What put to sea with seventy-five",
         "Yo ho ho, and a bottle of rum!");

my $numlines = scalar( @lines );

my @lengths = ( 0 ) x $numlines;


for (my $i = 0; $i < @lines; $i ++ ) {
    $lengths[$i] = $phat->write_string( $lines[$i], $offset_left, $line_height * $i );
    $offset_left += $lengths[$i];
}

my $current_line = 0;
$phat->show;

while (1) {
    my $starttime = time;
    my $pos_x = 0;
    my $pos_y = 0;
    for ( my $current_line = 0; $current_line < $numlines; $current_line ++) {
        $phat->sleep_milliseconds( $delay * 10 );
        for (my $y = 0; $y < $lengths[$current_line]; $y ++) { 
            $phat->scroll(1,0);
            $pos_x += 1;
            $phat->sleep_milliseconds( $delay );
            $phat->show();
        }
        if ( $current_line == $numlines - 1 && $rewind ) {
            for ( my $y = 0; $y < $pos_y; $y ++ ) {
                $phat->scroll(- int($pos_x/$pos_y), - 1);
                $phat->show();
                $phat->sleep_milliseconds( $delay );
            }
            $phat->scroll_to(0,0);
            $phat->show();
            $phat->sleep_milliseconds( $delay );
            my $endtime = time;
            $starttime = time;
        } else {
            for (my $i = 0; $i < $line_height; $i++) {
                $phat->scroll(0,1);
                $pos_y += 1;
                $phat->show();
                $phat->sleep_milliseconds( $delay );
            }
        }
    }
    
}

1;
