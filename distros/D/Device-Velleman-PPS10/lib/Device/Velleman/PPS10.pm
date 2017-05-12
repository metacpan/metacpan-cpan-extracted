package Device::Velleman::PPS10;

################################################################################
# Class for reading data from Velleman pps10 scope over serial line.
# Currently the module is geared towards processing only BA packets.
# 
# Note: This may work for the HPS40 model, but is untested.
#       Tested only on a Linux system.

use 5.008000;
use strict;
use warnings;

use base qw(Exporter);
BEGIN {
    our $VERSION = 0.03;
}

use Device::SerialPort;
use Hash::Util qw(lock_hash lock_keys);


################################################################################
# Scope Characteristics

use constant {
    # The ascii string of the delimiters defining the start of a data packet.
    # The binary values in the buffer will be matched in string context.
    BA_DELIM => 'BA' . chr(10) . chr(1),
    BR_DELIM => 'BR',
    BS_DELIM => 'BS' . chr(11) . chr(0),

    # There are 8 full divisions for volts on the scope LCD display spanning the 0-255 8-bit range output.
    POINTS_PER_VOLT_DIV => 32,	# number of points per division out of the full 8-bit 0-255 point range.
    POINTS_PER_TIME_DIV => 10,	# number of samples per division out of the full 256 samples per frame.

    # The voltage sample value defined to be the 0V baseline.
    BASELINE_POINT => 127,

    DEFAULT_SERIAL_PORT => '/dev/ttyS0',
    DEFAULT_SERIAL_READ => 255,
};

# Volts per divisions mappings for packet header values.
my @volts     = ('0.005', '0.01', '0.02', '0.05', '0.1', '0.2', '0.4', '1', '2', '4', '8', '20');
my @volts_10x = map { $_ * 10 } @volts;  # 10x
my %volt_divs;

# AC
@volt_divs{ 0 .. 11} = @volts;	    # 1x
@volt_divs{16 .. 27} = @volts_10x;  # 10x

# DC
@volt_divs{32 .. 43} = @volts;      # 1x
@volt_divs{48 .. 59} = @volts_10x;  # 10x

# Times in seconds.
# Note: there are higher time/div resolutions than 1 second.
#       It appears that the scope returns BR packets (and even BS packets) for times 0.5s/div and longer.
my @times = (
    '0.0000002',
    '0.0000005',
    '0.000001',
    '0.000002',
    '0.000005',			# 5 us
    '0.00001',
    '0.00002',
    '0.00005',
    '0.0001',
    '0.0002',
    '0.0005',
    '0.001',
    '0.002',
    '0.005',			# 5 ms
    '0.01',
    '0.02',
    '0.05',
    '0.1',
    '0.2',
    '0.5',
    '1'				# 1 s
    );

# Times per division mapping to header values.
my %time_divs;
@time_divs{ 0 .. 20} = @times;
@time_divs{64 .. 84} = @times;


################################################################################
# Local Functions

# Identify the packet type from the raw packet data.
# Simply check to see if the given strings begins with one of the delimiters.
sub _identify_packet_type {
    my $packet_bin = shift;

    if (index($packet_bin, BA_DELIM) == 0) {
	return 'BA';
    } elsif (index($packet_bin, BR_DELIM) == 0) {
	return 'BR';
    } elsif (index($packet_bin, BS_DELIM) == 0) {
	return 'BS';
    }
}

