#!env perl
use v5.14;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use Time::HiRes 'sleep';

use constant SLEEP_MS => 0.001;
use constant OUTPUT_PIN => 0;


my $rpi = Device::WebIO::RaspberryPi->new({
    type => Device::WebIO::RaspberryPi->TYPE_REV2,
});

my $webio = Device::WebIO->new;
$webio->register( 'rpi', $rpi );

my $do_count_down = 0;
my $count = 0;
print "Fading\n";
while(1) {
    if( $rpi->pwm_max_int() <= $count ) {
        $do_count_down = 1;
    }
    elsif( 0 >= $count ) {
        $do_count_down = 0;
    }

    if( $do_count_down ) {
        $count--;
    }
    else {
        $count++;
    }

    $webio->pwm_output_int( 'rpi', OUTPUT_PIN, $count );
    sleep SLEEP_MS;
}
