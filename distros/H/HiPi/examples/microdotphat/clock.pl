#!/usr/bin/perl
use strict;
use warnings;

use HiPi::Interface::MicroDotPHAT;

my $phat = HiPi::Interface::MicroDotPHAT->new();

print q(Clock
Displays the time in hours, minutes and seconds
Press Ctrl+C to exit.
);

my $offsetx = 0;
my $offsety = 0;
my $kerning = 0;

while(1) {
    $phat->clear();
    my($sec,$min,$hour) = localtime(time);
    if($sec % 2 == 0){
        $phat->set_decimal(2,1);
        $phat->set_decimal(4,1);
    } else {
        $phat->set_decimal(2,0);
        $phat->set_decimal(4,0);
    }
    $phat->write_string( sprintf('%02d%02d%02d', $hour, $min, $sec ), $offsetx ,$offsety, $kerning );
    $phat->show;
    $phat->sleep_milliseconds( 50 );
}

1;