# Convert the trace data points from 0:255 to voltage according to v/div.
# Convert the time data points from 0:255 to time where the first sample is 0 seconds.
# The shift_only does not scale the values, but centers the voltage sample values on 127,
# the 0V baseline.
sub _format_trace {
    my ($p_info, $shift_only) = @_;

    # x_max: The width of the x-axis.
    # y_max: The height of the y-axis above and below the 0V baseline.

    my (@new_trace, @new_time);
    if ($shift_only) {
	# Simply shift the trace half-way down, where 127 is the 0V baseline.
	@new_trace = map { $_ - BASELINE_POINT } @{$p_info->{trace}};
	@new_time  = @{$p_info->{time}};

	$p_info->{x_max} = 256;
	$p_info->{y_max} = BASELINE_POINT;
    } else {
	# Scale the time points to seconds.
	if (my $time_per_point = $p_info->{time_per_point}) {
	    $p_info->{x_max} = 256 * $time_per_point;
	    @new_time        = map { $_ * $time_per_point } @{$p_info->{time}};
	} else {
	    @new_time  = @{$p_info->{time}};
	}

	# Scale the trace data volts/div.
	if (my $volts_per_point = $p_info->{volts_per_point}) {
	    $p_info->{y_max} = BASELINE_POINT * $volts_per_point;
	    @new_trace       = map { ($_ - BASELINE_POINT) * $volts_per_point } @{$p_info->{trace}};
	} else {
	    @new_trace = @{$p_info->{trace}};
	}
    }

    $p_info->{trace_scaled} = \@new_trace;
    $p_info->{time_scaled}  = \@new_time;

    return;
}


################################################################################
# Class Methods

# Return all the packet header code to /div translation hashes.
sub get_division_maps {
    my $class = shift;

    return { time_divs => { %time_divs },
	     volt_divs => { %volt_divs } };
}

# Make pps10 scope object.
sub new {
    my $class = shift;

    # Define defaults and allow them to be overridden.
    my %args = @_;
    my ($port, $read_bytes, $verbose, $debug) = @args{qw(port read_bytes verbose debug)};

    $port       = defined $port       ? $port       : DEFAULT_SERIAL_PORT;
    $read_bytes = defined $read_bytes ? $read_bytes : DEFAULT_SERIAL_READ;

    # Create a Serial port object, or fail here.
    my $sp = Device::SerialPort->new($port) or
	die "Could not open $port: $!\n";

    # Serial port settings specific to the Velleman PPS10.
    $sp->handshake('none');
    $sp->baudrate(57600);
    $sp->parity('none');
    $sp->databits(8);
    $sp->stopbits(1);

    $sp->read_char_time(0);     # don't wait for each character
    $sp->read_const_time(1000); # 1 second per unfulfilled "read" call

    print STDERR "Reading in chunks of $read_bytes bytes\n"
	if $verbose;

    # Cause fatal error if accessing and undefined header value
    if ($debug) {
	lock_hash(%time_divs);
	lock_hash(%volt_divs);
    }

    my %self = (serial_port  => $sp,
		port         => $port,
		read_bytes   => $read_bytes,
		verbose      => defined $verbose ? $verbose : 0,
		debug        => defined $debug   ? $debug   : 0,

		# Data read from serial port
		read_data        => undef, # last data read from serial port.
		read_total_bytes => undef, # length of requested serial port data.
		read_count       => 0,     # count of serial port readings.
		read_buffer      => undef, # buffer of serial port data, holding candidate packets.

		# Packet info.
		packet_count   => 0,
		current_packet => undef,
		first_ba_seen  => 0,

		# Opened file handle of the file to dump raw serial port reads.
		# A defined value indicates that a dump should happen.
		raw_out_fh     => undef);

    bless \%self, $class;

    # Catch any invalid hash key usage.
    lock_keys(%self);

    return \%self;
}


################################################################################
# Object Methods

