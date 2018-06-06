#!/usr/bin/perl
use strict;
use warnings;

use HiPi::Interface::MicroDotPHAT;

my $phat = HiPi::Interface::MicroDotPHAT->new();

print q(Flash
Flashes all the elements.
Press Ctrl+C to exit.
);

my $speed = 5;
my @strings = ("One", "Two", "Three", "Four");
my $string = 0;
my $shown = 1;
$phat->show();

my $t = 500;

while(1) {
    $phat->clear();
    $phat->show();
    $phat->sleep_milliseconds( $t );
    for(my $x = 0; $x < $phat->width; $x ++) {
        for (my $y = 0; $y < $phat->height; $y ++) {
            $phat->set_pixel($x,$y,1);
        }
    }
    for (my $x = 0; $x < 6; $x++ ) {
        $phat->set_decimal($x,1);
    }
    $phat->show();
    $phat->sleep_milliseconds( $t );
}

1;
