# Serial.pm
# Device::GPIB interface to Serial Controller, maybe GPIB comnpatible
# Useful for some types of device like Tek 1240 RS232 Comm Pack 1200C01
# Author: Mike McCauley (mikem@airspayce.com),
#
# Works with:
#
# Default port params are OK for Tek 1240 at 9600 baud
# For AR488 on Linux, need -port /dev/ttyUSB0:115200
#
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Controllers::Serial;

use strict;
use Device::SerialPort;

$Device::GPIB::Controllers::Serial::VERSION = '0.02';

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

    $self->debug("$class is connecting to $portname with $self->{Baudrate}:$self->{Databits}:$self->{Parity}:$self->{Stopbits}:$self->{Handshake}");

    $self->{serialport} = Device::SerialPort->new($portname);
    if (!$self->{serialport})
    {
	die "Could not open serial:$port: $!";
	return;
    }

    $self->{serialport}->baudrate($self->{Baudrate});
    # Sigh: Baud rate setting does not work correctly on Ubuntu 25.10
    # because Device::SerialPort is trying to set eg the flags from symbolic bauds rates like
    # B9600 instead of integer 9600
    if ($^O == "linux")
    {
	$self->{serialport}->{"C_ISPEED"} = $self->{Baudrate};
	$self->{serialport}->{"C_OSPEED"} = $self->{Baudrate};
    }
    $self->{serialport}->databits($self->{Databits});
    $self->{serialport}->parity($self->{Parity});
    $self->{serialport}->stopbits($self->{Stopbits});
    $self->{serialport}->handshake($self->{Handshake});
    $self->{serialport}->read_char_time($self->{ReadCharTimeout});
    $self->{serialport}->read_const_time(100);
    $self->{serialport}->stty_icanon(0);
    
#    $self->{serialport}->stty_onlcr(0);
#    $self->{serialport}->stty_echoctl(0);
    $self->{serialport}->stty_echo(0);
#    $self->{serialport}->stty_echoe(0);
#    $self->{serialport}->stty_echok(0);
#    $self->{serialport}->stty_echonl(0);
#    $self->{serialport}->stty_echoke(0);
#    $self->{serialport}->stty_echoctl(0);
#    $self->{serialport}->stty_ignpar(1);
#    system("stty -F /dev/ttyUSB0");
    
    return $self;
}

sub isSerial($)
{
    return 1;
}

sub writeLowLevel($$)
{
    my ($self, $s) = @_;
#    my $x = unpack('H*', $s);
#    print "Serial writeLowLevel: $x\n";
    return $self->{serialport}->write($s); 
}

sub send($$)
{
    my ($self, $s) = @_;

    $self->debug("Sending Command: '$s'");
    if ($Device::GPIB::Controller::debug)
    {
	my $x = unpack('H*', $s);
	print "COMMAND HEX: $x\n";
    }
    return $self->{serialport}->writeLowLevel($s . "\n"); 
}

sub readLowLevel($$)
{
    my ($self, $count) = @_;

    return $self->{serialport}->read($count);
}

sub read_to_timeout($)
{
    my ($self) = @_;

    my $buf;
    while (1)
    {
	my ($count, $ch) = $self->{serialport}->read(1);
	my $x = unpack('H*', $ch);
	$self->debug("got $count, $ch: $x");
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
	    $self->debug("got $count, $ch: $x");
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
	    $self->debug("read_to_eol Timeout");
	    last;
	}
    }

    # Got a buffer full
    $self->debug("Read: '$buf'");
    return $buf;
}

sub read($$$)
{
    my ($self, $pad, $sad) = @_;

    return $self->read_until_timeout_or('eoi'); # Only works if EOI is enabled
}

sub read_binary($$$)
{
    my ($self, $pad, $sad) = @_;

    return $self->read_to_timeout();
}

sub warning($)
{
    my ($self, $s) = @_;

    Device::GPIB::Controller::warning($s);
}

sub debug($)
{
    my ($self, $s) = @_;

    Device::GPIB::Controller::debug($s);
}

sub close($)
{
    my ($self) = @_;

    if ($self->{serialport})
    {
	$self->{serialport}->close();
	undef $self->{serialport};
    }
}

sub DESTROY($)
{
    my ($self) = @_;

    $self->close();
}

sub sendTo($$$$)
{
    my ($self, $s, $pad, $sad) = @_;

    return $self->send($s);
}

## dummy functions for conpatibility with GPIB
# Can be overridden
sub clr($$$)
{
    my ($self, $pad, $sad) = @_;
}



1;

__END__

=head1 NAME

Device::GPIB::Controllers::Serial - Interface to devices that implement GPIB-like commands
over Serial ports. Available as a superclass to GPIB controllers that use a Serial interface.

=head1 SYNOPSIS

  use Device::GPIB::Controllers::Serial;
  my $d = Device::GPIB::Controllers::Serial->new('/dev/ttyUSB0');
  $d->sendTo('id?');
  my $id = $d->read();

=head1 DESCRIPTION

This module provides an OO interface to devices that implement GPIB-like commands over a serial port,
such as the Tektronix 1240 with 1200C01 RS232C Comm Pack.
Available as a superclass to GPIB controllers that use a Serial interface
such as the Prologix GPIB-USB Controller.

It allows you to issue commands and read and write data to and from GPIB-like Serial devices.

Requires Device::SerialPort.

=head2 EXPORT

None by default.

=head2 LOW LEVEL FUNCTIONS

=over

=item send

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

=head1 AUTHOR

Mike McCauley, E<lt>mikem@airspayce.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Mike McCauley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.1 or,
at your option, any later version of Perl 5 you may have available.


=cut


