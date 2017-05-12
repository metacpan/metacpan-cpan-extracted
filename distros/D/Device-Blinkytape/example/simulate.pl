#!/usr/bin/env perl
use lib '../lib';
use Device::BlinkyTape::WS2811; # BlinkyTape uses WS2811
my $bb = Device::BlinkyTape::WS2811->new(simulate => 1);
$bb->all_on();
sleep 2;
$bb->all_off();
sleep 2;
$bb->send_pixel(255,255,255);
$bb->show();
sleep 2;
$bb->send_pixel(255,0,0);
$bb->show();
sleep 2;
$bb->send_pixel(240,0,0);
$bb->show();
sleep 2;
# Go crazy
for (my $b=0; $b<=1000; $b++) {
    for (my $a=0; $a<=59; $a++) {
        $bb->send_pixel(int(rand(254)),int(rand(254)),int(rand(254)));
    }
    $bb->show(); # shows the sent pixel row
}
sleep 2;
