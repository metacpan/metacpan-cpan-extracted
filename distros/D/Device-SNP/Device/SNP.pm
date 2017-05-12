# SNP.pm
#
# Implement GE Fanuc SNP protocol on serial line
# Protocol is described at http://globalcare.gefanuc.com in
# these documents:
# GFK-0582D SNP-X
# GFK-0529C SNP
# ONly slave is supported so far.
# You can subclass and override functions to implement
# specific device features, or implemnt your own data storage and access functions.
# By default it reads and writes data from the data segments
# in %Device::SNP::segment
#
# Author: Mike McCauley (mikem@airspayce.com)
# Copyright (C) 2006 Mike McCauley
# $Id: SNP.pm,v 1.1 2006/05/31 23:30:53 mikem Exp mikem $
use Device::SerialPort;
use strict;

package Device::SNP;
our $VERSION = '1.3';

$Device::SNP::StartOfMessage = 0x1b;
$Device::SNP::EndOfBlock     = 0x17;

$Device::SNP::BroadcastSNPID = "\xff\xff\xff\xff\xff\xff\xff\xff";
$Device::SNP::NullSNPID      = "\x00\x00\x00\x00\x00\x00\x00\x00";

# SNP Message types (not used here, except for XMessage and Text)
$Device::SNP::MtypeAttach         = 0x41;
$Device::SNP::MtypeAttachResponse = 0x52;
$Device::SNP::MtypeMailbox        = 0x4d;
$Device::SNP::MtypeText           = 0x54;
$Device::SNP::MtypeBlockTransfer  = 0x42;
$Device::SNP::MtypeConnection     = 0x43;
$Device::SNP::MtypeUpdate         = 0x55;
$Device::SNP::MtypeInquiry        = 0x49;
$Device::SNP::MtypeXMessage       = 0x58;

# SNP-X Message types
$Device::SNP::XtypeAttach         = 0x00;
$Device::SNP::XtypeAttachResponse = 0x80;
$Device::SNP::XtypeRead           = 0x01;
$Device::SNP::XtypeReadResponse   = 0x81;
$Device::SNP::XtypeWrite          = 0x02;
$Device::SNP::XtypeWriteResponse  = 0x82;

# Major error codes
$Device::SNP::ErrorMajorNone                  = 0x00;
$Device::SNP::ErrorMajorServiceRequestError   = 0x05;

# Minor error codes
$Device::SNP::ErrorMinorNone                  = 0x00;
$Device::SNP::ErrorMinorInvalidInputParameter = 0xf4;

# These variables hold the PLC data in raw format
# They will auto-vivify to be as big as needed
%Device::SNP::segment =
    (
     'R'  => [],
     'AI' => [],
     'AQ' => [],
     'I'  => [],
     'Q'  => [],
     'T'  => [],
     'M'  => [],
     'SA' => [],
     'SB' => [],
     'SC' => [],
     'S'  => [],
     'G'  => [],
     );     

# Description of the data segments we can handle.
# The index is the PLC memory type code from table 6-1
# The addressing type is word, byte or bit
%Device::SNP::segments =
(
 0x08 => ['R',  'word'],           # Registers %R, word
 0x0a => ['AI', 'word'],           # Analog Inputs %AI, word
 0x0c => ['AQ', 'word'],           # Analog Outputs %AQ, word

 0x46 => ['I',  'bit'],            # Discrete Inputs %I, bit
 0x10 => ['I',  'byte'],           # Discrete Inputs %I, byte

 0x48 => ['Q',  'bit'],            # Discrete Outputs %Q, bit
 0x12 => ['Q',  'byte'],           # Discrete Outputs %Q, byte

 0x4a => ['T',  'bit'],            # Discrete Temporaries %T, bit
 0x14 => ['T',  'byte'],           # Discrete Temporaries %T, byte

 0x4c => ['M',  'bit'],            # Discrete Internals %M, bit
 0x16 => ['M',  'byte'],           # Discrete Internals %M, byte

 0x4e => ['SA', 'bit'],            # Discretes %SA, bit
 0x18 => ['SA', 'byte'],           # Discretes %SA, byte

 0x50 => ['SB', 'bit'],            # Discretes %SB, bit
 0x1a => ['SB', 'byte'],           # Discretes %SB, byte

 0x52 => ['SC', 'bit'],            # Discretes %SC, bit
 0x1c => ['SC', 'byte'],           # Discretes %SC, byte

 0x54 => ['S',  'bit'],            # Discretes %S read only, bit
 0x1e => ['S',  'byte'],           # Discretes %S, byte

 0x56 => ['G',  'bit'],            # Genius Global Data %G, bit
 0x38 => ['G',  'byte'],           # Genius Global Data %G, byte
 );

