
=head1 NAME

Device::TNC::KISS - Device::TNC subclass interface to a KISS mode TNC

=head1 DESCRIPTION

This module trys to implement an easy way to talk to a KISS mode Terminal Node
Controller (TNC) such as the TNC-X via a serial port.

=head1 SYNOPSIS

  use Device::TNC::KISS;

  To read data direct from a TNC:
  my %tnc_config = (
    'port' => ($Config{'osname'} eq "MSWin32") ? "COM3" : "/dev/TNC-X",
    'baudrate' => 9600,
    'warn_malformed_kiss' => 1,
    'raw_log' => "raw_packet.log",
  );

  To read data from a raw KISS log file
  my %tnc_config = (
    'warn_malformed_kiss' => 1,
    'file' => "raw_packet.log",
  );

  my $kiss_tnc = new Device::TNC::KISS(%tnc_config);

  my $kiss_frame = $kiss_tnc->read_kiss_frame();
  my @kiss_frame = $kiss_tnc->read_kiss_frame();

  my ($kiss_type, $hdlc_frame) = $kiss_tnc->read_hdlc_frame();
  my ($kiss_type, @hdlc_frame) = $kiss_tnc->read_hdlc_frame();

This module was developed on Linux and Windows. It should work for any UNIX like
operating system where the Device::SerialPort module can be used.

=cut

package Device::TNC::KISS;

####################
# Standard Modules
use strict;
use Config;
use FileHandle 2.0;
# Custom modules
use Device::TNC;

####################
# Variables
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
@ISA = qw( Device::TNC );
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = 0.01;
$| = 1;


####################
# Functions

if ($Config{'osname'} eq "MSWin32")
{
	require Win32::SerialPort;
	Win32::SerialPort->import( qw( :STAT 0.19 ) );
}
else
{
	require Device::SerialPort;
}

my $FEND  = 0xC0; # Frame end
my $FESC  = 0xDB; # Frame escape
my $TFEND = 0xDC; # Transposed frame end
my $TFESC = 0xDD; # Transposed frame escape

my $m_port = undef;
my $m_port_name = undef;
my $m_raw_log = undef;

################################################################################

=head2 B<new()>

 my %port_data = { 'option' => 'value' };
 my $kiss_tnc = new Device::TNC::KISS(%port_data);

The new method creates and returns a new Device::TNC::KISS object that can be
used to communicate with a KISS mode terminal node controller.

The method requires that a hash of settings be passed.
If the port and baudrate are not set in the passed settings or the port cannot
be opened an error message is printed and undef returned.

=head3 Options and values

=over 4

=item B<port>

This sets the serial port name as appropriate for the operating system.
For UNIX this will be something like /dev/ttyS0 and for Windows this will be
something like COM1

=item B<baudrate>

The baud rate is the speed the TNC is configured to talk at. i.e. 1200 baud.

=item B<warn_malformed_kiss>

To see warnings about malformed KISS frames then set this option to a true value

=item B<raw_log>

If you want to keep a log of the raw packets that are read then set raw_log to
the name of the log file you which to write to. If there is an error opening the
log file the

=item B<file>

Use to read KISS frames from a file instead of a port. Using this option will
cause the module to ignore any port, baudrate and raw_log options.

The value for this option should be a raw KISS log file such as that created via
the raw_log option.

=back

The returned object contains a reference to a serial port object which is either a
Device::SerialPort (UNIX) or Win32::SerialPort (Windows) object.

The serial port is initialised will the following

 $kiss_tnc->{'PORT'}->parity("none");
 $kiss_tnc->{'PORT'}->databits(8);
 $kiss_tnc->{'PORT'}->stopbits(1);
 $kiss_tnc->{'PORT'}->handshake("none");
 $kiss_tnc->{'PORT'}->read_interval(100) if $Config{'osname'} eq "MSWin32";
 $kiss_tnc->{'PORT'}->read_char_time(0);
 $kiss_tnc->{'PORT'}->read_const_time(1000);

For more details on this see the documentation for Device::SerialPort (UNIX) or
Win32::SerialPort (Windows).

=cut

