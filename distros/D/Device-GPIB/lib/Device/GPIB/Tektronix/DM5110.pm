# DM5110.pm
# Perl module to controla Tektronix DM5110 by GPIB
# Implements commands from https://w140.com/tek_dm5110_dm511_user.pdf

# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix::DM5110;
@ISA = qw(Device::GPIB::Tektronix);
use Device::GPIB::Tektronix;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    if ($self->id() !~ /TEK\/DM5110/)
    {
	warn "Not a Tek DM5110 at $self->{Address}: $self->{Id}";
	return;
    }
    # Device specific error and Spoll strings
    # from page 3-32
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
	232 => 'Null capabilities',
	260 => 'Cal locked',
	301 => 'Interrupt fault',
	302 => 'System error',
	401 => 'Power on',
	402 => 'Operation Complete',
	403 => 'User request',
	601 => 'Overrange error',
	701 => 'Below limits',
	703 => 'Above limits',
    };
    $self->{SpollStrings} = {
	0  => 'No errors or events',
	97 => 'Command error',
	98 => 'Execution error',
	99 => 'System error',
	65 => 'Power on',
	66 => 'Operation Complete',
	67 => 'User request',
	102 => 'Overrange error',
	193 => 'Below limits',
	195 => 'Above limits',
    };
    
    return $self;
}

sub setFunction($$)
{
    my ($self, $function) = @_;

    if ($function ne $self->{Function})
    {
	$self->send($function);
	$self->{Function} = $function; # Cache it for later
    }
    return 1;
}

# Front/rear
sub getSource($)
{
    my ($self) = @_;

    return $self->getGeneric('SOURCE');
}

sub setSource($$)
{
    my ($self, $source) = @_;

    if ($source =~ /rear/i)
    {
	$self->{Device}->send('SOURCE REAR');
    }
    else
    {
	$self->{Device}->send('SOURCE FRONT');
    }
    return 1;
}

sub getFunction($)
{
    my ($self) = @_;

    return $self->getGeneric('FUNC');
}

sub measure($$)
{
    my ($self, $function) = @_;

    # Change the function if necessary
    $self->setFunction($function) if defined $function;
    my $v = $self->sendAndRead('SEND');
    chop($v);
    return $v;
}

1;
