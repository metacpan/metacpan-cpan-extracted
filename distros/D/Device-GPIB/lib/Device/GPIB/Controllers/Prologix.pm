# Prologix.pm
# Device::GPIB interface to Prologix GPIB-USB Controller
# https://prologix.biz/downloads/PrologixGpibUsbManual-4.2.pdf
# Author: Mike McCauley (mikem@airspayce.com),
#
# Works with:
# - Prologix USB-GPIB adapter
# - AR488 for Arduino from Twilight-Logic: https://github.com/Twilight-Logic/AR488
#   (tested with Arduino Nano and custom wiring interface)
#
# Default port params are OK for Prologix at 9600 baud
# For AR488 on Linux, need -port /dev/ttyUSB0:115200
#
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Controllers::Prologix;

use strict;
use Device::SerialPort;

$Device::GPIB::Controllers::Prologix::VERSION = '0.10';

sub new($$)
{
    my ($class, $port) = @_;

    my $self = {};
    bless $self, $class;

    # Defaults:
    $self->{Port} = '/dev/ttyUSB0';
    $self->{Baudrate} = '9600';
    $self->{Databits} = '8';
    $self->{Parity} = 'none';
    $self->{Stopbits} = '1';
    $self->{Handshake} = 'none';
    $self->{ReadCharTimeout} = 2000; # ms

    $self->{Port} = $port if defined $port;

    my ($portname, $baudrate, $databits, $parity, $stopbits, $handshake) 
	= split(/:/, $self->{Port});
    $self->{Baudrate}  = $baudrate  if defined $baudrate;
    $self->{Databits}  = $databits  if defined $databits;
    $self->{Parity}    = $parity    if defined $parity;
    $self->{Stopbits}  = $stopbits  if defined $stopbits;
    $self->{Handshake} = $handshake if defined $handshake;

    debug("$class is connecting to $portname with $self->{Baudrate}:$self->{Databits}:$self->{Parity}:$self->{Stopbits}:$self->{Handshake}");

    $self->{serialport} = Device::SerialPort->new($portname);
    if (!$self->{serialport})
    {
	warning("Could not open serial port $portname: $!");
	return;
    }
    $self->{serialport}->baudrate($self->{Baudrate});
    $self->{serialport}->databits($self->{Databits});
    $self->{serialport}->parity($self->{Parity});
    $self->{serialport}->stopbits($self->{Stopbits});
    $self->{serialport}->handshake($self->{Handshake});
    $self->{serialport}->read_char_time($self->{ReadCharTimeout});
    $self->{serialport}->read_const_time(100);
    $self->{serialport}->stty_icanon(0);

    $self->{CurrentPad} = -1;
    $self->{CurrentSad} = -1;

    return unless $self->initialised();

    return $self;
}

sub initialised($)
{
    my ($self) = @_;

    # Sigh, when AR488 is first connected, it reboots and takes a few
    # seconds until it will respond to version.
    # Prologix is immediate
    for (my $retries = 0; $retries < 5; $retries++)
    {
	$self->{DeviceVersion} = $self->version();
	debug("Controller version: $self->{DeviceVersion}");
	if (!defined $self->{DeviceVersion})
	{
	    sleep(1);
	    next;
	}
	
	return unless $self->{DeviceVersion} =~ /^Prologix/ || $self->{DeviceVersion} =~ /^AR488/;
	# Set the Prologix compatible into a state we like
	$self->auto(0);
	return unless $self->auto() == 0;
	return 1; # OK
    }
    debug("Gave up trying to read versionfrom the controller");
    return; # Fail
}


# Send an unescaped Prologix command, possibly containing ++
# and certainly not \n
sub sendControllerCommand($$)
{
    my ($self, $s) = @_;

    debug("Sending Controller Command: '$s'");
    if ($Device::GPIB::Controller::debug)
    {
	my $x = unpack('H*', $s);
	print "CONTROLLER COMMAND HEX: $x\n";
    }
    return $self->{serialport}->write($s . "\n"); # \n to trigger Prologix Controller execution
}

# Escapes Prologix special characters
sub send($$)
{
    my ($self, $s) = @_;

    debug("Sending GPIB Command: '$s'");
    # Escape $s, prepend any CR, LF, ESC or '+' with ESC
    $s =~ s/([\x0d\x0a\x1b\x2b])/\x1b$1/g;
    if ($Device::GPIB::Controller::debug)
    {
	my $x = unpack('H*', $s);
	print "GPIB COMMAND HEX: $x\n";
    }
    return $self->{serialport}->write($s . "\n"); # \n to trigger Prologix Controller transmission
}

# Escapes Prologix special characters
sub sendTo($$$$)
{
    my ($self, $s, $pad, $sad) = @_;
    
    $self->addr($pad, $sad) if defined $pad;
    return $self->send($s);
}

