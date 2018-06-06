#!/usr/bin/perl
use strict;
use warnings;

use HiPi::Interface::MicroDotPHAT;

my $phat = HiPi::Interface::MicroDotPHAT->new();

print q(Thermal
Displays the temperature measured from thermal zone 0 using
/sys/class/thermal/thermal_zone0/temp
Press Ctrl+C to exit.
);

my $delay = 1000;
my $kerning = 0;

while(1) {
    $phat->clear();
    my $path = '/sys/class/thermal/thermal_zone0/temp';
    my $temp_raw = qx(cat $path);
    chomp( $temp_raw );
    my $temp = $temp_raw / 1000.0;
    $phat->write_string( sprintf('%.2fc', $temp ), 0, 0, $kerning );
    $phat->show;
    $phat->sleep_milliseconds( $delay );
}

1;
