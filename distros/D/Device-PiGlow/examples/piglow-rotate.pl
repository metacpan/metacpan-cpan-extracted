#!perl

use strict;
use warnings;

use Device::PiGlow;

my $pg = Device::PiGlow->new();

my @arms = (0,1,2);

$pg->enable_output();
$pg->enable_all_leds();

$SIG{INT} = sub { 
   print "Reset\n";
   $pg->reset();
   exit;
};

while (1 )
{
    print "Writing arm " . $arms[0] . "\n";
    $pg->set_arm($arms[0], 0xFF);
    print "clearing arm " . $arms[1] . "\n";
    $pg->set_arm($arms[1], 0x00);
    print "clearing arm " . $arms[2] . "\n";
    $pg->set_arm($arms[2], 0x00);
    print "updating \n";
    $pg->update();
    my $first = shift @arms;
    push @arms, $first;
    sleep 1;
}