# Read n number of of bytes from the serial port using Device::SerialPort->read into the buffer.
sub read {
    my $self = shift;

    my $verbose = $self->{verbose};
    my $read_bytes = $self->{read_bytes};

    my ($read_length, $read_data) = ($self->{serial_port}->read($read_bytes));

    # Total read count and bytes.
    $self->{read_count}++;
    $self->{read_total_bytes}+= length($read_data);

    if ($verbose) {
	print STDERR "Serial port reading $self->{read_count} ... ";
	print STDERR "reported length: $read_length, string length: " . length($read_data) . "\n";

	if ($read_length == 0) {
	    print STDERR "Serial port read: no data.\n";
	} elsif ($read_length < $read_bytes) {
	    print STDERR "Serial port read: under read $read_length/$read_bytes.\n";
	}
    }

    if (my $raw_fh = $self->{raw_out_fh}) {
	print $raw_fh $read_data;
    }

    # Append to read buffer. This buffer will be truncated from the
    # start by get_next_packet() as it extracts any packets it finds.
    $self->{read_data}   = $read_data; # Last read serial data.
    $self->{read_buffer}.= $read_data;

    return ($read_length, $read_data)
	if defined wantarray;

    return;
}

# To be called after a read() from the serial port.
# Get the next BA packet that's available based on the read serial port data.
# The caller should call get_next_packet() in a loop until all packets
# have been processed and fetch more data using read() in the outer loop.
# Returns undef if there was not enough data to process.
# TODO: Use of $read_buffer may be unnecessary and could be an opportunity to introduce bugs.
sub get_next_packet {
    my $self = shift;

    my $verbose = $self->{verbose};
    my $debug   = $self->{debug};

    my $read_buffer = $self->{read_buffer};

    # Get the index of the first BA delimiter.
    my $ba_index_0 = index($read_buffer, BA_DELIM);
    my $ba_index_1;

    # Get indexes of other delimiters.
    my $br_index = index($read_buffer, BR_DELIM);
    my $bs_index = index($read_buffer, BS_DELIM);

    # Make this verbose?
    if ($verbose and $ba_index_0 == -1) {
	print "No BA delim found in buffer of size: " . length($read_buffer) . ".\n";
    }

    return
	if $ba_index_0 == -1;

    if ($ba_index_0 >= 0) {
	print STDERR "Found start of BA packet in buffer.\n"
	    if $debug;

	# If no BA has been seen before this instance of get_next_packet() call, then strip off bytes
	# leading up to the first BA delim.
	# It's not clear if the leading data is a complete BA packet or not.
	# It needs to be stripped off, leaving the buffer to start with the BA delim.
	if (not $self->{first_ba_seen}) {
	    substr($self->{read_buffer}, 0, $ba_index_0, '');
	    $self->{first_ba_seen} = 1;

	    if ($verbose) {
		print STDERR "Truncating leading data before first BA delimiter.\n";
		print STDERR "Read buffer was: $read_buffer\n";
		print STDERR "Now            : $self->{read_buffer}\n";
	    }

	    # Reset buffer var and first index.
	    $read_buffer = $self->{read_buffer};
	    $ba_index_0  = index($read_buffer, BA_DELIM);
	}

	# Find second BA delim, if it exists.
	# This would indicate that a complete BA packet exists in the buffer.
	$ba_index_1 = index($read_buffer, BA_DELIM, ($ba_index_0 + 1));

	if (not $ba_index_1 > 0) {
	    return;
	}
    } elsif ($br_index >= 0) {
	if ($debug) {
	    print "Found BR packet: $read_buffer\n";
	    print "-> " . sprintf("%vd", $read_buffer) . "\n";
	}
    } elsif ($bs_index >= 0) {
	# Have not seen a BS packet so far during development.
	if ($debug) {
	    print "Found BS packet: $read_buffer\n";
	}
    }

    # Fetch the packet string and truncate at the same time.
    print STDERR "BA found packet in buffer at byte positions $ba_index_0 and $ba_index_1\n"
	if $verbose;

    my $length = $ba_index_1 - $ba_index_0;
    my $p_data = substr($self->{read_buffer}, $ba_index_0, $length, '');

    # Truncate any leading unused data to avoid bloat of the buffer.
    substr($self->{read_buffer}, 0, $ba_index_0, '');

    my $packet = $self->parse_packet($p_data);

    $self->{packet_count}++;

    # Return on the first packet from the parts.
    return $packet;
}