# Raw data formats:
# decimal       raw       reversed
# bit access in a word segment:
# 0             0000
# 1             0100
# word is 2 bytes. LSB first, MSB second
# 0             0000
# 1             0100
# 256           0001
# 258           0201
# dword is 4 bytes. LSB first, MSB last
# 0             00000000
# 1             01000000
# 256           00010000
# 65536         00000100
# 16777216      00000001
# 6730598g5      01020304
# Floating point is 4 bytes:
# -8            000000c1
# -4            000080c0
# -2            000000c0
# -1            000080bf
# 0             00000000
# 1             0000803f
# 2             00000040
# 4             00008040
# 8             00000041
# 10            00002041
# 16            00008041

# Tests:
# broadcast xattach:
#&handle_raw_message(pack('H*', '1b58ffffffffffffffff0000000000000000170000000079'));
# point-to-point xattach:
#&handle_raw_message(pack('H*',  '1b5800000000000000000000000000000000170000000079'));
# read:
#&handle_raw_message(pack('H*',  '1b5800000000000000000146010001000000170000000037'));
#&handle_raw_message(pack('H*',   '1B584142434445460000010800000400000017000000001A'));
#exit;

package Device::SNP::Slave;

#####################################################################
sub new
{
    my ($class, %args) = @_;

    my $self = {};
    bless $self, $class;

    # Initialize some values
    $self->{Portname} = '/dev/ttyS1';
    $self->{SNPID}    = '';
    $self->{Debug}    = 0;

    # Override with args
    map {$self->{$_} = $args{$_}} (keys %args);

    $self->{attached} = 0;
    $self->{plcstatusword} = 0;
    # Expected values for next packet, in case of deferred write
    $self->{expecttype} = 0;
    $self->{expectlength} = 24;
    $self->{expectSelector} = 0;
    $self->{expectOffset} = 0;
    $self->{expectLength} = 0;

    return $self;
}

#####################################################################
sub run
{
    my ($self) = @_;

    # Open the port

    my $port = new Device::SerialPort($self->{Portname});
    die "Could not open serial port $self->{Portname}: $!" unless $port;

    # Set up the port for standard SNP
    $port->baudrate(19200);
    $port->databits(8);
    $port->parity('odd');
    $port->stopbits(1);
    $port->handshake('none');
    $port->write_settings();
    $port->read_char_time(0);
    $port->read_const_time(1000);
    $port->stty_icanon(0);
#    $port->save('/tmp/xx');
    $self->{port} = $port;
    $self->main_loop();
}

#####################################################################
sub main_loop
{
    my ($self) = @_;

    while (1)
    {
	my ($count, $in, $buf);
	
	# Wait for Start-Of-Message
	while (1)
	{
	    ($count, $in) = $self->{port}->read(1);
	    last if ($count == 1) && ($in eq "\x1b");
	}
	$buf = $in;
	($count, $in) = $self->{port}->read($self->{expectlength} - 1);
	next unless $count == ($self->{expectlength} - 1);
	$buf .= $in;
	
	$self->handle_raw_message($buf);
    }
}

#####################################################################
sub handle_raw_message
{
    my ($self, $msg) = @_;

    my $hex = unpack('H*', $msg);
    print "receive: $hex\n" if $self->{Debug};

    # Calculate the correct BCC, using everything except 
    # the last byte which is the received BCC
    my $mybcc = &compute_bcc(substr($msg, 0, -1));

    # Now have a complete 24 byte SNP command in $buf, including the start char
    # Unpack into header data and trailer
    my $header = substr($msg, 0, 2);
    my $cmddata = substr($msg, 2, -6);
    my $trailer = substr($msg, -6);

    # Decode header and trailer
    my ($som, $mtype) = unpack('C C', $header);
    my ($eob, $nexttype, $nextlength, $unused, $bcc) = unpack('C C v C C', $trailer);

    # Message contents checks
    if ($bcc != $mybcc)
    {
	warn "Bad BCC, should be $mybcc, received $bcc";
    }
    elsif ($som != $Device::SNP::StartOfMessage)
    {
	warn "Incorrect Start-Of-Message";
    }
    elsif ($eob != $Device::SNP::EndOfBlock)
    {
	warn "Incorrect EndOf-Block";
    }
    elsif ($self->{expecttype} && $self->{expecttype} != $mtype)
    {
	warn "Expected next type of $nexttype, but received $mtype";
    }
    else
    {
	# OK
	# Check whether there is info about the next expected type
	$self->{expecttype}   = $nexttype;
	$self->{expectlength} = 24;
	$self->{expectlength} = $nextlength
	    if $nexttype;
	# Dispatch the message
	$self->handle_message($mtype, $cmddata);
    }
}

