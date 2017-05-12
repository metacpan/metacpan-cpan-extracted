#!/usr/bin/env perl
use lib '../lib';
use Device::BlinkyTape::WS2811; # BlinkyTape uses WS2811
use Time::HiRes qw / usleep /;
my $bb = Device::BlinkyTape::WS2811->new(dev => '/dev/tty.usbmodem1411');

for (my $b=0; $b<=100000; $b++) {
    for (my $a=0; $a<=59; $a++) {
        $bb->send_pixel(int(rand(254)),int(rand(254)),int(rand(254)));
    }
    $bb->show(); # shows the sent pixel row.
    usleep(400000);
}

