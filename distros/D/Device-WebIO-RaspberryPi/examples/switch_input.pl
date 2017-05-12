#!env perl
use v5.14;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use Time::HiRes 'sleep';

use constant SLEEP_MS   => 0.1;
use constant INPUT_PIN  => 18;
use constant OUTPUT_PIN => 17;


my $rpi = Device::WebIO::RaspberryPi->new;

my $webio = Device::WebIO->new;
$webio->register( 'rpi', $rpi );

$webio->set_as_input(  'rpi', INPUT_PIN );
$webio->set_as_output( 'rpi', OUTPUT_PIN );

say "Taking input . . . ";
while(1) {
    my $in = $webio->digital_input( 'rpi', INPUT_PIN );
    say "Switch on" if $in;
    $webio->digital_output( 'rpi', OUTPUT_PIN, $in );
    sleep SLEEP_MS;
}
