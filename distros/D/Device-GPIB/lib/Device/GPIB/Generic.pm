# Generic.pm
# Superclass for any GPIB device

# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Generic;

use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;
    
    my $self = {};
    bless $self, $class;

    $self->{Device} = $device;
    $self->{Address} = $address;
    
    return $self;
}

# Serial poll out all current events for this device, and report them in an array
# Works even if another device is asserting SRQ
# IF no SRQs returns empty array
sub spoll($)
{
    my ($self) = @_;

    my @result;
    while ($self->{Device}->srq())
    {
	$self->{Device}->spoll($self->{Address});
	my $poll = $self->{Device}->read_to_eol();
	last if $poll == 0;
	push(@result, $poll);
    }
    return @result;
}

# Wrapper for device send()
# Automatically sets the address to this device
sub send($$)
{
    my ($self, $s) = @_;

    $self->{Device}->sendTo($s, $self->{Address});
}

# Wrapper for device send()
# Automatically sets the address to this device
sub sendBinary($$)
{
    my ($self, $s) = @_;

    $self->{Device}->sendBinaryTo($s, $self->{Address});
}

# Wrapper for device read()
sub read($)
{
    my ($self) = @_;

    $self->{Device}->read($self->{Address});
}

# Wrapper for device read_binary()
sub read_binary($)
{
    my ($self) = @_;

    $self->{Device}->read_binary($self->{Address});
}

sub sendAndRead($$)
{
    my ($self, $s) = @_;

    $self->send($s) || return;
    return $self->read();
}

sub sendAndReadBinary($$)
{
    my ($self, $s) = @_;

    $self->send($s) || return;
    return $self->read_binary();
}

# Convert a numeric error into device-specific error string
# Expect ErrorStrings to be defined in the subclass
sub errorToString($$)
{
    my ($self, $error) = @_;

    return $self->{ErrorStrings}{$error} if exists $self->{ErrorStrings}{$error};
    return;
}

# Convert a numeric spoll result into device-specific error string
# Expect SpollStrings to be defined in the subclass
sub spollToString($$)
{
    my ($self, $spoll) = @_;

    # Mask out the BUSY bit:
    $spoll &= 0xf7;
    return $self->{SpollStrings}{$spoll} if exists $self->{SpollStrings}{$spoll};
    return;
}

# Send Group trigger to this device only
sub trigger()
{
    my ($self) = @_;

    $self->{Device}->trg($self->{Address});
}

# Set a new address to talk to
sub setAddress()
{
    my ($self, $address) = @_;

    $self->{Address} = $address;
}

# Return the device ID, or undef if nothing at the address
sub id($)
{
    my ($self) = @_;
    
    $self->{Id} = $self->sendAndRead('ID?');

    if (!$self->{Id})
    {
	warn "No GPIB device at address $self->{Address}";
	return;
    }
    return $self->{Id};
}

sub executeCommandsFromFiles($@)
{
    my ($self, @files) = @_;

    foreach my $file (@files)
    {
	#print "file $file\n";
	my $fh;
	open($fh, $file) || die "could not open command filename $file: $!\n";
	while (<$fh>)
	{
	    #	print "line $_\n";
	    chomp;
	    $self->executeCommand($_);
	}
	close($fh);
    }
}

# Execute an array of commands
sub executeCommands($@)
{
    my ($self, @commands) = @_;

    foreach (@commands)
    {
	$self->executeCommand($_);
    }
}

# Multiple semicolon sparated commands permitted
# Comamnds can begin with comment char # and are ignore
# Can end with a ? and query result is preinted to stdout
sub executeCommand()
{
    my ($self, $command) = @_;

    print "execute $command\n" if $main::opt_debug;
    return if (index($command, '#') == 0); # Comment
    return if length($command) == 0; # Empty
    
    if ($command =~ /query:(.*)/i)
    {
	# For commands that dont end in a ? but we still want to see the results eg from VREAD
	print $self->sendAndRead($1);
	print "\n";
    }
    elsif (index($command, '?') == (length($command) - 1))
    {
	print $self->sendAndRead($command);
	print "\n";
    }
    else
    {
	$self->send($command);
    }
}

1;
