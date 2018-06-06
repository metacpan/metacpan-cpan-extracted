#!/usr/bin/perl
use strict;
use warnings;

use HiPi::Interface::MicroDotPHAT;
use Time::HiRes ();

my $phat = HiPi::Interface::MicroDotPHAT->new();

print q(Fading Text
Uses the brightness control to fade between messages.
Press Ctrl+C to exit
);

my $speed = 5;
my @strings = ("One", "Two", "Three", "Four");
my $string = 0;
my $shown = 1;
$phat->show();

# Start time. Phase offset
my $start = Time::HiRes::time();

my $offsetx = 0;
my $offsety = 0;
my $kerning = 0;

while(1) {
    my $b = (sin((Time::HiRes::time() - $start) * $speed) + 1) / 2;
    $phat->set_brightness($b);
    
    if($b < 0.002 && $shown ) {
        $phat->clear();
        $phat->write_string($strings[$string], $offsetx, $offsety, $kerning);

        $string += 1;
        $string %=  scalar @strings;

        $phat->show();
        $shown = 0;
    }

    # At maximum brightness, confirm the string has been shown
    if ( $b > 0.998 ) {
        $shown = 1;
    }
    # Sleep a bit to save resources, this wont affect the fading speed
    $phat->sleep_milliseconds( 10 );
}

1;
