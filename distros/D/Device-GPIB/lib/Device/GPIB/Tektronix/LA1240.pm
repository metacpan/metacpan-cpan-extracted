# LA1240.pm
# Perl module to control a Tektronix 1240 Logic Analyser by GPIB or Serial
# using the 1200C01 (RS232C serial) or 1200C02 (GPIB) Comm Packs
#
# LA 1240 responds to these commands in Serial mode
# HELP ACqmem,BEll,DIAg,DISplay,ERror,EVent,GTL,HElp,ID,INIt,INSetup,KEy,LLo,LOad,NOK,OK,RAmpack,REFmem,REMote,RPHelp,RQs,STARt,STATus,STOp,TEST,#H
# and in GPIB mode:
# HELP ACqmem,BEll,DAtafmt,DIAg,DISplay,DT,ERror,EVent,HElp,ID,INIt,INSetup,KEy,LOad,MSgdlm,RAmpack,REfmem,RPHelp,RQs,SEt,STArt,STOp,TEST
#
# For serial, the default is 9600:8:N:1
#
# For GPIB, the 1240 Logic Analyser must be configured for:
# GPIB PORT STATUS = ONLINE
# 1240's GPIN ADDRESS = 01   (or whatever for your system)
# MESSAGE TERMINATION = LF OR EOI
# (see the UTILITY -> COMM PORT CONTROL page)
#
# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix::LA1240;
@ISA = qw(Device::GPIB::Tektronix);
use Device::GPIB::Tektronix;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    $self->{Id} = $self->id();
    if ($self->{Id} !~ /1240/)
    {
	warn "Not a Tek 1240 Logic Analyzer at $self->{Address}: $self->{Id}";
	return;
    }

    # These are actually event codes
    $self->{ErrorStrings} = {
	101 => 'Command header error',
	102 => 'Header delimiter error',
	103 => 'Command argument error',
	104 => 'Argument delimiter error',
	105 => 'Non-numeric Argument (numeric expected)',
	106 => 'Missing argument',
	107 => 'Invalid message unit delimiter',
	108 => 'Binary block checksum error',
	109 => 'Binary block byte count error',
	121 => 'Illegal hex character',
	122 => 'Unrecognised arument type',
	123 => 'Argument too large',
	124 => 'Non-binary Argument (binary or hex expected)',
	
	201 => 'Remote Only command received while in local mode',
	202 => 'Command aborted - change to local',
	203 => 'I/O deadlock detected',
	205 => 'Argument out of range',
	206 => 'Group execute trigger ignored',
	251 => 'Header/Location conflict in ACQMEM, REFMEM, INSETUP, or RAMPACK',
	252 => 'System error (illegal command)',
	253 => 'Integer overflow (range 0-65535)',
	254 => 'RAM pack not installed',
	255 => 'Illegal ROM pack command',
	256 => 'REFMEM not compatible with ACQMEM',
	257 => 'TEST command cannot be executed when RQS is off',
	261 => 'Possible loss of data - change to local during upload',
	262 => 'Acquisition terminated - change to local',
	263 => 'Auto-run terminated - change to local',
	264 => 'Key operation terminated - change to local',
	265 => 'Conflict in SETUP memory',
	266 => 'Data block location out of range',
	267 => 'UNKNOWN CODE',  # not in any of my documents
	271 => 'Command too long',
	
	401 => 'ONLINE (Power On)',

	711 => 'Request ACQMEM upload',
	712 => 'Request REFMEM upload',
	713 => 'Request REFMEM download',
	714 => 'Request SETUP upload',
	715 => 'Request SETUP download',
	721 => 'End of acquisition',
	722 => 'End auto-run',
	723 => 'End of KEY',
	724 => 'End auto-run, memories equal',
	725 => 'End auto-run, memories not equal',
	731 => 'Diagnostics test complete',
	
    };
    return $self;
}

sub id($)
{
    my ($self) = @_;

    my $id = $self->sendAndRead('ID?');
    if ($id eq 'STATUS 41') # restarted
    {
	$id = $self->sendAndRead('ID?');
    }
    return $id;
}

sub getEvent($)
{
    my ($self) = @_;

    return $self->sendAndRead('EV?');
}

# Get all events until 0 and return as an array
sub getEvents($)
{
    my ($self) = @_;

    my @ret;
    while (1)
    {
	my $event = $self->getEvent();
	my $eventnum = 0;
	if ($event =~ /EVENT (\d+)/)
	{
	    $eventnum = $1;
	}

	return @ret if $eventnum == 0;
	push(@ret, $eventnum);
    }
}

sub getEventsAsStrings($)
{
    my ($self) = @_;

    my @events = $self->getEvents();
    return map $self->errorToString($_), @events;
}

sub remote($)
{
    my ($self) = @_;

    return 1 if !$self->isSerial(); # No equivalent in GPIB
    return 1 if $self->{IsInRemoteMode};
    
    my $result = $self->sendAndRead('REM'); # Only supported in Serial
    if ($result ne 'READY')
    {
	print("remote: Unexpected reply: $result\n");
	return 0;
    }
    $self->{IsInRemoteMode} = 1;
    return 1;
}

