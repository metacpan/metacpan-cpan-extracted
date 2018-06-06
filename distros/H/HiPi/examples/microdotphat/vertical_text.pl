#!/usr/bin/perl
use strict;
use warnings;

use HiPi::Interface::MicroDotPHAT;

my $phat = HiPi::Interface::MicroDotPHAT->new();

print q(Vertical Text
Scrolls text messages vertically.
Press Ctrl+C to exit.
);

my @lines = qw( One Two Three Four Five );

# $line_height 9 gives 2 pixel vertical spacing for rows
my $line_height = 9;

for(my $i = 0; $i < @lines; $i ++ ) {
    $phat->write_string( $lines[$i], 0, $i * $line_height, 0);
}
   
$phat->show;

while (1) {
    $phat->sleep_milliseconds( 1000 );
    my $iter = 0;
    while( $iter < $line_height ) {
        $iter++;
        $phat->scroll_vertical();
        $phat->show();
        $phat->sleep_milliseconds( 50 );
    }
}


1;