# Parse and process a packet string.
# Must be a complete paket with header bytes but the delimiter may be optional.
sub parse_packet {
    my $self = shift;

    my $packet = shift;

    my $verbose = $self->{verbose};
    my $debug   = $self->{debug};

    my $raw_packet = $packet;

    # Strip and fetch any packet type delimiters.
    my $ba_str = BA_DELIM;
    my $br_str = BR_DELIM;
    my $bs_str = BS_DELIM;

    # Strip the packet delimiters.
    $packet =~ s/^($ba_str|$br_str|$bs_str)(.*)/$2/;
    my $packet_type = _identify_packet_type($1);

    print "Parsed Packet Type: $packet_type\n"
	if $verbose;

    # For now, strip off any non-BA packets that may have snuck in.
    my @non_ba_str = $packet =~ s/($br_str|$bs_str).*$//;

    # Split into individual bytes.
    # Note: Would it be faster to sprintf() first and then split?
    my @bytes  = split('', $packet);

    # Fetch the data section, leaving the headers in @bytes.
    my @trace = map { sprintf("%vd", $_) } splice(@bytes, 6);

    # Time.
    # Fix x-axis to 256 samples per screen, as described in the serial port protocol.
    # This will keep the trace display consistent and not vary based on length of @trace.
    my @time = (0 .. 255);

    # Convert the header bytes into decimals.
    my @header = map { sprintf("%vd", $_) } @bytes;

    my $volts_key = $header[1];

    my $volts_acdc;
    if ($volts_key >= 0 and $volts_key <= 11 or $volts_key >= 16 and $volts_key <= 27 ) {
	$volts_acdc = 'ac';
    } elsif ($volts_key >= 32 and $volts_key <= 43 or $volts_key >= 48 and $volts_key <= 59 ) {
	$volts_acdc = 'dc';
    }

    my $volts_10x;
    if ($volts_key >= 16 and $volts_key <= 27 or $volts_key >= 48 and $volts_key <= 59) {
	$volts_10x = 1;
    } elsif ($volts_key >= 32 and $volts_key <= 43 or $volts_key >= 0 and $volts_key <= 11 ) {
	$volts_10x = 0;
    }

    # Expect the possibility of an unknown header value for divisions.
    my $time_per_div   = $time_divs{$header[0]};
    my $time_per_point = $time_per_div ? ($time_per_div / POINTS_PER_TIME_DIV) : 0;

    my $volts_per_div   = $volt_divs{$volts_key};
    my $volts_per_point = $volts_per_div ? ($volts_per_div / POINTS_PER_VOLT_DIV) : 0;

    if ($debug) {
	print STDERR "Found unknown time/div value: " . $header[0] . "\n"
	    if not $time_per_div;

	print STDERR "Found unknown volt/div value: " . $volts_key . "\n"
	    if not $volts_per_div;
    }

    # Complete packet data structure.
    my %packet = ( packet_type      => $packet_type,
		   raw_packet       => $raw_packet,
		   processed_packet => $packet,
		   header           => \@header,
		   time_per_div     => $time_per_div,
		   time_per_point   => $time_per_point,
		   volts_per_div    => $volts_per_div,
		   volts_per_point  => $volts_per_point,
		   volts_acdc       => $volts_acdc,
		   volts_10x        => $volts_10x,
		   trace            => \@trace,
	           time             => \@time,
		   x_max            => undef, # The width of the x-axis.
		   y_max            => undef, # The height of the y-axis above and below the 0V baseline.
		   trace_scaled     => undef,
		   time_scaled      => undef,);

    # Scale the trace data.
    _format_trace(\%packet, 0);

    # Note: Should the last processed packet persist when there should not be any current packet?
    $self->{current_packet} = \%packet;

    return \%packet;
}

