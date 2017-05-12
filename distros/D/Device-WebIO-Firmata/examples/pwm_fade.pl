#!env perl
use v5.12;
use Device::WebIO;
use Device::WebIO::Firmata;
use Time::HiRes 'sleep';

use constant STEP_INC => 16;
use constant PIN      => 11;

my $PORT = shift or die "Need port to connect to\n";

my $webio = Device::WebIO->new;
my $firmata = Device::WebIO::Firmata->new({
    port => $PORT,
});
$webio->register( 'foo', $firmata );
my $MAX_VALUE = $webio->pwm_max_int( 'foo', PIN );


my $do_increase_value = 1;
my $value = 0;
while( 1 ) {
    if( $do_increase_value ) {
        $value += STEP_INC;
        if( $value >= $MAX_VALUE ) {
            $value = $MAX_VALUE;
            $do_increase_value = 0;
        }
    }
    else {
        $value -= STEP_INC;
        if( $value <= 0 ) {
            $value = 0;
            $do_increase_value = 1;
        }
    }

    $webio->pwm_output_int( 'foo', PIN, $value );
    sleep 0.1;
}
