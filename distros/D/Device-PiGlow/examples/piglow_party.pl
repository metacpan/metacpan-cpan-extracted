#!perl

use strict;
use warnings;

use Device::PiGlow;

my $pg = Device::PiGlow->new();

my $values = [0x01,0x02,0x04,0x08,0x10,0x18,0x20,0x30,0x40,0x50,0x60,0x70,0x80,0x90,0xA0,0xC0,0xE0,0xFF];

$pg->enable_output();
$pg->enable_all_leds();

$SIG{INT} = sub { 
   print "Reset\n";
   $pg->reset();
   exit;
};

while (1 )
{
    print "Writing\n";
    $pg->write_all_leds($values,1 );
    my $first = shift @{$values};
    push @{$values}, $first;
    sleep 1;
}

