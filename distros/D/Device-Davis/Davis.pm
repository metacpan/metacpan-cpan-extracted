package Device::Davis;

require 5.005_62;
use strict;
use warnings;

require Exporter;
require DynaLoader;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Davis ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(station_open put_string get_char crc_accum put_unsigned
);
our $VERSION = '1.2.3';

bootstrap Device::Davis $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Device::Davis - Perl extension for communicating with Davis weather stations

=head1 SYNOPSIS

  use Device::Davis;
  $fd = station_open($tty);
  put_string($fd, "$string");
  $char = get_char($fd);
  $crc = crc_accum($crc, $data_byte);
  put_unsigned($fd, $num);

=head1 DESCRIPTION

Davis is a Perl 5 module that facilitates communication with Davis weather stations.  This module should work on most unix systems, however it was developed on Linux.  

B<station_open()> takes the tty where the station is connected as an argument and opens the tty with the correct parameters for communication.  The baud rate that is used matches the factory default of the Vantage Pro, which is 19200.  If you need to use a different baud rate, you will need to modify the Davis.xs file before compiling the module.

B<put_string()> takes a file descriptor (NOT a perl filehandle) and the string to send as arguments and sends the string to the weather station.  This function will return the number of bytes written.

B<get_char()> takes a file descriptor as an argument and retuns 1 byte from the weather station.  

B<crc_accum()> is an accumulator for the crc calculation.  It takes the previous value of the crc that has been accumulated ($crc) and the new data byte that needs to be added to the accumulated total.  Be sure to initialize $crc to 0 before sending a new set of data bytes.  The function will return the new accumulated crc value.  Once you pass in the crc value received from the weather station, the function should return a 0 if the crc check passed.  If you are sending commands to the station, the last value returned by the function should be what you send to the station as the crc value.  Note that the station expects the most significant byte of the crc to be sent first, which is opposite of how regular data values are sent.  

B<put_unsigned()> is for sending numeric values to the station.  It takes the file descriptor and the character to send as arguments.  It will send it's argument as a one byte unsigned character.  It will return the number of bytes written. 

=head1 EXAMPLES

	$bytes = put_string($fd, "\n");
	$bytes = put_string($fd, "TEST\n");

Reading the results from a LOOP 1 request:

	$crc = 0;
	while($index < 100){
           $data[$index] = get_char($fd);

The first byte returned by the station in a LOOP 1 packet is an ACK (0x06) and should not be included in the crc.  

           if($index){$crc = crc_accum($crc, $data[$index]);};
	   $data[$index] = sprintf("%02x", "$data[$index]"); # Convert to hex
           $index++;
	};

At this point the value of $crc should be 0 if there were no transmission errors, and you can continue to process the packet.

Sending a command or other value to the station:

We will want to calculate the value for the crc by running each byte we will send through crc_accum().

	$crc = crc_accum($crc, 0xc6);
	$crc = crc_accum($crc, 0xce);
	$crc = crc_accum($crc, 0xa2);
	$crc = crc_accum($crc, 0x03)
;
Let's say at this point that the value of $crc is e2b4.  If we are sending a command to the weather station, we should send e2b4 (most significant byte first) to the station.  

	$msbyte = $crc >> 8;  # For our example equals e2
	put_unsigned($fd, $msbyte);
	$lsbyte = $crc << 24;
	$lsbyte = $lsbyte >> 24;  # For our example equals b4
	put_unsigned($fd, $lsbyte);

=head2 EXPORT

station_open(), put_string(), get_char(), crc_accum(), put_unsigned()

=head1 AUTHOR

Stan Sander stsander@sblan.net

=head1 CREDITS

I used as an example the source code for the getweather utility written by Lew Riley (rileyle@earlham.edu http://www.cs.earlham.edu/~weather/).  The Serial Programming Guide for Posix Operating Systems currently maintained by Michael R. Sweet (http://www.easysw.com/~mike/serial/serial.htm) was invaluable as a reference.  
Wes Young also provided a patch to allow the module to work on a Mac.

=head1 SEE ALSO

perl(1) POSIX(3)

B<vanprod> available at http://www.cpan.org/scripts/index.html

=cut