# Start saving the raw data read from the serial port to specified file.
# Data will start being saved in the next call to read().
sub save_raw_data_to_file {
    my $self = shift;

    my $filename = shift;
    my $unbuffer = shift;

    # Don't clobber an existing file handle.
    if (defined $self->{raw_out_fh}) {
	print STDERR "Open file handle exists for writing raw data. Skipping.\n"
	    if $self->{verbose};

	return 0;
    }

    # Open or die.
    open(my $out_fh, '>', $filename) or
	die "Could not write to '$filename': $!\n";

    # Unbuffer this file handle if explicitly requested.
    # Unbuffering the handle results in disk activity for each read from serial port.
    if ($unbuffer) {
	my $old_fh = select($out_fh); $| = 1; select($old_fh);
    }

    $self->{raw_out_fh} = $out_fh;

    return 1;
}

# Close the raw dump file handle.
sub close_raw_data_file {
    my $self = shift;

    if (defined $self->{raw_out_fh}) {
	print "closing\n";
	close($self->{raw_out_fh});
	$self->{raw_out_fh} = undef;
    }

    return;
}

sub DESTROY {
    my $self = shift;

    print STDERR "DESTROY() called\n"
	if $self->{debug};

    # Close any dump files that may be open.
    $self->close_raw_data_file;

    return;
}
1;

__END__

=head1 NAME

Device::Velleman::PPS10 - Read data from Velleman PPS10 oscilloscope

=head1 SYNOPSIS

    use Device::Velleman::PPS10;
    my $pps10 = Device::Velleman::PPS10->new;

    while (1) {
        # Read data from serial port and append to buffer in $pps10 object.
        $pps10->read;

        # Get 0 or more packets that may exist in buffer.
        while (my $packet = $pps10->get_next_packet) {
            # Do stuff with packet of a single frame of the signal trace.
        }
    }

=head1 DESCRIPTION

The Velleman PPS10 oscilloscope sends each frame of the signal
displayed on its LCD screen as a series of packets over the serial
port. Each packet contains 256 voltage samples, which if traced
graphically, replicates the signal the LCD screen. The data in the
packet is more detailed than can be drawn on the 128x64 LCD screen.

Device::Velleman::PPS10 allows for reading of the raw data from the
serial port and parses for packets containing the frames. Currently,
the module only uses the packet type (BA) containing a complete frame
of a signal trace. The scope sends two other packet types (BR and BS),
which contain 1 or just a few samples.

This module relies on Device::SerialPort. The user may need to handle
permission issues when reading from the serial port device on their
system.

This module has not been tested on a Win32 system.

=head2 The Raw Data

The data sent by the oscilloscope over the serial device is
binary. There are three packet types and each begins with a delimiter
of 2 to 4 byte values. The delimiter is then followed by 6 header
values containing oscilloscope settings such as volts/division. This
version of the module only processes the BA type packets. These
packets contain 256 sample values following the headers. One byte per
sample.

=head2 Parsed Packet Data Structure

The final product of parsing the raw data from the serial device is a
hash containing the unscaled and scaled voltage samples, and
oscilloscope setting values contained in each packet. The unscaled
sample values of the signal are scaled to actual voltage values given
the display settings reported in the packet.

    $packet = {
        packet_type      => 'BA' | 'BR' | 'BS',
        raw_packet       => <binary data>, # packet data from serial port to be parsed
        processed_packet => $packet,       # actual raw packet that was parsed
        header           => [ ... ],       # array of header values in decimal
        time_per_div     => '0.002',       # time between division marks on screen
        time_per_point   => '0.0002',      # time between each sample point
        volts_per_div    => '0.01',        # volts between division marks on screen
        volts_per_point  => '0.0003125',   # volts between each sample point
        volts_acdc       => 'ac' | 'dc',
        volts_10x        => 0 | 1,
        time             => [ ... ],       # sample counts 0 .. 255
        trace            => [ ... ],       # the sample values in decimal
        x_max            => 0.0512',       # end of x-axis in seconds from 0
        y_max            => 0.04',         # height of y-axis in volts above the 0V baseline
        time_scaled      => [ ... ],       # x-axis values in seconds
        trace_scaled     => [ ... ],       # y-axis values in volts
    };