sub new
{
	my $class = shift;
	my %port_data = @_;

	my $baudrate;
	my %data;
	my $raw_log_file;
	foreach my $key (keys %port_data)
	{
		if (lc($key) eq "port")
		{
			$m_port_name = $port_data{$key};
		}
		if (lc($key) eq "baudrate")
		{
			$baudrate = $port_data{$key};
		}
		if (lc($key) eq "warn_malformed_kiss")
		{
			$data{'WARN_MALFORMED_KISS'} = 1;
		}
		if (lc($key) eq "file")
		{
			$data{'FILE'} = $port_data{$key};
		}
		if (lc($key) eq "raw_log")
		{
			$raw_log_file = $port_data{$key};
		}
	}

	if ($data{'FILE'})
	{
		my $file = new FileHandle();
		if ($file->open("<$data{'FILE'}"))
		{
			$file->autoflush(1);
			$data{'FILE_HANDLE'} = $file;
		}
		else
		{
			warn "Warning: Cannot open raw KISS log file \"$data{'FILE'}\" for reading: $!\n";
			return undef;
		}
	}
	else
	{
		$m_raw_log = new FileHandle();
		if ($m_raw_log->open(">>$raw_log_file"))
		{
			$m_raw_log->autoflush(1);
			$data{'RAW_LOG'} = $m_raw_log;
		}
		else
		{
			warn "Warning: Cannot open raw log file \"$raw_log_file\" for append: $!\n";
		}

		unless ($m_port_name)
		{
			warn "Error: No port was specified in the passed data.\n";
			return undef;
		}
		unless ($baudrate)
		{
			warn "Error: No baudrate was specified in the passed data.\n";
			return undef;
		}

		if ($Config{'osname'} eq "MSWin32")
		{
			$m_port = new Win32::SerialPort($m_port_name) or
				warn "Error: Cannot open serial port \"$m_port_name\": $^E\n";
		}
		else
		{
			$m_port = new Device::SerialPort($m_port_name) or
				warn "Error: Cannot open serial port \"$m_port_name\": $!\n";
		}
		$m_port->baudrate($baudrate);
		$m_port->parity("none");
		$m_port->databits(8);
		$m_port->stopbits(1);
		$m_port->handshake("none");
		$m_port->read_interval(100) if $Config{'osname'} eq "MSWin32";
		$m_port->read_char_time(0);
		$m_port->read_const_time(1000);

		$data{'PORT'} = $m_port;
	}
	my $self = bless \%data, $class;

	return $self;
}

# When we close try and close the port too.
DESTROY
{
	# Close the serial port
	$m_port->close() or
		warn "Error: Failed to the serial port \"$m_port_name\": $!\n";

	# Close the raw log file if we have opened it.
	$m_raw_log->close() if $m_raw_log;

}

################################################################################

=head2 B<read_kiss_frame()>

 my $kiss_frame = $kiss_tnc->read_kiss_frame();
 my @kiss_frame = $kiss_tnc->read_kiss_frame();

This method reads a KISS frame from the TNC and returns it. This has not had
the FEND, FESC, TFEND and TFESC bytes stripped out.

=cut

sub read_kiss_frame
{
	my $self = shift;
	my @frame;
	my $fend_count = 0;
	if ($self->{'FILE'})
	{
		while(1)
		{
			# Processing the file one byte at a time
			my $saw = $self->{'FILE_HANDLE'}->getc();

			$fend_count++ if (ord($saw) == $FEND);
			# Make sure we don't add bytes to the frame that are before the first FEND
			push @frame, $saw if $fend_count > 0;

			if ($fend_count == 2)
			{
				if (scalar @frame > 2)
				{
					# We have data in the frame so return it.
					last;
				}
				else
				{
					# we have an empty frame or we got the end of one frame and the start of another.
					# So start the search again.
					$fend_count--;
					@frame = ($saw);
				}
			}
		}
	}
	else
	{
		while(1)
		{
			# Processing one byte at a time makes things nice and easy
			my ($count,$saw) = $self->{'PORT'}->read(1);
			if ($count > 0)
			{
				$self->{'RAW_LOG'}->write($saw) if $self->{'RAW_LOG'};
				$fend_count++ if (ord($saw) == $FEND);
				# Make sure we don't add bytes to the frame that are before the first FEND
				push @frame, $saw if $fend_count > 0;

				if ($fend_count == 2)
				{
					if (scalar @frame > 2)
					{
						# We have data in the frame so return it.
						last;
					}
					else
					{
						# we have an empty frame or we got the end of one frame and the start of another.
						# So start the search again.
						$fend_count--;
						@frame = ($saw);
					}
				}
			}
		}
	}
	$self->{'LAST_KISS_FRAME_LENGTH'} = scalar @frame;

	if (wantarray)
	{
		return @frame;
	}
	else
	{
		my $frame = join '', @frame;
		return $frame;
	}
}

################################################################################

=head2 B<read_hdlc_frame()>

 my ($kiss_type, $hdlc_frame) = $kiss_tnc->read_hdlc_frame();
 my ($kiss_type, @hdlc_frame) = $kiss_tnc->read_hdlc_frame();

This method reads a KISS frame from the TNC and strips out the KISS FEND, FESC,
TFEND and TFESC bytes and returns the KISS type byte followed by the HDLC frame.

The value of type indicator byte is use to distinguish between command and data
frames.

From: The KISS TNC: A simple Host-to-TNC communications protocol
L<http://people.qualcomm.com/karn/papers/kiss.html>

