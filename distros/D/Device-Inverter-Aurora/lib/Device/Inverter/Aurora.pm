package Device::Inverter::Aurora;

use 5.008008;
use strict;
use warnings;
use Carp qw/croak carp confess/;

require Exporter;

our @ISA = qw(Exporter);
our $TEST = 0;

my $onWindows = $^O eq "MSWin32" || $^O eq "cygwin";
if ($onWindows) {
	require Win32::SerialPort;
}
else {
	require Device::SerialPort;
}

use Device::Inverter::Aurora::Constants;
use Device::Inverter::Aurora::Strings;

our %EXPORT_TAGS = (
	CumulatedPeriod => [map {s/^.+:://; $_} grep {/Device::Inverter::Aurora::CUMULATED_/} keys %constant::declared],
	DSP             => [map {s/^.+:://; $_} grep {/Device::Inverter::Aurora::DSP_/} keys %constant::declared],
	Counters        => [map {s/^.+:://; $_} grep {/Device::Inverter::Aurora::COUNTER_/} keys %constant::declared],
	Operations      => [map {s/^.+:://; $_} grep {/Device::Inverter::Aurora::OP_/} keys %constant::declared],
);

# Combine all the tags to an :all tag
{my %s; push @{$EXPORT_TAGS{all}}, grep {!$s{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;}

our @EXPORT_OK = ( @{ $EXPORT_TAGS{all} } );

our @EXPORT = qw( );

our $VERSION = '0.05';

sub _error {
	my $self = shift;
	my $error = shift;

	$self->{error} = $error;
	carp $error unless $self->{quiet};
	return 1;
}

sub lastError {
	my $self = shift;
	my $error = $self->{error};
	$self->{error} = undef;
	return $error;
}

sub new {
	my $caller = shift;
	my $caller_is_ref = ref $caller;
	my $class = $caller_is_ref || $caller;

	my %args = ref $_ eq 'HASH' ? %{shift @_} : @_;

	# Extract some configuration from the given arguments
	my $debug    = $args{debug}   || 0;
	my $retries  = $args{retries} || 0;
	my $backoff  = $args{backoff} || 1;
	my $address  = $args{address} || 2;
	my $port_str = $args{port}    || '/dev/ttyS0';
	my $raw      = $args{raw}     || 0;
	my $quiet    = $args{quiet}   || 0;

	# Configure the serial port
	my $port = ($TEST
		? new Test::Device::SerialPort($port_str, debug => $debug)
		: ($onWindows
			? new Win32::SerialPort($port_str, debug => $debug)
			: new Device::SerialPort($port_str, debug => $debug)
		)
	) or croak "Can't open $port_str: $^E";

	# Again, mostly from the arguments provided
	$port->baudrate($args{baudrate} || 19200);
	$port->parity($args{parity} || 'none');
	$port->databits($args{databits} || 8);
	$port->stopbits($args{stopbits} || 1);
	$port->datatype($args{datatype} || 'raw');
	$port->handshake($args{handshake} || 'none');
	$port->read_const_time($args{read_const_time} || 150);

	$port->write_settings or warn "Unable to write settings to $port_str";

	# Does this even work?
	$port->purge_all;

	my $self = bless {
		port_str         => $port_str,
		debug            => $debug,
		quiet            => $quiet,
		retries          => $retries,
		backoff          => $backoff,
		port             => $port,
		address          => $address,
		error            => undef,
	}, $class;

	return $self;
}

sub raw {
	my ($self, $raw) = @_;
	$self->{raw} = $raw if defined $raw;
	return $self->{raw};
}

sub communicate {
	my ($self, $address, $command, @args) = @_;
	$address = $self->{address} unless defined $address;

	# Build a 8 byte space padded buffer based on address, command, and given arguments
	my @buffer = ($address, $command);
	push @buffer, map {defined $args[$_] ? $args[$_] : 32} 0..5;

	# Pack that buffer into a binary string, append CRC to it
	my $str = pack 'C8', @buffer;
	$str .= pack 'v', crc($str);

	# Try as many times as permitted to send to the inverter and get a reply
	my $try = -1;
	while ($try++ < $self->{retries}) {
		$self->{port}->purge_all;

		# Give the coms a break for a $backoff period
		sleep $self->{backoff} if $try > 1 && $self->{backoff};

		# Transmit data, make sure 10 bytes are sent
		warn "Sending " , hexstr($str) , "\n" if $self->{debug};
		my $sent = $self->{port}->write($str);
		$self->_error("Failed to write all bytes") and next unless defined $sent and $sent == 10;

		# Receive data, make sure that 8 bytes are read
		my $read = $self->{port}->read(8);
		warn "Received " , hexstr($read) , "\n" if $self->{debug};
		$self->_error("Failed to read in all bytes") and next unless defined $read and length $read == 8;

		# First 6 bytes of the reply are unsigned characters of data, the last 2 are a short CRC
		my @reply = unpack 'C6v', $read;
		my $reply_crc = pop @reply;

		# Verify the CRC matches
		$self->_error("CRC failure") and next unless crc(substr($read,0,6)) == $reply_crc;

		return wantarray ? @reply : \@reply;
	}

	confess "Read failure, $try attempts made.";
}

sub translate {
	my ($input, $matrix) = @_;

	# Given a hash and a valid $input, return the translation
	if (ref $matrix eq 'HASH' && defined $matrix->{$input}) {
		return $matrix->{$input}
	}
	# Given an array and a valid $input, return the translation
	elsif (ref $matrix eq 'ARRAY' && defined $matrix->[$input]) {
		return $matrix->[$input];
	}

	# Input was invalid or otherwise unknown
	return 'unknown';
}

sub transmissionCheck {
	my ($self, $input) = @_;

	# Get a translation for debugging
	my $translation = translate($input, \@TransmissionStates);
	warn "Transmission state check: $translation ($input)\n" if $self->{debug};

	# All is good in the world
	return 1 if $input == 0;

	# All is not so good, complain and return false
	$self->_error("Transmission State: $translation ($input)");
	return 0;
}

sub crc {
	my $str = shift;
	my $crc = 0xffff;
	foreach my $chr (unpack 'C*', $str) {
		for (my $i = 0, my $data =int 0xff & $chr; $i < 8; $i++, $data >>= 1) {
			$crc = ($crc & 0x0001) ^ ($data & 0x0001) ? ($crc >> 1) ^ 0x8408 : $crc >> 1;
		}
	}
	return 0xffff & ~$crc;
}

sub hexstr {
	my $str = shift;
	return join(' ', unpack('H2'x(length $str), $str));
}


sub commCheck {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_VERSION, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		my $translation = translate(chr($reply[2]), \%ProductNames);
		warn "Product name: $translation\n" if $self->{debug};
		return 1;
	}
	return 0;
}

sub getState {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_STATE, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		my %result = (
			globalState       => [$reply[1], translate($reply[1], \@GlobalStates)],
			inverterState     => [$reply[2], translate($reply[2], \@InverterStates)],
			channel1DCDCState => [$reply[3], translate($reply[3], \@DCDCStates)],
			channel2DCDCState => [$reply[4], translate($reply[4], \@DCDCStates)],
			alarmState        => [$reply[5], translate($reply[5], \@AlarmStates)],
		);
		return wantarray ? %result : \%result;
	}
	return wantarray ? () : undef;
}

sub getLastAlarms {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, 86, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		my @result = map {[$_, translate($_, \@AlarmStates)]} @reply[2,3,4,5];
		return wantarray ? @result : \@result;
	}
	return wantarray ? () : undef;
}

sub getPartNumber {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_PART_NUMBER, 0);
	# Simple 6 character string to return
	return pack('C*', @reply);
}

sub getSerialNumber {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_SERIAL_NUMBER, 0);
	# Simple 6 character string to return
	return pack('C*', @reply);
}

sub getVersion {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_VERSION, 0, 46);
	if (@reply && $self->transmissionCheck($reply[0])) {
		my %result = (
			model       => [$reply[2], translate(chr($reply[2]), \%ProductNames)],
			regulation  => [$reply[3], translate(chr($reply[3]), \%ProductSpec)],
			transformer => [$reply[4], $reply[4] == 84 ? 'transformer' : 'transformerless'],
			type        => [$reply[5], $reply[5] == 87 ? 'wind' : 'photovoltic'],
		);
		return wantarray ? %result : \%result;
	}
	return wantarray ? () : undef;
}

sub getManufactureDate {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_MANUFACTURING_DATE, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		# Two simple strings, month is first two bytes, year is last two.
		my %result = (
			year => pack('C*', @reply[4, 5]),
			month => pack('C*', @reply[2, 3]),
		);
		return wantarray ? %result : \%result;
	}
	return wantarray ? () : undef;
}

sub getFirmwareVersion {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_FIRMWARE_VERSION, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		# Dot delimited characters
		return join '.', map{chr} @reply[2, 3, 4, 5];
	}
	return undef;
}

sub getConfiguration {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_CONFIGURATION, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		my @result = ($reply[2],translate($reply[2], \@ConfigurationStrings));
		return wantarray ? @result : \@result;
	}
	return wantarray ? () : undef;
}

sub getCumulatedEnergy {
	my ($self, $period, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_CUMULATED_ENERGY, $period, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		# Data returned is a long expressing watts, pack the 4 bytes
		my $packed = pack 'C*', @reply[2, 3, 4, 5];
		# Return raw, or a long.
		return $self->{raw} ? $packed : unpack 'N', $packed;
	}
	return undef;
}

sub getDailyEnergy   {shift->getCumulatedEnergy(CUMULATED_DAILY, shift);}
sub getWeeklyEnergy  {shift->getCumulatedEnergy(CUMULATED_WEEKLY, shift);}
sub getMonthlyEnergy {shift->getCumulatedEnergy(CUMULATED_MONTHLY, shift);}
sub getYearlyEnergy  {shift->getCumulatedEnergy(CUMULATED_YEARLY, shift);}
sub getTotalEnergy   {shift->getCumulatedEnergy(CUMULATED_TOTAL, shift);}
sub getPartialEnergy {shift->getCumulatedEnergy(CUMULATED_PARTIAL, shift);}

sub getDSPData {
	my ($self, $parameter, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_DSP, $parameter, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		# Data returned is a single precision float, pack the 4 bytes
		my $packed = pack 'C*', @reply[5, 4, 3, 2];
		# Return raw or float.
		return $self->{raw} ? $packed : unpack 'f', $packed;
	}
	return undef;
}

sub getFrequency           {shift->getDSPData(DSP_FREQUENCY, shift);}
sub getGridVoltage         {shift->getDSPData(DSP_GRID_VOLTAGE, shift);}
sub getGridCurrent         {shift->getDSPData(DSP_GRID_CURRENT, shift);}
sub getGridPower           {shift->getDSPData(DSP_GRID_POWER, shift);}
sub getInput1Voltage       {shift->getDSPData(DSP_INPUT_1_VOLTAGE, shift);}
sub getInput1Current       {shift->getDSPData(DSP_INPUT_1_CURRENT, shift);}
sub getInput2Voltage       {shift->getDSPData(DSP_INPUT_2_VOLTAGE, shift);}
sub getInput2Current       {shift->getDSPData(DSP_INPUT_2_CURRENT, shift);}
sub getInverterTemperature {shift->getDSPData(DSP_INVERTER_TEMPERATURE, shift);}
sub getBoosterTemperature  {shift->getDSPData(DSP_BOOSTER_TEMPERATURE, shift);}

sub getJoules {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_LAST_10_SEC_ENERGY, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		# Data returned is a short, only pack the first two bytes
		my $packed = pack 'C*', @reply[2, 3];
		# Return raw or short.
		return $self->{raw} ? $packed : (unpack 'n', $packed) * 0.319509;
	}
	return undef
}

