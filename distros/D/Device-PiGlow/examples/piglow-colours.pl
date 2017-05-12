#!perl

use strict;
use warnings;

use Device::PiGlow;

my $pg = Device::PiGlow->new();

my @colours = $pg->colours();

$pg->enable_output();
$pg->enable_all_leds();

$SIG{INT} = sub { 
   print "Reset\n";
   $pg->reset();
   exit;
};

while (1 )
{
    my $on_colour = shift @colours;
    print "Writing colour " . $on_colour . "\n";
    $pg->set_colour($on_colour, 0xFF);
    foreach my $off_colour ( @colours )
    {
       $pg->set_colour($off_colour, 0x00);
    }
    
    $pg->update();
    push @colours, $on_colour;
    sleep 1;
}