sub local($)
{
    my ($self) = @_;

    if ($self->isSerial())
    {
	my $result = $self->sendAndRead('GTL'); # Only supported in Serial
	if ($result ne 'READY')
	{
	    print("local: Unexpected reply: $result\n");
	    return 0;
	}
	$self->{IsInRemoteMode} = 0;
    }
    else
    {
	# GPIB
	$self->{Device}->loc();
	$self->{IsInRemoteMode} = 0;
    }
    
    return 1;
}

# Everything is converted to uppercase by the LA1240
# Min line number is 2
# Min Col number is 1
sub displayAscii($$$$)
{
    my ($self, $line, $col, $text) = @_;

    return unless $self->remote();
    my $result = $self->sendAndRead("DIS $line,$col,ASCII,\"$text\"");
    if ($self->isSerial && $result ne 'READY')
    {
	print("remote:Unexpected reply: $result\n");
	return 0;
    }
}

# Annoyingly, in Serial mode, the device will return READY, but in GPIB mode
# its the usual GPIB acknowledgement
sub sendAcknowledgedCommand($$)
{
    my ($self, $command) = @_;

    if ($self->isSerial())
    {
	my $result = $self->sendAndRead($command);
	print "Not in REMOTE mode\n" if ($result eq 'STATUS 72');
	return $result eq 'READY';
    }
    else
    {
	return $self->send($command);
    }
}

# Remote only commnd
sub bell($)
{
    my ($self) = @_;

    return unless $self->remote();

    return $self->sendAcknowledgedCommand('BEL');
}

sub key($)
{
    my ($self) = @_;

    return unless $self->remote();

    if ($self->isSerial())
    {
	my $result = $self->sendAndRead('KE');
	if ($result ne 'READY')
	{
	    print "Could not start KEY collection\n";
	    return 0;
	}
	# Now wait for 'STATUS hh' which will occur when the key is pressed
	while (($result = $self->{Device}->read_to_eol()) eq '')
	{
	    # Wait
	}
	if ($result eq 'STATUS C7')
	{
	    # Keypress has occurred, get it and return the keycode, decimal
	    $result = $self->sendAndRead('KE?');
	    return $1 if ($result =~ /KEY\s+(\d+)/);
	}
	else
	{
	    print "Unexpected response to KEY?: $result\n"
	}
	return 0;
    }
    else
    {
	# GPIB
	if ($self->send('KE'))
	{
	    # Now wait for SRQ which will occur when the key is pressed
	    while (!$self->{Device}->srq())
	    {
		# Wait
	    }
	    # Keypress has occurred, get it and return the keycode, decimal
	    my $result = $self->sendAndRead('KE?');
	    $self->{Device}->clr(); # Else SRQ is never cleared
	    return $1 if ($result =~ /KEY\s+(\d+)/);
	    print "Unexpected response to KEY?: $result\n"
	}
	return 0;
    }
}

sub start($)
{
    my ($self) = @_;

    return unless $self->remote();
    if ($self->isSerial())
    {
	# This will return as soon as acquisition started, and not wait for acquisition to complete
	if (!$self->sendAcknowledgedCommand('STAR AC')) # REVISIT: what about AUTO?
	{
	    print "Could not START\n";
	    return 0;
	}
    }
    else
    {
	if (!$self->send('STAR AC')) # REVISIT: what about AUTO?
	{
	    print "Could not START\n";
	    return 0;
	}
    }
    return 1;
}

sub stop($)
{
    my ($self) = @_;

    return unless $self->remote();
    if (!$self->sendAcknowledgedCommand('STO'))
    {
	print "Could not STOP\n";
	return 0;
    }
    return 1;
}

sub waitAcquisition($)
{
    my ($self) = @_;

    return unless $self->remote();
    if ($self->isSerial())
    {
	while ($self->status() == 91) # What about auto-run?
	{
	    # Wait
	}
    }
    else
    {
	while (!$self->{Device}->srq())
	{
	    # Wait
	}
	$self->{Device}->clr(); # Else SRQ is never cleared
    }
}

sub status($)
{
    my ($self) = @_;

    if ($self->isSerial())
    {
	my $result = $self->sendAndRead('STAT?');
	return $1 if ($result =~ /STATUS\s+(\d+)/);
    }
    else
    {
	# GPIB, read the status bits with spoll
	$self->{Device}->spoll($self->{Address});
	my $poll = $self->{Device}->read_to_eol();
	return sprintf("0x%X", $poll);
    }
    return 0;
}