sub getTime {
	my ($self, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_TIME, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		# Data returned is a long, pack the 4 bytes
		my $packed =  pack 'C*', @reply[2, 3, 4, 5];
		# Return as raw or as long offset for unix epoch (Inverter epoch is 946706400 later than unix)
		return $self->{raw} ? $packed : (unpack 'N', $packed) + 946706400;
	}
	return undef;
}

sub setTime {
	my ($self, $time, $address) = @_;

	# Convert from unix epoch to inverter epoch
	$time -= 946706400;

	# Pack the long and unpack into a 4 character array
	my @args = unpack 'C*', pack 'N', $time;
	my @reply = $self->communicate($address, OP_SET_TIME, @args, 0);
	if (@reply && $self->transmissionCheck($reply[0])) {
		return 1;
	}
	return undef;
}

sub getCounterData {
	my ($self, $counter, $address) = @_;

	my @reply = $self->communicate($address, OP_GET_COUNTERS, $counter);
	if (@reply && $self->transmissionCheck($reply[0])) {
		#Data returned is a long, pack the 4 bytes
		my $packed = pack 'C*', @reply[2, 3, 4, 5];
		# Return raw or long
		return $self->{raw} ? $packed : unpack 'N', $packed;
	}
	return undef;
}

sub getTotalRunTime {shift->getCounterData(COUNTER_TOTAL, shift);}
sub getPartialRunTime {shift->getTCounterData(COUNTER_PARTIAL, shift);}
sub getGridRunTime {shift->getCounterData(COUNTER_GRID, shift);}
sub getResetRunTime {shift->getCounterData(COUNTER_RESET, shift);}

