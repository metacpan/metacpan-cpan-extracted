# TCP.pm
# Device::GPIB interface to a Controller via TCPIP, maybe GPIB compatible
# devices like AR488-ESP32 https://github.com/douardda/AR488-ESP32
#
# BUT.... there are some problems with AR488-ESP32 and at this date 2026-02-12, it appears to be
# a dead project since 2023. Some things might work?
#
# The default pinouts for AR488-ESP32 are defined in platformio.ini:
# DIO1=34 DIO2=35 DIO3=32  DIO4=33
# DIO5=25 DIO6=26 DIO7=27  DIO8=14
# REN=13  IFC=15  NDAC=22  NRFD=19
# DAV=23  EOI=18  ATN=5    SRQ=2
#
# BUT....
# We tested with ESP32-MINI-D1, with differnet pin settings in platofmrio.ini like this:
# These GPIO pins are tested to be ok for input or output:
# 26, 18, 19, 23, 13, 22, 21, 17, 16, 5, 33, 14, 27, 25, 32, 12, 0, 2, 3
# (13 == TCK, 14 == TMS, 12 == TDI)
# But 17 seems to be driven low all the time: UART?
#
# ;; mikem 2026-02-12
# [env:esp32mini-d1]
# extends = esp32
# board = esp32dev
# board_build.partitions = ttgo.csv
# build_flags =
# 	${esp32.build_flags}
# 	-D AR488_WIFI_ENABLE
# 	-D BOARD_HAS_PSRAM
# 	-D AR488_BT_ENABLE
#; 	-D SN7516X -D SN7516X_TE=2 -D SN7516X_DC=5
#;         -D SN7516X_SC=0  # for 75162
#
#	-D DIO1=26 -D DIO2=18 -D DIO3=19  -D DIO4=23
#	-D DIO5=13 -D DIO6=22 -D DIO7=21  -D DIO8=0
#	-D REN=16  -D IFC=5  -D NDAC=33  -D NRFD=14
#       -D DAV=27  -D EOI=25  -D ATN=32    -D SRQ=12


## Author: Mike McCauley (mikem@airspayce.com),
#
# Works with:
#
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Controllers::TCP;

use strict;
use IO::Socket::INET;
use IO::Select;

$Device::GPIB::Controllers::TCP::VERSION = '0.01';

sub new($$)
{
    my ($class, $port) = @_;

    my $self = {};
    bless $self, $class;

    # Defaults:
    $self->{Port} = '192.168.12.108:23';

    $self->{Port} = $port if defined $port;

    my ($address, $portnum) = split(/:/, $self->{Port});
    $self->{Address}  = $address  if defined $address;
    $self->{Portnum}  = $portnum  if defined $portnum;
    $self->{ReadCharTimeout} = 2000; # ms
    
    $self->debug("$class is connecting to $self->{Address} at port $self->{Portnum}");

    $self->{socket} = IO::Socket::INET->new(
	PeerHost => $self->{Address}, 
	PeerPort => $self->{Portnum},
	Proto    => 'tcp', 
	) or die "Cannot connect to tcp:$self->{Address}:$self->{Portnum} : $!\n";
    $self->{select} = IO::Select->new();
    $self->{select}->add($self->{socket});
    
    return unless $self->initialised();

    return $self;
}

sub initialised($)
{
    my ($self) = @_;

    return 1; # OK
}

sub isTCP($)
{
    return 1;
}

sub writeLowLevel($$)
{
    my ($self, $s) = @_;
    return $self->{socket}->send($s);
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
    return $self->writeLowLevel($s . "\n"); 
}

sub read_to_timeout($)
{
    my ($self) = @_;

    print "TCP read_to_timeout not implemented\n";
}

sub read_to_eol($)
{
    my ($self) = @_;

    my $buf;
    while (1)
    {
	$! = 0; # So we can distinguish between timeout and error
	if ($self->{select}->can_read($self->{ReadCharTimeout} / 1000))
	{
	    my $ch;
	    my $count = sysread($self->{socket}, $ch, 1);
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
		$self->warning("TCP sysread error: $!\n");
	    }
	}
	else
	{
	    if ($! == 0)
	    {
		$self->debug("read_to_eol Timeout");
	    }
	    else
	    {
		$self->warning("TCP can_read error: $!\n");
	    }
	    last;
	}
    }

    # Got a buffer full
    $self->debug("Read: '$buf'");
    return $buf;
}

# REad until a char or timeout.
# $waitfor can be either 'eoi' or the decimal number of the char < 256
sub read_until_timeout_or($$)
{
    my ($self, $waitfor) = @_;
    
    return $self->read_to_eol();
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

    if ($self->{socket})
    {
	$self->{socket}->close();
	undef $self->{socket};
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

Device::GPIB::Controllers::TCP - Interface to devices that implement GPIB-like commands
over TCP ports. Available as a superclass to GPIB controllers that use a TCP interface.

=head1 SYNOPSIS

  use Device::GPIB::Controllers::TCP;
  my $d = Device::GPIB::Controllers::TCP->new('192.168.12.100:23');
  $d->sendTo('id?');
  my $id = $d->read();

=head1 DESCRIPTION

This module provides an OO interface to devices that implement GPIB-like commands over a TCP port,
AR488-ESP32 
Available as a superclass to GPIB controllers that use a TCP interface
such as the Prologix GPIB-USB AR488TCP Controller.

It allows you to issue commands and read and write data to and from GPIB-like TCP ports.

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


