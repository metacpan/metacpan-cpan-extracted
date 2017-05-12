#!perl
use v5.14;
use Device::SerialPort;

use constant READ_LEN => 16;

my $PORT = shift || die "Need port to read\n";

my $serial = Device::SerialPort->new( $PORT );
$serial->baudrate( 115_900 );
$serial->parity( 'none' );
$serial->stopbits( 1 );
$serial->databits( 8 );

my $continue = 1;
while( $continue ) {
    my ($count_in, $string_in) = $serial->read(READ_LEN);
    next if $count_in != READ_LEN;

    my @bytes = unpack 'C*', $string_in;
    my $hex = sprintf( ('%02x ' x scalar(@bytes)), @bytes );
    say "Got frame ($count_in bytes): $hex";
}

$serial->close;