sub checkData($$)
{
    my ($self, $result) = @_;

    if ($result =~ /#H(\p{Hex}{10,})/) # Must at least be char count, 3 bytes of location, data and checksum
    {
	# Get the reply in forms we can easily deal with
	my $ashex = $1;
	my $asbinary = pack('H*', $1);
	my @asbytes = unpack('C*', $asbinary);

	# First 2 hex digits should be the count and last 2 the checksum
	# The sum of the entire binary data (including checksum) should be 0
	my $checksum = unpack("%8C*", $asbinary); # Magic 8 bit summer
	if ($checksum != 0)
	{
	    print "Bad checksum in Hex response\n";
	    return;
	}
	# Checksum is ok, remove it from asbytes
	pop(@asbytes);
	
	# The length byte should agree with our data len
	# and should not exceed 61 hex
	my $len = shift(@asbytes);
	if ($len != length($asbinary) - 1)
	{
	    print "Bad length byte ($len) in Hex response\n";
	    return;
	}
	if ($len > hex('61'))
	{
	    print "Excessive length byte ($len) in Hex response\n";
	    return;
	}

	# Now get the location (next 3 bytes)
#	my $location = shift(@asbytes) << 16;
#	$location += (shift(@asbytes) << 8);
#	$location += shift(@asbytes);

	# The remainder of @asbytes is out data, one byte per entry
	#	return ($location, @asbytes);
	return $result;
    }
    # Hmmm, if binary is needed fir GPIB, need also:
    elsif ($result =~ /#H(\p{Hex}{5,})/) # Must at least be char count, 3 bytes of location, data and checksum
    {
	print "Binary fomat not supported\n";
	return;
    }
    else
    {
	print "Unexpected response format: $result\n";
	return;
    }
}

# ACqmem and REfmem commands returns hex data like
# #H34000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000CC
# The incoming data is encoded in hex or binary:
# 1 byte length of data
# 3 bytes location address
# <length> data bytes
# 1 byte checksum
# Returns an array, with the location as the first value and the data following, one byte per array member

sub acqmem($)
{
    my ($self) = @_;

    return $self->getData('AC?');
}


sub refmem($)
{
    my ($self) = @_;

    return $self->getData('REF?');
}

# INS? returns setup data in this format:
# #H340100000201000000000101000000000001010001000001010001FF01000001010001FF01000001010001FF01000001010001FFB8
# It includes configuration and trigger information
sub getSetup
{
    my ($self) = @_;

    return $self->getData('INS?');
}

# Send a command and get multiple lines of encoded data
sub getData($$)
{
    my ($self, $command) = @_;

    return unless $self->remote();
    
    my $result = $self->sendAndRead($command);


    if ($self->isSerial())
    {
	my $data;
	while (length($result))
	{
	    if ($result eq 'READY')
	    {
		# That was the last one
		return $data;
	    }
	    else
	    {
		my $line = $self->checkData($result);
		if (length($line))
		{
		    # Decoded OK
		    $data .= $line;
		    $data .= "\n";
		    $result = $self->sendAndRead('OK'); # Ask for the next one
		}
		else
		{
		    $result = $self->sendAndRead('NOK'); # Bad result, please send again
		}
	    }
	}
	return $data;
    }
    else
    {
	# GPIB
	# We have now slurped the whole thing
	# There is a leading string (ACQ, INSET or REF) and the lines are separated by commas
	$result =~ s/^\D+ //;
	map {$self->checkData($_)} split /,/, $result;
	$result =~ s/,/\n/g;
	$result .= "\n";
	return $result;
    }
}

sub init($)
{
    my ($self) = @_;

    return unless $self->remote();
    return $self->sendAcknowledgedCommand('INI');
}

sub test($)
{
    my ($self) = @_;

    return unless $self->remote();
#    my $result = $self->sendAndRead('TEST');  # NOT FINISHED
    my $result = $self->send('TEST');
    while (!$self->{Device}->srq())
    {
	print "waiting\n";
    }
    return; # FIXME
     
    # Now wait for 'STATUS hh' which will occur
    while (($result = $self->{Device}->read_to_eol()) eq '')
    {
	# Wait
    }
    if ($result eq 'STATUS C8')
    {
	return 1;
    }
    else
    {
	print "TEST failed: $result\n";
    }
}

sub sendData($$)
{
    my ($self, $datatype, $data) = @_; 

    if ($self->isSerial())
    {
	my @lines = split /\n/, $data;
	return unless @lines;
	#    $self->sendAndRead('INS'); # Not necessary to send a command, the #H triggers the load
	
	foreach my $line (@lines)
	{
	    my $result = $self->sendAndRead($line);
	    if ($result ne 'READY')
	    {
		print "Unexpected response $result\n";
		return;
	    }
	}
    }
    else
    {
	# GPIB
	$data =~ s/\n/,/g;
	return $self->sendAndRead("LOAD $datatype " . $data);
    }
    return 1;
}

# Seems the <loc> field identifies the actual memory involved
# For Serial interface, no ACQ, REF or INS command is required
sub loadAcqmem
{
    my ($self, $data) = @_; # $data is the entire setup, mutiple lines

    return $self->sendData('ACQMEM', $data);
}

sub loadRefmem
{
    my ($self, $data) = @_; # $data is the entire setup, mutiple lines

    return $self->sendData('REFMEM', $data);
}

sub loadSetup
{
    my ($self, $data) = @_; # $data is the entire setup, mutiple lines

    return $self->sendData('INSET', $data);
}

# Unimplemented commands
# DIAG
# LL lockout
# MSGDIM
# RAMPACK

1;

