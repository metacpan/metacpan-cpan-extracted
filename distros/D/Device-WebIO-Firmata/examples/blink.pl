#!env perl
use v5.12;
use Device::WebIO;
use Device::WebIO::Firmata;

use constant PIN => 13;

my $PORT = shift or die "Need port to connect to\n";

my $webio = Device::WebIO->new;
my $firmata = Device::WebIO::Firmata->new({
    port => $PORT,
});
$webio->register( 'foo', $firmata );

$webio->set_as_output( 'foo', PIN );
while( 1 ) {
    $webio->digital_output( 'foo', PIN, 1 );
    sleep 1;
    $webio->digital_output( 'foo', PIN, 0 );
    sleep 1;
}
