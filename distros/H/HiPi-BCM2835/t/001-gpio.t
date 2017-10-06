#!perl

use Test::More tests => 24;
use HiPi qw( :rpi );
use HiPi::RaspberryPi;
use Time::HiRes;

my $sleepwait = 1000;

SKIP: {
      skip 'not in dist testing', 24 unless $ENV{HIPI_BCM2385_DIST_TEST_GPIO};


diag('BCM2835 GPIO tests are running');

use_ok( 'HiPi::BCM2835' );
use HiPi::BCM2835 qw( :all );

my $gpio = HiPi::BCM2835->new;

## MODE
$gpio->gpio_fsel( RPI_PIN_36, BCM2835_GPIO_FSEL_INPT );
Time::HiRes::usleep($sleepwait);
is ( $gpio->gpio_fget( RPI_PIN_36 ), RPI_MODE_INPUT, 'pin mode input');
is ( $gpio->gpio_fget_name( RPI_PIN_36 ), 'INPUT', 'gpio function name' );


$gpio->gpio_fsel( RPI_PIN_36, RPI_MODE_OUTPUT );
Time::HiRes::usleep($sleepwait);
is( $gpio->gpio_fget( RPI_PIN_36 ), BCM2835_GPIO_FSEL_OUTP, 'pin mode output');
is ( $gpio->gpio_fget_name( RPI_PIN_36 ), 'OUTPUT', 'gpio function name' );

$gpio->gpio_fsel( RPI_PIN_36, BCM2835_GPIO_FSEL_INPT );
Time::HiRes::usleep($sleepwait);
is ( $gpio->gpio_fget( RPI_PIN_36 ), BCM2835_GPIO_FSEL_INPT, 'pin mode input reset');

$gpio->gpio_set_pud( RPI_PIN_36, BCM2835_GPIO_PUD_UP );
Time::HiRes::usleep($sleepwait);
is( $gpio->gpio_lev( RPI_PIN_36 ), RPI_HIGH, 'pin pud up');

$gpio->gpio_set_pud( RPI_PIN_36, BCM2835_GPIO_PUD_OFF );
Time::HiRes::usleep($sleepwait);

$gpio->gpio_set_pud( RPI_PIN_36, BCM2835_GPIO_PUD_DOWN );
Time::HiRes::usleep($sleepwait);
is( $gpio->gpio_lev( RPI_PIN_36 ), RPI_LOW, 'pin pud down');


$gpio->gpio_set_pud( RPI_PIN_36, BCM2835_GPIO_PUD_OFF );


Time::HiRes::usleep($sleepwait);
# pins

my $pin = $gpio->get_pin( RPI_PIN_36 );

$pin->mode( RPI_MODE_INPUT );
Time::HiRes::usleep($sleepwait);
is ( $pin->mode(), RPI_MODE_INPUT, 'PIN pin mode input');
#
$pin->mode(  RPI_MODE_OUTPUT );
Time::HiRes::usleep($sleepwait);
is( $pin->mode(  ), RPI_MODE_OUTPUT, 'pin mode output');

$pin->mode(  RPI_MODE_INPUT );
Time::HiRes::usleep($sleepwait);
is( $pin->mode(  ), RPI_MODE_INPUT, 'pin mode input reset');

$pin->set_pud(  RPI_PUD_UP );
Time::HiRes::usleep($sleepwait);
is( $pin->value( ), RPI_HIGH, 'pin pud up');

$pin->set_pud(  RPI_PUD_OFF );
Time::HiRes::usleep($sleepwait);

$pin->set_pud(  RPI_PUD_DOWN );
Time::HiRes::usleep($sleepwait);
is( $pin->value(  ), RPI_LOW, 'pin pud low');

$pin->set_pud( RPI_PUD_OFF );


# OUTPUT

is ( $gpio->gpio_fget( RPI_PIN_37 ),, RPI_MODE_INPUT, 'output pin mode input');
$gpio->gpio_fsel( RPI_PIN_37, RPI_MODE_OUTPUT );
Time::HiRes::usleep($sleepwait);
is ( $gpio->gpio_fget( RPI_PIN_37 ), RPI_MODE_OUTPUT, 'output pin mode output');

is ( $gpio->gpio_lev( RPI_PIN_37 ), 0, 'gpio output pin reads 0');
$gpio->gpio_write( RPI_PIN_37, 1 );
diag 'LED IS ON';
sleep(4); # see the LED
is ( $gpio->gpio_lev( RPI_PIN_37 ), 1, 'gpio output pin reads 1');
$gpio->gpio_write( RPI_PIN_37, 0 );
diag 'LED IS OFF';
sleep(4); # see the LED
$gpio->gpio_fsel( RPI_PIN_37, RPI_MODE_INPUT );

# PIN Interface

my $pinout = $gpio->get_pin( RPI_PIN_37 );

is ( $pinout->mode(), RPI_MODE_INPUT, 'PIN output pin mode input');
is ( $pinout->get_function(), 'INPUT', 'pin function name' );

$pinout->mode( RPI_MODE_OUTPUT );
Time::HiRes::usleep($sleepwait);
is ( $pinout->mode(), RPI_MODE_OUTPUT, 'PIN output pin mode output');
is ( $pinout->get_function(), 'OUTPUT', 'pin function name' );

is ( $pinout->value(), 0, 'PIN gpio output pin reads 0');
$pinout->value( 1 );
diag 'PIN LED IS ON';
sleep(4); # see the LED
is ( $pinout->value(), 1, 'PIN gpio output pin reads 1');
$pinout->value( 0 );
diag 'PIN LED IS OFF';
sleep(4); # see the LED
$pinout->mode( RPI_MODE_INPUT );
is ( $pinout->get_function(), 'INPUT', 'pin function name' );


} # End SKIP

1;