1;
__END__

=head1 NAME

Device::Inverter::Aurora - Module for communicating with Power-One Aurora inverters.

=head1 SYNOPSIS

  use Device::Inverter::Aurora;
  my $dev = new Device::Inverter::Aurora(port => '/dev/ttyUSB0');
  if ($dev->commCheck()) {
    my %version = $dev->$dev->getVersion();
    print $version{model};
  }

=head1 DESCRIPTION

Perl module for communicating with Power-One Aurora inverters.

Based on Curt Blank's Aurora program (http://www.curtronics.com/Solar/AuroraData.html)
which is in turn based on Power One's 'Aurora Inverter Series - Communication Protocol -'
document, Rel. 4.6 25/02/09.

Having not so far been able to obtain a copy of this document from Power One I've had to
make some educated guesses as to some things, but for the most part this library should
be functional to the point the original Aurora program is.

=head1 METHODS

=head2 new(I<%args>)

Constructor for the module, accepts the following paramaters with defaults listed.

=over 4

=item debug => bool (0)

Set to 1 to output more data from this module.

=item retries => int (0)

How many times to attempt to communicate with the inverter before giving up.

=item address => int (2)

The default inverter address to use (passing an address to the functions is optional).

=item port => string ('/dev/ttyS0')

The path to the serial device/port that the inverter is connected to.

