use strict;
use warnings;

use Device::FTDI qw( :bits :stop :parity :break :bitmode );

my $dev = Device::FTDI->new();
$dev->reset;

$dev->set_baudrate( 57600 );
$dev->set_line_property( BITS_8, STOP_BIT_1, PARITY_NONE, BREAK_OFF );

$dev->write_data( "Hello, world!\n" );
