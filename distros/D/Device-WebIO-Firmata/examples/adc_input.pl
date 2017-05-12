#!env perl
use v5.14;
use Device::WebIO;
use Device::WebIO::Firmata;

use constant PIN => 0;


my $PORT = shift or die "Need port to connect to\n";

my $webio = Device::WebIO->new;
my $firmata = Device::WebIO::Firmata->new({
    port => $PORT,
});
$webio->register( 'foo', $firmata );


while( 1 ) {
    my $value = $webio->adc_input_int( 'foo', PIN );
    warn "Got: [$value]\n";
    sleep 1;
}
