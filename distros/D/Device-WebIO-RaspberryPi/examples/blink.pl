#!env perl
use v5.14;
use Device::WebIO;
use Device::WebIO::RaspberryPi;

use constant OUTPUT_PIN => 17;


my $rpi = Device::WebIO::RaspberryPi->new;

my $webio = Device::WebIO->new;
$webio->register( 'rpi', $rpi );

$webio->set_as_output(  'rpi', OUTPUT_PIN );


say "Blinking";
while(1) {
    sleep 1;
    $webio->digital_output( 'rpi', OUTPUT_PIN, 1 );
    sleep 1;
    $webio->digital_output( 'rpi', OUTPUT_PIN, 0 );
}
