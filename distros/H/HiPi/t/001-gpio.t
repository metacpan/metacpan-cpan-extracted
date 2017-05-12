#!perl

use Test::More tests => 29;
use HiPi qw( :rpi );
use HiPi::RaspberryPi;
use Time::HiRes;

my $sleepwait = 1000;

SKIP: {
      skip 'not in dist testing', 29 unless $ENV{HIPI_MODULES_DIST_TEST};

use_ok( 'HiPi::RaspberryPi' );
require HiPi::GPIO;
my $gpio = HiPi::GPIO->new;

# MODE
$gpio->set_pin_mode( RPI_PIN_36, RPI_MODE_ALT5 );
Time::HiRes::usleep($sleepwait);
is( $gpio->get_pin_mode( RPI_PIN_36 ), RPI_MODE_ALT5, 'pin mode ALT5');

$gpio->set_pin_mode( RPI_PIN_36, RPI_MODE_INPUT );
Time::HiRes::usleep($sleepwait);
is( $gpio->get_pin_mode( RPI_PIN_36 ), RPI_MODE_INPUT, 'pin mode output');

$gpio->set_pin_pud( RPI_PIN_36, RPI_PUD_UP );
Time::HiRes::usleep($sleepwait);
is( $gpio->pin_read( RPI_PIN_36 ), RPI_HIGH, 'pin pud up');
is( $gpio->get_pin_level( RPI_PIN_36 ), RPI_HIGH, 'pin pud up - level');

$gpio->set_pin_pud( RPI_PIN_36, RPI_PUD_DOWN );
Time::HiRes::usleep($sleepwait);
is( $gpio->pin_read( RPI_PIN_36 ), RPI_LOW, 'pin pud low');
is( $gpio->get_pin_level( RPI_PIN_36 ), RPI_LOW, 'pin pud low - level');

$gpio->set_pin_pud( RPI_PIN_36, RPI_PUD_OFF );

# edge detection
{
    # 22 tests
    my @maskbits = ( RPI_INT_FALL ,RPI_INT_RISE , RPI_INT_AFALL , RPI_INT_ARISE , RPI_INT_HIGH , RPI_INT_LOW );
    my $pin = $gpio->get_pin( RPI_PIN_36 );
    while( @maskbits ) {
        my $edgemask = 0;
        $edgemask |= $_ for ( @maskbits );
        $pin->interrupt($edgemask);
        Time::HiRes::usleep($sleepwait);
        is( $pin->interrupt, $edgemask, qq(pin edgemask $edgemask));
        isnt( $pin->interrupt, 0, qq(pin edgemask $edgemask));
        pop @maskbits;
    }
    $pin->interrupt(RPI_INT_NONE);
    Time::HiRes::usleep($sleepwait);
    is( $pin->interrupt, RPI_INT_NONE, qq(pin edgemask none));
    
    $pin->set_pud(RPI_PUD_DOWN );
    $pin->interrupt(RPI_INT_RISE);
    $pin->clear_edge_detect;
    Time::HiRes::usleep($sleepwait);
    is( $pin->value, RPI_LOW, 'pin low on edge pud down');
    is( $pin->get_edge_detect, 0, 'no ren detected edge pud down');
    $pin->set_pud(RPI_PUD_UP);
    Time::HiRes::usleep($sleepwait);
    is( $pin->get_edge_detect, 1, 'ren detected edge pud up');
    is( $pin->value, 1, 'value edge pud up');
    
    $pin->interrupt(RPI_INT_NONE);
    Time::HiRes::usleep($sleepwait);
    is( $pin->interrupt, RPI_INT_NONE, qq(pin edgemask none));
    $pin->interrupt(RPI_INT_FALL);
    $pin->clear_edge_detect;
    Time::HiRes::usleep($sleepwait);
    is( $pin->value, RPI_HIGH, 'pin high on edge pud up');
    is( $pin->get_edge_detect, 0, 'no fen detected edge pud up');
    $pin->set_pud(RPI_PUD_DOWN);
    Time::HiRes::usleep($sleepwait);
    is( $pin->get_edge_detect, 1, 'fen detected edge pud down');
    is( $pin->value, 0, 'value edge pud down');
    
    # clean up
    $pin->interrupt(RPI_INT_NONE);
    $pin->clear_edge_detect;
    $pin->set_pud(RPI_PUD_OFF);

}

} # End SKIP

1;
