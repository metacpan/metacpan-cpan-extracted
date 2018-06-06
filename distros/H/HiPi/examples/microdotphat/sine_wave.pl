#!/usr/bin/perl
use strict;
use warnings;

use Time::HiRes ();
use HiPi::Interface::MicroDotPHAT;

my $phat = HiPi::Interface::MicroDotPHAT->new();

print q(Sine Wave
Displays a sine wave across your pHAT.
Press Ctrl+C to exit.
);

my $x = 0;

while (1) {
    $phat->clear();
    my $t = Time::HiRes::time() * 10;
    for ( my $x = 0; $x < $phat->width; $x ++) {
        my $y = int((sin($t + ($x/2.5)) + 1) * 3.5);
        $phat->set_pixel($x, $y, 1);
    }
    $phat->show();
    $phat->sleep_milliseconds( 50 );
}


1;
