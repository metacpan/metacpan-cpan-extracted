# DC5009.pm
# Perl module to control a Tektronix DC5009 by GPIB
# Implements commands from https://w140.com/tekwiki/images/7/75/070-3888-00.pdf
#
# Fast responses to reads requires the DC5009 to be configured for LF/EOI
# with internal GPIB switch 1, so the DC5009 asserts EOI at the end of each message
# See Maintenance: GPIB SWITCH in the service manual.

# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix::DC5009;
@ISA = qw(Device::GPIB::Tektronix);
use Device::GPIB::Tektronix;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    if ($self->id() !~ /TEK\/DC5009/)
    {
	warn "Not a Tek DC5009 at $self->{Address}: $self->{Id}";
	return;
    }
    # Device specific error and Spoll strings
    # from page 2-43
    $self->{ErrorStrings} = {
	0   => 'No errors or events',
	101 => 'Command header error',
	102 => 'Header delimiter error',
	103 => 'Command argument error',
	104 => 'Argument delimiter error',
	105 => 'Nonnumeric argument (numeric expected)',
	106 => 'Missing argument',
	107 => 'Invalid message unit delimiter',
	201 => 'Command not executable in local',
	202 => 'Settings lost due to "rtl"',
	203 => 'I/O buffers full, output dumped',
	205 => 'Argument out of range',
	206 => 'Group execute trigger ignored',
	301 => 'Interrupt fault',
	302 => 'System error',
	401 => 'Power on',
	402 => 'Operation Complete',
	403 => 'User request',
	602 => 'Channel A 50 ohm protect',
	603 => 'Channel B 50 ohm protect',
	604 => 'No prescaler',
	711 => 'Channel A overflow',
	712 => 'Channel B overflow',
    };
    $self->{SpollStrings} = {
	0  => 'No errors or events',
	97 => 'Command error',
	98 => 'Execution error',
	99 => 'Internal error',
	65 => 'Power on',
	66 => 'Operation Complete',
	67 => 'User request',
	102 => 'No prescaler',
	193 => 'Channel A overflow',
	194 => 'Channel B overflow',
    };

    return $self;
}

# Read value from the device and remove leading space and trailing ;
sub readResult($)
{
    my ($self) = @_;

    my $value = $self->read(); # Leading space and trailing ;
    $value =~ / (.+);/;
    return $1;
}

# Read frequency from channel A
sub frequency($)
{
    my ($self) = @_;
    
    $self->send('FREQ');
    while ($self->getGeneric('RDY') == 0) {} # Wait for RDY
    $self->send('SEND');
    return $self->readResult();
}

# Read period from channel A
sub period($)
{
    my ($self) = @_;
    
    $self->send('PER');
    while ($self->getGeneric('RDY') == 0) {} # Wait for RDY
    $self->send('SEND');
    return $self->readResult();
}

# Read ration of events on channel B to events on channel A
sub ratio($)
{
    my ($self) = @_;
    
    $self->send('RAT');
    while ($self->getGeneric('RDY') == 0) {} # Wait for RDY
    $self->send('SEND');
    return $self->readResult();
}

# Read time interval from first event on A to succeeding event on B
sub time($)
{
    my ($self) = @_;
    
    $self->send('TIME');
    while ($self->getGeneric('RDY') == 0) {} # Wait for RDY
    $self->send('SEND');
    return $self->readResult();
}

# Read pulse width on channel A
sub width($)
{
    my ($self) = @_;
    
    $self->send('WID');
    while ($self->getGeneric('RDY') == 0) {} # Wait for RDY
    $self->send('SEND');
    return $self->readResult();
}

# Start counting total events on channel A
sub totalize($)
{
    my ($self) = @_;
    
    $self->send('TOT');
    return $self->readResult();
}

sub tmanual($)
{
    my ($self) = @_;
    
    $self->send('TMAN');
}

# Return try if instrumnet is ready
sub ready($)
{
    my ($self) = @_;
    
    return int($self->getGeneric('RDY'));
}
    
sub stop($)
{
    my ($self) = @_;
    
    $self->send('STOP');
}

sub start($)
{
    my ($self) = @_;
    
    $self->send('START');
}

sub reset($)
{
    my ($self) = @_;
    
    $self->send('RES');
}


1;
