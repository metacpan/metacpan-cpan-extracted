#!/usr/bin/perl
use strict;
use warnings;

use HiPi::Interface::MicroDotPHAT;

my $phat = HiPi::Interface::MicroDotPHAT->new();

print q(Tiny Font
Displays an IP address in a tiny, tiny number font!
Press Ctrl+C to exit.
);

my $x = 0;

while (1) {
    $phat->clear();
    $phat->draw_tiny(0,"192");
    $phat->draw_tiny(1,"178");
    $phat->draw_tiny(2,"0");
    $phat->draw_tiny(3,"68");
    $phat->draw_tiny(4, $x);

    $x++;
    $x = 0 if $x > 199;
    $phat->show();
    $phat->sleep_milliseconds( 100 );
}


1;