#####################################################################
sub handle_message
{
    my ($self, $mtype, $cmddata) = @_;

    print "handle_message $mtype\n" if $self->{Debug};
    if ($mtype == $Device::SNP::MtypeXMessage)
    {
	my ($snpid, $reqcode, $data) = unpack('a8 C a*', $cmddata);
	$self->handle_x_message($snpid, $reqcode, $data);
    }
    elsif ($mtype == $Device::SNP::MtypeText)
    {
	$self->handle_t_message($cmddata);
    }
}

#####################################################################
sub handle_t_message
{
    my ($self, $data) = @_;

    my $x = unpack('H*', $data);
    print "got a T: $x\n" if $self->{Debug};
    if ($self->handle_write($self->{expectSelector}, 
			    $self->{expectOffset}, 
			    $self->{expectLength}, $data))
    {
	# Reply
	$self->send_message($Device::SNP::MtypeText, 
			    pack('C v C C v', 
				 $Device::SNP::XtypeWriteResponse, 
				 $self->{plcstatusword}, 
				 $Device::SNP::ErrorMajorNone, 
				 $Device::SNP::ErrorMinorNone, 0));
    }
    else
    {
	# Error
	$self->send_message($Device::SNP::MtypeText, 
			    pack('C v C C v', 
				 $Device::SNP::XtypeWriteResponse, 
				 $self->{plcstatusword}, 
				 $Device::SNP::ErrorMajorServiceRequestError, 
				 $Device::SNP::ErrorMinorInvalidInputParameter, 0));
    }
}

#####################################################################
sub handle_x_message
{
    my ($self, $snpid, $reqcode, $cmddata) = @_;

    print "handle_x_message $reqcode\n" if $self->{Debug};
    if ($reqcode == $Device::SNP::XtypeAttach)
    {
	$self->handle_x_attach($snpid);
    }
    elsif ($reqcode == $Device::SNP::XtypeRead)
    {
	$self->handle_x_read($snpid, $cmddata);
    }
    elsif ($reqcode == $Device::SNP::XtypeWrite)
    {
	# REVISIT: handle broadcast writes
	$self->handle_x_write($snpid, $cmddata);
    }
}

#####################################################################
sub handle_x_attach
{
    my ($self, $snpid) = @_;

    print "handle_x_attach\n" if $self->{Debug};
    return unless ($snpid eq $Device::SNP::BroadcastSNPID
		   || $snpid eq  $Device::SNP::NullSNPID
		   || $snpid eq $self->{SNPID});
    # According to the docs, No reply required
    # but Datapanel 160 does not work correctly unless
    # we do reply to the broadcast attach :-(
    $self->send_x_attach_response();
    $self->{attached}++;
}

#####################################################################
sub handle_x_read
{
    my ($self, $snpid, $cmddata) = @_;

    print "handle_x_read $snpid\n" if $self->{Debug};
    return unless (   $snpid eq  $Device::SNP::NullSNPID
		   || $snpid eq $self->{SNPID});

    my ($selector, $offset, $length, $unused) = unpack('C v v v', $cmddata);
    $self->handle_read($selector, $offset, $length);
}

#####################################################################
sub handle_read
{
    my ($self, $selector, $offset, $length) = @_;

    print "handle_read $selector, $offset, $length\n" if $self->{Debug};

    my ($segmentname, $type) = @{$Device::SNP::segments{$selector}};
    my $data;
    if ($type eq 'word')
    {
	$data = $self->read_words($segmentname, $offset, $length);
    }
    elsif ($type eq 'byte')
    {
	$data = $self->read_bytes($segmentname, $offset, $length);
    }
    elsif ($type eq 'bit')
    {
	$data = $self->read_bits($segmentname, $offset, $length);
    }

    if (defined $data)
    {
	$self->send_x_message(pack('C v C C v/a*', 
				   $Device::SNP::XtypeReadResponse, 
				   $self->{plcstatusword}, 
				   $Device::SNP::ErrorMajorNone, 
				   $Device::SNP::ErrorMinorNone, $data));
    }
    else
    {
	# Error
	$self->send_x_message(pack('C v C C v', 
				   $Device::SNP::XtypeReadResponse, 
				   $self->{plcstatusword}, 
				   $Device::SNP::ErrorMajorServiceRequestError, 
				   $Device::SNP::ErrorMinorInvalidInputParameter, 0));
    }
}

