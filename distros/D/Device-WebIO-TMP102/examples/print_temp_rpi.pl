#!env perl
use v5.14;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use Device::WebIO::TMP102;
use constant DEVICE => 1;


my $webio = Device::WebIO->new;
my $rpi   = Device::WebIO::RaspberryPi->new;
$webio->register( 'rpi', $rpi );

my $tmp102 = Device::WebIO::TMP102->new({
    webio    => $webio,
    provider => 'rpi',
    channel  => DEVICE,
});
$webio->register( 'tmp102', $tmp102 );

while( 1 ) {
    my $celsius    = $webio->temp_celsius( 'tmp102' );
    my $fahrenheit = $webio->temp_fahrenheit( 'tmp102' );
    say 'Temp: ' . $celsius . 'C (' . $fahrenheit . 'F)';
    sleep 1;
}