sub read_to_timeout($)
{
    my ($self) = @_;

    my $buf;
    while (1)
    {
	my ($count, $ch) = $self->{serialport}->read(1);
	my $x = unpack('H*', $ch);
	debug("got $count, $ch: $x");
	return $buf
	    unless $count;  # Timeout
	$buf .= $ch;
    }
}

sub read_to_eol($)
{
    my ($self) = @_;

    my $buf;
    while (1)
    {
	my ($count, $ch) = $self->{serialport}->read(1);
	if ($count)
	{
	    my $x = unpack('H*', $ch);
	    debug("got $count, $ch: $x");
	    if ($ch eq ';' && $self->{EOIMode}) # Experimental
	    {
		# Not EOI/LF mode, so this is the last char
		last;
	    }
	    elsif ($ch eq "\r")
	    {
		# ignore CR
	    }
	    elsif ($ch eq "\n")
	    {
		# NL, end of message (unless we are reading binary)
		last;
	    }
	    else
	    {
		$buf .= $ch;
	    }
	}
	else
	{
	    debug("read_to_eol Timeout");
	    last;
	}
    }

    # Got a buffer full
    debug("Read: '$buf'");
    return $buf;
}

# REad until a char or timeout.
# $waitfor can be either 'eoi' or the decimal number of the char < 256
sub read_until_timeout_or($$)
{
    my ($self, $waitfor) = @_;
    
    my $cmd = '++read';
    $cmd .= " $waitfor"
	if defined($waitfor);
    $self->sendControllerCommand($cmd);
    return $self->read_to_eol();
}

sub read($$$)
{
    my ($self, $pad, $sad) = @_;

    $self->addr($pad, $sad) if defined $pad;
    return $self->read_until_timeout_or('eoi'); # Only works if EOI is enabled
}

sub read_binary($$$)
{
    my ($self, $pad, $sad) = @_;

    $self->addr($pad, $sad) if defined $pad;
    $self->sendControllerCommand('++read eoi');   
    return $self->read_to_timeout();
}

sub warning($)
{
    my ($s) = @_;

    print "WARNING: $s\n";
}

sub debug($)
{
    my ($s) = @_;

    print "DEBUG: $s\n"
	if $Device::GPIB::Controller::debug;
}

sub close($)
{
    my ($self) = @_;

    if ($self->{serialport})
    {
	# Sigh: AR488 will fail to complete last command if we close too soon.
	sleep(1) if $self->{DeviceVersion} =~ /^AR488/;
	$self->{serialport}->close();
	undef $self->{serialport};
    }
}

sub DESTROY($)
{
    my ($self) = @_;

    $self->close();
}

###
### Implementations of low level Prologix commands
###

sub version($)
{
    my ($self) = @_;

    # Send the command
    $self->sendControllerCommand('++ver');
    # Read the result
    return $self->read_to_eol();
}

sub auto($$)
{
    my ($self, $value) = @_;
    
    if (defined($value))
    {
	$self->sendControllerCommand("++auto $value");
	return;
    }
    else
    {
	$self->sendControllerCommand("++auto");
	return $self->read_to_eol();
    }
}

sub addr($$$)
{
    my ($self, $pad, $sad) = @_;
    
    if (defined($pad))
    {
	if ($pad != $self->{CurrentPad})
	{
	    my $cmd = "++addr $pad";
	    $cmd .= " $sad"
		if defined $sad;
	    $self->sendControllerCommand($cmd);
	    # Sigh: AR488 can take some time to process this during scans
	    sleep(1) if $self->{DeviceVersion} =~ /^AR488/;
	    $self->{CurrentPad} = $pad;
	    $self->{CurrentSad} = $sad;
	    return;
	}
    }
    else
    {
	$self->sendControllerCommand('++addr');
	return $self->read_to_eol();
    }
}

sub clr($$$)
{
    my ($self, $pad, $sad) = @_;

    $self->addr($pad, $sad) if defined $pad;
    $self->sendControllerCommand('++clr');   
}

sub eoi($$)
{
    my ($self, $val) = @_;

    if (defined($val))
    {
	$self->sendControllerCommand('++eoi ' . ($val ? '1' : '0'));
	return;
    }
    else
    {
	$self->sendControllerCommand('++eoi');
	return $self->read_to_eol();
    }
}

sub eos($$)
{
    my ($self, $val) = @_;

    if (defined($val))
    {
	$self->sendControllerCommand("++eos $val");
	return;
    }
    else
    {
	$self->sendControllerCommand('++eos');
	return $self->read_to_eol();
    }
}

