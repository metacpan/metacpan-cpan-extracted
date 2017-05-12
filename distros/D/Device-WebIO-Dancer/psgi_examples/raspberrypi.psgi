use Dancer;
use lib '.';
use Device::WebIO::Dancer;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use Plack::Builder;

my $webio = Device::WebIO->new;
my $rpi = Device::WebIO::RaspberryPi->new;
$webio->register( 'rpi', $rpi );

Device::WebIO::Dancer::init( $webio, 'rpi' );

 
builder {
    set log => 'core';
    set show_errors => 1;
    set public => '/var/www/app';

    dance;
};
