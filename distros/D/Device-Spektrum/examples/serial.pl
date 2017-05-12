#!perl
use v5.14;
use Device::SerialPort;
use Device::Spektrum::Packet;
use Time::HiRes qw( usleep );

use constant SLEEP_TIME_MICROSECONDS => 22_000;

my $PORT = shift || die "Need serial port\n";

my $serial = Device::SerialPort->new( $PORT ) or die "Can't open serial port: $^E\n";
$serial->baudrate( 115_200 );
$serial->parity( 'none' );
$serial->databits(8);
$serial->stopbits(1);
$serial->write_settings or die "Can't write settings: $^E\n";


say "Setup complete, going into write loop . . . ";
my $continue = 1;
while( $continue ) {
    my $packet = Device::Spektrum::Packet->new({
        throttle => SPEKTRUM_LOW,
        aileron => SPEKTRUM_MIDDLE,
        elevator => SPEKTRUM_HIGH,
        rudder => SPEKTRUM_LOW,
        gear => SPEKTRUM_MIDDLE,
        aux1 => SPEKTRUM_LOW,
        aux2 => SPEKTRUM_HIGH,
    });
    $serial->write( $packet->encode_packet );

    usleep( SLEEP_TIME_MICROSECONDS );
}

$serial->close;