#####################################################################
sub read_words
{
    my ($self, $segmentname, $offset, $length) = @_;

    my $segment = $Device::SNP::segment{$segmentname};
    return unless defined $segment;

    my $boffset = $offset * 2;
    my $blength = $length * 2;
    return pack('C*', @{$segment}[$boffset .. ($boffset + $blength)]);
}

#####################################################################
sub read_bytes
{
    my ($self, $segmentname, $offset, $length) = @_;

    my $segment = $Device::SNP::segment{$segmentname};
    return unless defined $segment;

    return pack('C*', @{$segment}[$offset .. ($offset + $length)]);
}

#####################################################################
sub read_bits
{
    my ($self, $segmentname, $offset, $length) = @_;

    my $segment = $Device::SNP::segment{$segmentname};
    return unless defined $segment;

    my $boffset = int($offset / 8);
    my $blength = int(($length + 7) / 8);
    return pack('C*', @{$segment}[$boffset .. ($boffset + $blength)]);
}

#####################################################################
sub handle_x_write
{
    my ($self, $snpid, $cmddata) = @_;

    return unless ($snpid eq $Device::SNP::BroadcastSNPID
		   || $snpid eq  $Device::SNP::NullSNPID
		   || $snpid eq $self->{SNPID});

    my ($selector, $offset, $length, $data) = unpack('C v v a*', $cmddata);
    print "handle_x_write $selector, $offset, $length\n" if $self->{Debug};

    if ($self->{expecttype} == $Device::SNP::MtypeText)
    {
	# Sigh, the data will be in the next request,
	# remember the data from this message until later
	$self->{expectSelector} = $selector;
	$self->{expectOffset}   = $offset;
	$self->{expectLength}   = $length;
	$self->send_x_message(pack('C v C C v', 
				   $Device::SNP::XtypeWriteResponse, 
				   $self->{plcstatusword}, 
				   $Device::SNP::ErrorMajorNone, 
				   $Device::SNP::ErrorMinorNone, 0));
    }
    elsif ($self->handle_write($selector, $offset, $length, $data))
    {
	$self->send_x_message(pack('C v C C v', 
				   $Device::SNP::XtypeWriteResponse, 
				   $self->{plcstatusword}, 
				   $Device::SNP::ErrorMajorNone, 
				   $Device::SNP::ErrorMinorNone, 0));
    }
    else
    {
	# Error
	$self->send_x_message(pack('C v C C v', 
				   $Device::SNP::XtypeWriteResponse, 
				   $self->{plcstatusword}, 
				   $Device::SNP::ErrorMajorServiceRequestError, 
				   $Device::SNP::ErrorMinorInvalidInputParameter, 0));
    }

    # Intermediate response is the same is write response
}

#####################################################################
# Write data to the sement
sub handle_write
{
    my ($self, $selector, $offset, $length, $data) = @_;

    my $x = unpack('H*', $data);
    print "handle_write $selector, $offset, $length, $x\n" if $self->{Debug};

    my ($segmentname, $type) = @{$Device::SNP::segments{$selector}};
    if ($type eq 'word')
    {
	return $self->write_words($segmentname, $offset, $length, $data);
    }
    elsif ($type eq 'byte')
    {
	return $self->write_bytes($segmentname, $offset, $length, $data);
    }
    elsif ($type eq 'bit')
    {
	return $self->write_bits($segmentname, $offset, $length, $data);
    }
}

#####################################################################
sub write_words
{
    my ($self, $segmentname, $offset, $length, $data) = @_;

    my $segment = $Device::SNP::segment{$segmentname};
    return unless defined $segment;

    my $boffset = $offset * 2;
    my $blength = $length * 2;
    for (my $i = 0; $i < $blength; $i++)
    {
	@{$segment}[$boffset++] = ord(substr($data, $i, 1));
    }
    return 1;
}

#####################################################################
sub write_bytes
{
    my ($self, $segmentname, $offset, $length, $data) = @_;

    my $segment = $Device::SNP::segment{$segmentname};
    return unless defined $segment;

    for (my $i = 0; $i < $length; $i++)
    {
	@{$segment}[$offset++] = ord(substr($data, $i, 1));
    }
    return 1;
}