=item raw => bool (0)

Set this to true if you want to get raw binary data from some functions (useful for compact binary logging)

=item baudrate => int (19200)

Passed directly to L<Device::SerialPort|Device::SerialPort> (or L<Win32::SerialPort|Win32::SerialPort> for windows users)

=item parity => string ('none')

Passed directly to L<Device::SerialPort|Device::SerialPort> (or L<Win32::SerialPort|Win32::SerialPort> for windows users)

=item databits => int (8)

Passed directly to L<Device::SerialPort|Device::SerialPort> (or L<Win32::SerialPort|Win32::SerialPort> for windows users)

=item stopbits => int (1)

Passed directly to L<Device::SerialPort|Device::SerialPort> (or L<Win32::SerialPort|Win32::SerialPort> for windows users)

=item datatype => string ('raw')

Passed directly to L<Device::SerialPort|Device::SerialPort> (or L<Win32::SerialPort|Win32::SerialPort> for windows users)

=item handshake => string ('none')

Passed directly to L<Device::SerialPort|Device::SerialPort> (or L<Win32::SerialPort|Win32::SerialPort> for windows users)

=item read_const_time => int (150)

Passed directly to L<Device::SerialPort|Device::SerialPort> (or L<Win32::SerialPort|Win32::SerialPort> for windows users)