The C<time> values are simply integers 0 to 255 and represent the 256
samples. They are scaled to units of C<seconds> using
C<time_per_point> and stored in C<time_scaled>. The C<trace> values
are scaled using C<volts_per_point> and stored in C<trace_scaled>. The
original C<trace> values are 8-bit samples (0 .. 255) where 127 is the
0V baseline. Plotting C<time_scaled> values on the x-axis and
C<trace_scaled> on the y-axis will give a nice graph of the frame.

=head1 METHODS

There are no exportable functions or symbols.

The following methods are provided.

=over 4

=item $pps10 = Device::Velleman::PPS10->new;

Create a new object to read from a single serial port. All parameters
to the constructor are optional.

    port        Serial port to read from. Default: '/dev/ttyS0'.
    read_bytes  Number of bytes to read from port. Default: 255.
    verbose     Report actions being taken to STDERR. 0|1. Default: 0.
    debug       Enable dev actions. 0|1. Default: 0.

The returned object is a hash-ref with the following structure:

    $self = {
        serial_port  => $serial_port, # Device::SerialPort object
        port         => '/dev/ttyS0',
	read_bytes   => 255,
	verbose      => 0|1,
	debug        => 0|1,

	read_data        => <last data read from serial port>,
	read_total_bytes => <int>,    # Total bytes read from serial port over life of object
	read_count       => <int>,    # count of serial port readings
	read_buffer      => <buffer of serial port data, holding candidate packets>

        packet_count   => <int>,      # number of parsed packets over the life of the object
        current_packet => { ... },    # hash ref of last parsed packet
        first_ba_seen  => 0,

	raw_out_fh     => undef|<filehandle>, # file handle of the raw data file
    };

=item $pps10->read;

=item $pps10->read(<read byte length>);

=item ($length_read, $data_read) = $pps10->read;

Read data from serial port and append to the rasw data buffer in the
object. Returns the length of the read request and the string read in
array context. These are the same values returned by the read() method
of a Device::SerialPort object.

The length of the data to be read is defined by read_bytes value
passed to the constructor. Optional parameter to ->read() overrides
the default read length, for that call of the method. This should not
be necessary since the default value of 255 works well.

=item $pps10->get_next_packet;

Fetches first packet of data from the raw data buffer, parses and
scales it. Returns undef if no complete packet is found in the
buffer. This method should be called repeatedly between each ->read(),
until no packets are returned. See L</"Parsed Packet Data Structure">.

=item $pps10->save_raw_data_to_file('/file/path', [0|1]);

Start saving the raw data read from the serial port to specified
file. Data is written to file with each ->read() after this method is
called. This will essentially save the binary stream from the serial
port to a file. Only one file is opened. If a file is already open for
saving, additional calls to this method are ignored.

If the second parameter is true, the filehandle is unbuffered. This
allows the data to be immediately written to disk after each serial
port read. The filehandle is buffered by default.

Returns 0 if a file is currently open, 1 on success and die()s if
there is an error open()ing the file.

=item $pps10->close_raw_data_file;

Stop saving raw data by closing the data dump file. Does nothing if no
file is open. No return value.

=back

=head1 Misc Notes

BR type packets appear in the stream at 20ms/div and longer. The
parsed packets may not be useful at intervals greater than 20ms/div.

=head1 Bugs

Death, taxes and software bugs. This is the first release of this
module.

=head1 SEE ALSO

=head2 Device::SerialPort

Can't read without it.

=head2 http://forum.velleman.eu/

The forum for questions related to Velleman products. The protocol
used to send the packets over the serial device are discussed on that
site. Searching for "pps10 serial port" or "serial port protocol"
should return relevant threads.

=head1 AUTHOR

Narbey Derbekyan

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Narbey Derbekyan

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
