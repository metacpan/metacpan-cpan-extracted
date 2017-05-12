#!/usr/bin/env perl
use strict;
use lib '../lib';
use Device::BlinkyTape::WS2811; # BlinkyTape uses WS2811
use Time::HiRes qw/ usleep /;

my $dev = shift @ARGV;

if (!$dev) {
    print "\n";
    print "Usage: $0 [device] [amount_of_blinking] [blinking_speed_min] [blinking_speed_max]\n";
    print "   [device] is the file to BlinkyTape, for example /dev/tty.usbmodem1411\n";
    print "\n";
    print "   Default is            $0 [device] 30  1 30\n";
    print "   For faster blinking:  $0 [device] 30 30 30\n";
    print "   For lots of blinking  $0 [device]  1  1 30\n";
    print "\n";
    exit 255;
}

my $amount_of_blinking = shift @ARGV || 30;
my $brightness_step_min = shift @ARGV || 1;
my $brightness_step_max = shift @ARGV || 30;

my $bb = Device::BlinkyTape::WS2811->new(dev => $dev);

my @led; # 0..59
for (my $a=0; $a<=59; $a++) {
    $led[$a] = 0;
}
my @ledb;
my @ledr;

for (my $b=0; $b<=100000; $b++) {
    if ($b % $amount_of_blinking == 0) {
        my $pos = int(rand(59));
        if ($led[$pos]==0) { # if not already blinking
            my $brightness_step = int(rand($brightness_step_max-$brightness_step_min))+$brightness_step_min;
            $ledb[$pos] = $brightness_step;
            $ledr[$pos] = int(rand(254));
            $led[$pos] = $ledb[$pos]; # initiate blinking
        }
    }

    for (my $a=0; $a<=59; $a++) {
        if ($led[$a]>0) {
            $led[$a] = $led[$a]+$ledb[$a];
        }

        $led[$a] = 0 if ($led[$a]>512);

        my $sendval = $led[$a];
        if ($led[$a]>255) {
            $sendval =512 - $sendval;
        }

        my $o = $sendval-$ledr[$a]; # redness
        $o=0 if ($o<0);

        $bb->send_pixel($sendval, $o, $o);
    }
    $bb->show(); # shows the sent pixel row.
    usleep(400);
}

