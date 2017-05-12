#!/usr/bin/perl
use v5.14;
use warnings;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use Device::WebIO::Firmata;

use constant DEBUG => 1;


my $webio = Device::WebIO->new;
my $rpi = Device::WebIO::RaspberryPi->new;
my $firmata = Device::WebIO::Firmata->new({
    port => '/dev/ttyACM0',
});
$webio->register( 'rpi', $rpi );
$webio->register( 'firmata', $firmata );

$webio->set_as_input( 'rpi', 17 );
$webio->set_as_output( 'firmata', 13 );

say "Taking input . . . ";
while( 1 ) {
    my $input = $webio->digital_input( 'rpi', 17 );
    say "Input: $input" if DEBUG;
    $webio->digital_output( 'firmata', 13, $input );
    sleep 1;
}