sub eot_enable($$)
{
    my ($self, $val) = @_;

    if (defined($val))
    {
	$self->sendControllerCommand('++eot_enable ' . ($val ? '1' : '0'));
	return;
    }
    else
    {
	$self->sendControllerCommand('++eot_enable');
	return $self->read_to_eol();
    }
}

sub eot_char($$)
{
    my ($self, $val) = @_;

    if (defined($val))
    {
	$self->sendControllerCommand('++eot_char ' . ord($val));
	return;
    }
    else
    {
	$self->sendControllerCommand('++eot_char');
	return $self->read_to_eol();
    }
}

sub ifc($)
{
    my ($self) = @_;

    $self->sendControllerCommand('++ifc');   
}

sub llo($$$)
{
    my ($self, $pad, $sad) = @_;

    $self->addr($pad, $sad) if defined $pad;
    $self->sendControllerCommand('++llo');   
}

sub loc($$$)
{
    my ($self, $pad, $sad) = @_;

    $self->addr($pad, $sad) if defined $pad;
    $self->sendControllerCommand('++loc');   
}

sub lon($$)
{
    my ($self, $val) = @_;

    if (defined($val))
    {
	$self->sendControllerCommand('++lon ' . ($val ? '1' : '0'));
	return;
    }
    else
    {
	$self->sendControllerCommand('++lon');
	return $self->read_to_eol();
    }
}

sub mode($$)
{
    my ($self, $val) = @_;

    if (defined($val))
    {
	$self->sendControllerCommand('++mode ' . ($val ? '1' : '0'));
	return;
    }
    else
    {
	$self->sendControllerCommand('++mode');
	return $self->read_to_eol();
    }
}

sub read_tmo_ms($$)
{
    my ($self, $val) = @_;

    $self->sendControllerCommand('++read_tmo_ms ' . int($val));
}

sub rst($)
{
    my ($self) = @_;

    # CAUTION: This can take 5 seconds to complete
    $self->sendControllerCommand('++rst');   
}

sub savecfg($$)
{
    my ($self, $val) = @_;

    if (defined($val))
    {
	$self->sendControllerCommand('++savecfg ' . ($val ? '1' : '0'));
	return;
    }
    else
    {
	$self->sendControllerCommand('++savecfg');
	return $self->read_to_eol();
    }
}

sub spoll($$$)
{
    my ($self, $pad, $sad) = @_;
    
    my $cmd = '++spoll';
    $cmd .= " $pad"
	if defined($pad);
    $cmd .= " $sad"
	if defined($sad);
    $self->sendControllerCommand($cmd);
}

sub srq($)
{
    my ($self) = @_;

    $self->sendControllerCommand('++srq');
    # Hmmm, on HP8904A, this will return the status byte!
    return $self->read_to_eol();
}

sub status($$)
{
    my ($self, $val) = @_;

    if (defined($val))
    {
	$self->sendControllerCommand('++status ' . $val);
	return;
    }
    else
    {
	$self->sendControllerCommand('++status');
	return $self->read_to_eol();
    }
}

sub trg($@)
{
    my ($self, @addrs) = @_;

    my $cmd = '++trg';
    while (@addrs)
    {
	$cmd .= ' ' . shift(@addrs);
    }
    $self->sendControllerCommand($cmd);
}

1;

__END__

=head1 NAME

Device::GPIB::Prologix - Interface to Prologix GPIB-USB Controller

=head1 SYNOPSIS

  use Device::GPIB::Prologix;
  my $d = Device::GPIB::Prologix->new('/dev/ttyUSB0');
  my $pad = 17;
  $d->sendTo('id?', $pad);
  my $id = $d->read();

=head1 DESCRIPTION

This module provides an OO interface to the Prologix GPIB-USB Controller
http://prologix.biz/downloads/PrologixGpibUsbManual-6.0.pdf

It allows you to issue commands and read and write data to and from GPIB devices.
The Prologix controller can also act as a device and Device::GPIB::Prologix supports this.

Requires Device::SerialPort.

=head2 EXPORT

None by default.

=head2 LOW LEVEL FUNCTIONS

=over

=item send

$d->sendControllerCommand($command);

Sends the unescaped $command to the Prologix controller. This is for internal use only, and not for sending commands to 
GPIB devices, for which you should instead use send() or sendTo()

$d->send($command);

Sends the $command to the currently addressed device.

=item sendTo

$d->sendTo($command, $pad);

Sets the current address if necessary, sends the $command to the specified device.

=item read_to_timeout

Reads data until a timeout. No interpretation of incoming characters is done.

=item read_to_eol

Reads data until and EOL character (newline, "\n")  is read.

=item close

Closes the serial port device.

=back 

=head2 PROLOGIX COMMANDS

=over

=item new

my $d = Device::GPIB::Prologix->new($port);

Creates a new device instance, connected to the Prologix GPIB-USB Controller via the serial-USB port
specified by $port (default '/dev/ttyUSB0').