#####################################################################
sub write_bits
{
    my ($self, $segmentname, $offset, $length, $data) = @_;

    my $segment = $Device::SNP::segment{$segmentname};
    return unless defined $segment;
    my @data = unpack('C*', $data);
    for (my $i = 0; $i < $length; $i++)
    {
	my $destindex = int(($offset + $i) / 8);
	my $srcindex = int((($offset % 8) + $i) / 8);
	my $bit = ($offset + $i) % 8;
	my $mask = 1 << $bit;
	if ($data[$srcindex] & $mask)
	{
	    # Set
	    $$segment[$destindex] |= $mask;
	}
	else
	{
	    # Clear
	    $$segment[$destindex] &= ~$mask;
	}
    }
    return 1;
}

#####################################################################
sub send_x_attach_response
{
    my ($self) = @_;
    
    print "send_x_attach_response\n" if $self->{Debug};
    $self->send_x_message(pack('a8 C a7', 
			       $self->{SNPID}, 
			       $Device::SNP::XtypeAttachResponse, 
			       ''));
}

#####################################################################
sub send_x_message
{
    my ($self, $cmddata) = @_;

    $self->send_message($Device::SNP::MtypeXMessage, $cmddata);
}

#####################################################################
sub send_message
{
    my ($self, $mtype, $cmddata) = @_;
    my $msg = pack('C C a* C C n C', 
		   $Device::SNP::StartOfMessage,
		   $mtype,
		   $cmddata,
		   $Device::SNP::EndOfBlock,
		   0, 0, 0);
    # Append the BCC byte
    $msg .= chr(compute_bcc($msg));

    # Send it
    $self->send_raw_message($msg);
}

#####################################################################
sub send_raw_message
{
    my ($self, $msg) = @_;

    # Print it out
    my $hex = unpack('H*', $msg);
    print "send: $hex\n" if $self->{Debug};

    return unless $self->{port}; # Testing
    $self->{port}->dtr_active('T');
    my $count = $self->{port}->write($msg);
    $self->{port}->write_drain();
    $self->{port}->dtr_active('F');
    warn "write failed\n" unless ($count);
    warn "write incomplete\n" unless $count == length($msg);
}

#####################################################################
sub compute_bcc
{
    my ($s) = @_;

    my $bcc = 0;
    for (split(//, $s))
    {
	$bcc ^= ord($_);
	# 8 bit rotate (msb -> lsb)
	$bcc <<= 1;
	$bcc |= 1 if $bcc & 0x100;
	$bcc &= 0xff;
    }

    return $bcc;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Device::SNP - Perl extension for the GE Fanuc SNP-X
serial protocol as used by GE Fanuc DataPanel data terminals.  See
http://www.gefanuc.com/en/ProductServices/VisPCSolutions/DataPanel/index.html

=head1 SYNOPSIS

  use Device::SNP;

  my $s = new Device::SNP::Slave(
                       Portname => '/dev/ttyUSB0',
		       Debug => 0);
  $s->run();

Amarok serial interface program:
datapanel.pl [-h] [-d] [-p portdevice]

portdevice defaults to /dev/ttyUSB0

=head1 ABSTRACT

This Device::SNP module contains an implementation of the GE Fanuc SNP-X
serial protocol as used by GE Fanuc DataPanel data terminals.  See
http://www.gefanuc.com/en/ProductServices/VisPCSolutions/DataPanel/index.html

=head1 DESCRIPTION

DataPanels are usually used with PLCs to monitor and control industrial
equipment. They provide a programmable bitmap display, programmable function
keys, and can poll and display data values and set data values in a remote PLC
using the SNP-X serial protocol.

The Device::SNP::Slave object implements an SNP-X slave, opens a
Device::Serial port and answers SNP-X requests to read and write data to a
simulated PLC.

This package also contains a sample application that uses a DataPanel 160 to
implement a remote control panel for the Amarok music player on Linux,
allowing you to play, pause, next, prev tracks etc.

DataPanels are programmed with a GE application called DataDesigner,
available from the GE web site for registered customers. Included in this
package is a database for DataDesigner 5.2 for the Amarok remote control
application. You will need DataDesigner 5.2 to download the
datadesigner/linux.DTB database to the DataPanel 160

Tested on SuSE linux, but should run on pretty well any Linux or Unix.

=head2 EXPORT

None by default.

=head1 SEE ALSO


=head1 AUTHOR

Mike McCauley, E<lt>mikem@airspayce.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 Mike McCauley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
