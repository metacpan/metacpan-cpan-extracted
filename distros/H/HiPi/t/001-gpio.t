#!perl

use Test::More tests => 34;
use HiPi qw( :rpi );
use HiPi::RaspberryPi;
use Time::HiRes;

my $sleepwait = 1000;

SKIP: {
      skip 'not in dist testing', 34 unless $ENV{HIPI_MODULES_DIST_TEST_GPIO};




diag('GPIO (/dev/gpiomem) tests are running');

use_ok( 'HiPi::GPIO' );

my $gpio = HiPi::GPIO->new;

## MODE
$gpio->set_pin_mode( RPI_PIN_36, RPI_MODE_INPUT );
Time::HiRes::usleep($sleepwait);
is ( $gpio->get_pin_mode( RPI_PIN_36 ), RPI_MODE_INPUT, 'pin mode input');
is ( $gpio->get_pin_function( RPI_PIN_36 ), 'INPUT', 'gpio function name' );

$gpio->set_pin_mode( RPI_PIN_36, RPI_MODE_OUTPUT );
Time::HiRes::usleep($sleepwait);
is( $gpio->get_pin_mode( RPI_PIN_36 ), RPI_MODE_OUTPUT, 'pin mode output');
is ( $gpio->get_pin_function( RPI_PIN_36 ), 'OUTPUT', 'gpio function name' );


$gpio->set_pin_mode( RPI_PIN_36, RPI_MODE_INPUT );
Time::HiRes::usleep($sleepwait);
is( $gpio->get_pin_mode( RPI_PIN_36 ), RPI_MODE_INPUT, 'pin mode input reset');

$gpio->set_pin_pud( RPI_PIN_36, RPI_PUD_UP );
Time::HiRes::usleep($sleepwait);
is( $gpio->pin_read( RPI_PIN_36 ), RPI_HIGH, 'pin pud up');
is( $gpio->get_pin_level( RPI_PIN_36 ), RPI_HIGH, 'pin pud up - level');

$gpio->set_pin_pud( RPI_PIN_36, RPI_PUD_OFF );
Time::HiRes::usleep($sleepwait);

$gpio->set_pin_pud( RPI_PIN_36, RPI_PUD_DOWN );
Time::HiRes::usleep($sleepwait);
is( $gpio->pin_read( RPI_PIN_36 ), RPI_LOW, 'pin pud low');
is( $gpio->get_pin_level( RPI_PIN_36 ), RPI_LOW, 'pin pud low - level');

$gpio->set_pin_pud( RPI_PIN_36, RPI_PUD_OFF );

is( $gpio->get_pin_interrupt_filepath( RPI_PIN_36 ), undef, 'pin interrupt filepath');

is( $gpio->get_pin_activelow( RPI_PIN_36 ), undef, 'active low is 0');

$gpio->set_pin_activelow( RPI_PIN_36, 1 );
Time::HiRes::usleep($sleepwait);
is( $gpio->get_pin_activelow( RPI_PIN_36 ), undef, 'active low is 1');

$gpio->set_pin_activelow( RPI_PIN_36, 0 );
Time::HiRes::usleep($sleepwait);
is( $gpio->get_pin_activelow( RPI_PIN_36 ), undef, 'active low is reset');


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

is( $pin->get_interrupt_filepath(), undef, 'PIN pin interrupt filepath');

is( $pin->active_low( ), undef, 'PIN active low is 0');

$pin->active_low(  1 );
Time::HiRes::usleep($sleepwait);
is( $pin->active_low(), undef, 'PIN active low is 1');

$pin->active_low( 0 );
Time::HiRes::usleep($sleepwait);
is( $pin->active_low(), undef, 'PIN active low is reset');


# OUTPUT

is ( $gpio->get_pin_mode( RPI_PIN_37 ), RPI_MODE_INPUT, 'output pin mode input');
$gpio->set_pin_mode( RPI_PIN_37, RPI_MODE_OUTPUT );
Time::HiRes::usleep($sleepwait);
is ( $gpio->get_pin_mode( RPI_PIN_37 ), RPI_MODE_OUTPUT, 'output pin mode output');

is ( $gpio->pin_read( RPI_PIN_37 ), 0, 'gpio output pin reads 0');
$gpio->pin_write( RPI_PIN_37, 1 );
diag 'LED IS ON';
sleep(4); # see the LED
is ( $gpio->pin_read( RPI_PIN_37 ), 1, 'gpio output pin reads 1');
$gpio->pin_write( RPI_PIN_37, 0 );
diag 'LED IS OFF';
sleep(4); # see the LED
$gpio->set_pin_mode( RPI_PIN_37, RPI_MODE_INPUT );

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