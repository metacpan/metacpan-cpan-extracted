#!/usr/bin/perl
use v5.14;
use warnings;
use Device::Spektrum::Packet;
use HiPi::Wiring qw( :wiring );
use Device::SerialPort;

my $PORT = shift || '/dev/ttyAMA0';
my $PIN = 1; # GPIO 18 (P1 header pin 12)


HiPi::Wiring::wiringPiSetup();
HiPi::Wiring::pinMode( $PIN, WPI_INPUT );
HiPi::Wiring::pullUpDnControl( $PIN, WPI_PUD_UP );

my $serial = Device::SerialPort->new( '/dev/ttyAMA0' ) or die "Can't open port: $^E\n";
$serial->baudrate( 115_200 );
$serial->parity( 'none' );
$serial->stopbits( 1 );
$serial->databits( 8 );
$serial->write_settings or die "Can't write settings: $^E\n";


my $continue = 1;
while( $continue ) {
    my $input = HiPi::Wiring::digitalRead( $PIN );
    say $input;

    my $packet = Device::Spektrum::Packet->new({
        throttle => ($input ? SPEKTRUM_HIGH : SPEKTRUM_LOW),
        aileron => SPEKTRUM_LOW,
        elevator => SPEKTRUM_LOW,
        rudder => SPEKTRUM_HIGH,
        gear => SPEKTRUM_LOW,
        aux1 => SPEKTRUM_LOW,
        aux2 => SPEKTRUM_HIGH,
    });
    my $encoded_packet = $packet->encode_packet;
    $serial->write( $encoded_packet );
    $serial->purge_tx;
    $serial->write_done;
}

$serial->close;