=back

=head2 raw([I<raw>])

Setter getter for raw provided to constructor

=head2 communicate(I<address>, I<command>[, I<arg> [, I<arg>[, I<arg> [, I<arg>[, I<arg> [, I<arg>]]]]]] )

This method isn't really intended to be used directly but is provided all the same.

Send a command to the given inverter address, in this instance address must be provided, or set to undef.
The last used argument must be followed by a 0 argument.

  $obj->communicate(2, OP_GET_SOMETHING, 2, 4, 0);
  $obj->communicate(undef, OP_GET_SOMETHING, 0);

Please be sure to include a 0 param as the last argument.

There is only one exception I know of to the 0 as last argument rule, that's OP_GET_VERSION.

=head2 translate(I<value>, I<ref>)

Check the given array or hashref for the given value, if no match found, returns "unknown"

=head2 transmissionCheck(I<status>)

Used internally to check the transmission check byte (byte 0 from most replies) to make sure all is well.

You can use this function if you've been calling communicate directly but I suggest checking the source to work
out which op codes do and don't return a transmission check byte.

=head2 commCheck([I<address>])

Check that the we can talk to the inverter, and it's inclined to reply.

=head2 getState([I<address>])

Get the current state of the inverter, returns a hash.

  (
    feature => [raw integer value, 'string translation'],
    etc...
  )

Features are I<globalState>, I<inverterState>, I<channel1DCDCState>, I<channel2DCDCState>, and I<alarmState>

=head2 getLastAlarms([I<address>])

Get the lsat 4 alarms from the inverter, returns an array

  (
    [raw integer value, 'string translation'],
    etc...
  )

=head2 getPartNumber([I<address>])

Gets the part number from the inverter and returns it as a string.

=head2 getSerialNumber([I<address>])

Gets the serial number from the inverter and returns it as a string.

=head2 getVersion([I<address>])

Get the model of inverter, the spec it complies with, what type the inverter is (wind or photovoltic) and whether it is transformerless or not.

  (
    field => [raw integer value, 'string translation'],
    etc...
  )

Fields are I<model>, I<regulation>, I<transformer>, and I<type>

=head2 getManufactureDate([I<address>])

Gets and returns the (2 digit) year and month of manufacture as a hash.

=head2 getFirmwareVersion([I<address>])

Gets and returns the firmware version of the inverter as a string formatted 'a.b.c.d'

=head2 getConfiguration([I<address>])

Get the string configuration from the inverter, returns an array containing the raw value from the inverter and the string translation

  (raw integer value, 'string translation')

=head2 getCumulatedEnergy(I<period>[, I<address>])

Get the value (watts) from one of the energy cumulaters being daily, weekly, monthly, yearly, total, partial.

While you can call this method directly, and the constants for these cumulaters can be imported with the :CumulatedPeriod tag, you should probably just use the shortcuts below.

If the 'raw' is true then this function will return a 4 byte big-endian unsigned long as a binary string.

=head2 getDailyEnergy([I<address>])

Shortcut for getCumulatedEnergy to get the daily value

=head2 getWeeklyEnergy([I<address>])