To distinguish between command and data frames on the host/TNC link, the first
byte of each asynchronous frame between host and TNC is a "type" indicator. This
type indicator byte is broken into two 4-bit nibbles so that the low-order
nibble indicates the command number (given in the table below) and the
high-order nibble indicates the port number for that particular command.
In systems with only one HDLC port, it is by definition Port 0. In multi-port
TNCs, the upper 4 bits of the type indicator byte can specify one of up to
sixteen ports. The following commands are defined in frames to the TNC (the
"Command" field is in hexadecimal):

 Command       Function         Comments
   0           Data frame       The  rest  of the frame is data to
                                be sent on the HDLC channel.

   1           TXDELAY          The next  byte  is  the  transmitter
                                keyup  delay  in  10 ms units.
                		The default start-up value is 50
                                (i.e., 500 ms).

   2           P                The next byte  is  the  persistence
                                parameter,  p, scaled to the range
                                0 - 255 with the following
                                formula:

                                         P = p * 256 - 1

                                The  default  value  is  P  =  63
                                (i.e.,  p  =  0.25).

   3           SlotTime         The next byte is the slot interval
                                in 10 ms units.
                                The default is 10 (i.e., 100ms).

   4           TXtail           The next byte is the time to hold
                                up the TX after the FCS has been
                                sent, in 10 ms units.  This command
                                is obsolete, and is included  here
                                only for  compatibility  with  some
                                existing  implementations.

   5          FullDuplex        The next byte is 0 for half duplex,
                                nonzero  for full  duplex.
                                The  default  is  0
                                (i.e.,  half  duplex).

   6          SetHardware       Specific for each TNC.  In the
                                TNC-1, this command  sets  the
                                modem speed.  Other implementations
                                may use this function  for   other
                                hardware-specific   functions.

   FF         Return            Exit KISS and return control to a
                                higher-level program. This is useful
                                only when KISS is  incorporated
                                into  the TNC along with other
                                applications.

The following types are defined in frames to the host:

Type			Function		Comments

  0                 Data frame       Rest of frame is data from
                                     the HDLC channel.

No other types are defined; in particular, there is no provision for
acknowledging data or command frames sent to the TNC. KISS implementations must
ignore any unsupported command types. All KISS implementations must implement
commands 0,1,2,3 and 5; the others are optional.

=cut

sub read_hdlc_frame
{
	my $self = shift;

	# This is what we will return
	my @frame;
	my $type;

	# This is not the simplest method of getting the data but it allows for
	# for catching errors.
	my @kiss = $self->read_kiss_frame();
	for (my $location = 0; $location <= $#kiss; $location++)
	{
		if ($location == 0)
		{
			# We should find an FEND here. If not print a warning.
			unless (ord($kiss[$location]) == $FEND)
			{
				warn "Warning: Malformed KISS frame read. Didn't start with FEND\n" if $self->{'WARN_MALFORMED_KISS'};
			}
		}
		elsif ($location == $#kiss)
		{
			# We should find an FEND here. If not print a warning.
			unless (ord($kiss[$location]) == $FEND)
			{
				warn "Warning: Malformed KISS frame read. Didn't end with FEND\n" if $self->{'WARN_MALFORMED_KISS'};
			}
		}
		elsif ($location == 1)
		{
			# This is the type byte
			$type = $kiss[$location];
		}
		else
		{
			# this is the data but may contains transposed bytes
			# FEND, FESC, TFEND and TFESC
			if (ord($kiss[$location]) == $FESC)
			{
				# Entered frame escape mode
				if (ord($kiss[$location + 1]) == $TFESC)
				{
					#warn "Un-Transposed a FESC\n";
					push @frame, pack("c", $FESC);
					$location++;
				}
				elsif (ord($kiss[$location + 1]) == $TFEND)
				{
					#warn "Un-Transposed a FEND\n";
					push @frame, pack("c", $FEND);
					$location++;
				}
				elsif (ord($kiss[$location + 1]) != $TFESC)
				{
					warn "Warning: Malformed KISS frame read. Expected TFESC after FESC\n" if $self->{'WARN_MALFORMED_KISS'};
				}
				elsif (ord($kiss[$location + 1]) != $TFEND)
				{
					warn "Warning: Malformed KISS frame read. Expected TFEND after FESC\n" if $self->{'WARN_MALFORMED_KISS'};
				}
			}
			else
			{
				push @frame, $kiss[$location];
			}
		}
	}

	if (wantarray)
	{
		return $type, @frame;
	}
	else
	{
		my $frame = join '', @frame;
		return $type, $frame;
	}
}

1;

__END__

=head1 SEE ALSO

 Device::SerialPort
 Win32::SerialPort

L<http://people.qualcomm.com/karn/papers/kiss.html>

=head1 AUTHOR

R Bernard Davison E<lt>bdavison@asri.org.auE<gt>

=head1 COPYRIGHT

Copyright (C) 2007, Australian Space Research Institute.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