The Device::GPIB::Prologix object will be automatically destroyed and the serial port closed when the reference goes
out of scope.

=item read

$data = $d->read();

Read data from the addressed instrument until a timeout.

$data = $d->read(1);

Read data from the addressed instrument until EOI or timeout.

=item read_binary

Reads binary data from the addressed instrument until a timeout expires.
The binary data s delivered verbatim, adn can enclude the EOL character.
 
=item version

Returns the version string from the Prologix GPIB-USB controller.

=item auto

Issues the '++auto' command to the PRologix controller, which is not very useful with this package.

=item addr

Configure or query the current GPIB address of the GPIB controllerusing the '++addr' command.

$ver = $d->addr();

Returns the currently selected GPIB device address.

$d->addr($pad);

Sets the GPIB address of the instrument to be controlled. 
$pad is an integer between 0 and 30.

$d->addr($pad, $sad);

Sets both the Primary and secondary address of the instrument to be controlled.
$pad is an integer between 0 and 30.
$sad is an ineger between 96 and 126.

=item clr

Sends the Selected Device Clear (SDC) message to the currently specified GPIB address.

=item eoi

$d->eoi($bool);

Enables or disables the assertion of the EOI signal with the last character.

$set = $d->eoi();

Queries whether EOI is enabled or disabled.

=item eos

$d->eos($val);

Specifies the GPIB termination character, where $val is:

0 Append CR+LF to instrument commands
1 Append CR to instrument commands
2 Append LF to instrument commands
3 Do not append anything to instrument commands

$val = $d->eos();

Queries the current setting of eoi.

=item eot_enable

$d->eot_enable($bool)
Enables or disables the appending of a user specified character (see eot_char) 
to USB output whenever EOI is detected while reading a character from the GPIB port.

$val = $d->eot_enable();

Queries the current state of eot_enable.

=item eot_char

$d->eot_char($char);

Specifies the character to be appended to USB output when eot_enable is set to 1 and EOI is detected.

$char = $d->eot_char();

Queries the value of the currently set eot_char.

=item ifc

$d->ifc();

Asserts GPIB IFC signal for 150 microseconds making Prologix GPIB-USB 
controller the Controller-In-Charge on the GPIB bus.

=item llo

$d->llo();

Disables front panel operation of the currently addressed instrument.

=item loc

$d->loc();

Enables front panel operation of the currently addressed instrument.

=item lon

$d->lon($bool)

Enables or disables the GPIB-USB controller to listen to all traffic on the GPIB bus, 
irrespective of the currently specified address (listen-only mode).

$val = $d->lon();

Queries the state of the lon.

=item mode

$d->mode($val);

Configures the Prologix GPIB-USB controller to be a CONTROLLER or DEVICE, where 
$val = 1 is CONTROLLER and
$val = 2 is DEVICE

$val = $d->mode();

Queries the current value of the mode setting.

=item read_tmo_ms

$d->read_tmo_ms($val);

specifies the timeout value, in milliseconds, to be used in the read command and spoll command. 
Timeout may be set to any value between 1 and 3000 milliseconds

=item rst

$d->rst();

Performs a power-on reset of the controller. The process takes about 5 seconds. 
All input received over USB during this time are ignored.

=item savecfg

$d->savecfg($val);

Enables, or disables, automatic saving of configuration parameters in EPROM.

$val = $d->savecfg();

=item spoll

performs a serial poll of the instrument at the specified address. 
If no address is specified then this command serial polls the currently addressed instrument.

$d->spoll($pad);

Serial poll instrument at primary address.

$d->spoll($pad, $sad);

Serial poll instrument at primary address and secondary address.

$d->spoll(); 

Serial poll the currently addressed instrument.

=item srq

$val= $d->srq();

Returns the current state of the GPIB SRQ signal.

=item status

$d->status($val);

Specify the device status byte to be returned when serial polled by a GPIB controller.

=item trg

$d->trg($pad1, $sad1, ......);

issues Group Execute Trigger GPIB command to devices at the specified addresses. Up to 15 addresses maybe specified.

=item id

$d->id()

Queries the device for its ID and retuens it. If there is no device at the assigned address, returns empty string

=back

=head1 SEE ALSO

=head1 EXAMPLES

A number ofsample programs are provided in bin which may be useful in their own right.
They will be installed into your perl script diorectory if you 'make install'.

=head2 tekscreendump.pl

Make a screendump from a Tek TDS-220 or similar scope
tekscreendump.pl -address 1 >/tmp/x.bmp

=head2 dm5110.pl

Read values continuously from a Tektronix DM5110.
dm5110.pl -address 22

=head1 AUTHOR

Mike McCauley, E<lt>mikem@airspayce.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Mike McCauley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