Shortcut for getCumulatedEnergy to get the weekly value

=head2 getMonthlyEnergy([I<address>])

Shortcut for getCumulatedEnergy to get the monthly value

=head2 getYearlyEnergy([I<address>])

Shortcut for getCumulatedEnergy to get the yearly value

=head2 getTotalEnergy([I<address>])

Shortcut for getCumulatedEnergy to get the total value (like forever man)

=head2 getPartialEnergy([I<address>])

Shortcut for getCumulatedEnergy to get the partial value (since last reset)

=head2 getDSPData(I<parameter>[, I<address>])

Get one of the DSP parameters returned as a float. or in raw mode a 4 byte binary string representing a flot in 'native' format.

There are many DSP parameters available (see Device::Inverter::Aurora::Constants for a full list) which have defined constants importable with the :DSP tag.

The most basic and common DSP parameters have shortcut methods already as part of this module listed below.

=head2 getFrequency([I<address>])

Shortcut to get and return the frequency detected on the grid (I think).

=head2 getGridVoltage([I<address>])

Shortcut to get and return the voltage being pushed to the grid.

=head2 getGridCurrent([I<address>])

Shortcut to get and return the amount of current (in amps) being pushed to the grid.

=head2 getGridPower([I<address>])

Shortcut to get and return the amount of power (in watts) being pushed to the grid.

=head2 getInput1Voltage([I<address>])

Shortcut to get and return the voltage received on input 1 from your solar array/wind turbine

=head2 getInput1Current([I<address>])

Shortcut to get and return the amount of current (in amps) being received from input 1

=head2 getInput2Voltage([I<address>])

Shortcut to get and return the voltage received on input 2 from your solar array/wind turbine

=head2 getInput2Current([I<address>])

Shortcut to get and return the amount of current (in amps) being received from input 2

=head2 getInverterTemperature([I<address>])

Shortcut to get and return the current temperature of the inverter in celsius.

=head2 getBoosterTemperature([I<address>])

Shortcut to get and return the current temperature of the booster in celsius.

=head2 getJoules([I<address>])

The amount of power produced in the last 10 seconds as Joules, in raw mode it returns a 2 byte big-endian binary short

=head2 getTime([I<address>])

Get the current timestamp from the inverter, returns as a unix epoch based timestamp unless in raw mode, then it
returns the 4 big-endian binary bytes containing the inverter time. This is not an unix timetamp rather it is a timestamp
from 946706400 seconds later than epoch.

ie:

  $obj->raw(1);
  $t = $obj->getTime();
  # $t is a binary timestamp that needs 946706400 seconds added to it

=head2 setTime(I<timestamp>[, I<address>])

Set the time in the inverter to the given timestamp.

B<Warning:> this may result in the resetting of partial counters/cumulaters.

=head2 getCounterData(I<counter>[, I<address>])

Get the value (seconds?) from one of the counters being total, partial, grid, and reset runtimes.

While you can call this method directly, and the constants for these counters can be imported with the :Counters tag, you should probably just use the shortcuts below.

If the 'raw' is true then this function will return a 4 byte big-endian unsigned long as a binary string.

=head2 getTotalRunTime([I<address>])

Get the total runtime for the inverter

=head2 getPartialRunTime([I<address>])

Get the partial runtime of the inverter... since when?

=head2 getGridRunTime([I<address>])

Get the amount of time the inverter has been on grid.

=head2 getResetRunTime([I<address>])

Get a timer sine reset? of what?

=head2 lastError()

Returns the last error/warning and clears the buffer

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<Device::SerialPort|Device::SerialPort>, L<Win32::SerialPort|Win32::SerialPort>, Original Aurora program (L<http://www.curtronics.com/Solar/AuroraData.html>)

=head1 AUTHOR

Shannon Wynter

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Shannon Wynter (L<http://fremnet.net/contact>)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
