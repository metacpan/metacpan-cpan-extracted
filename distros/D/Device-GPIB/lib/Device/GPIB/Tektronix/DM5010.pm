# DM5010.pm
# Perl module to controla Tektronix DM5010 by GPIB
# Implements commands from https://w140.com/tek_dm5010_dm511_user.pdf
# For fast responses, LF/EOI switch on CPU board on left side of instrument must be set to LF/EOI
#
# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix::DM5010;
@ISA = qw(Device::GPIB::Tektronix);
use Device::GPIB::Tektronix;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    if ($self->id() !~ /TEK\/DM5010/)
    {
	warn "Not a Tek DM5010 at $self->{Address}: $self->{Id}";
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
	231 => 'Not in calibrate mode',
	232 => 'Null capabilities',
	301 => 'Interrupt fault',
	302 => 'System error',
	303 => 'Math pack error',
	311 => 'Converter timeout',
	317 => 'Front panel timeout',
	318 => 'Bad ohms calibration constant',
	351 => 'Calibration checksum error',
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
	132 => 'Reading available',
	136 => 'Waiting for trigger',
	140 => 'Reading available and Waiting for trigger',
	128 => 'No errors or events',
	193 => 'Below limits',
	195 => 'Above limits',
    };
    
    return $self;
}

# Function can be ACV, DCV, ACDC, DIODE, OHMS
# Range can include units
# No range means auto
sub setFunction($$$)
{
    my ($self, $function, $range) = @_;

    if ($function ne $self->{Function} || $range ne $self->{Range})
    {
	$function .= " $range" if defined $range;

	$self->send($function);
    	$self->{Function} = $function; # Cache it for later
	$self->{Range}    = $range; # Cache it for later
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

sub null($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('NULL', $value);
}

# MODE can be RUN, TRIG
sub setMode($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('MODE', $value);
}

sub getMode($)
{
    my ($self) = @_;

    return $self->getGeneric('MODE');
}

# CALC can be AVE or AVG, CMPR or COMP, DBM, DBR, RATIO, OFF
sub setCalc($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('CALC', $value);
}

sub getCalc($)
{
    my ($self) = @_;

    return $self->getGeneric('CALC');
}

sub setOverrange($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('OVER', $value ? 'ON' : 'OFF');
}

sub getOverrange($)
{
    my ($self) = @_;

    return $self->getGeneric('OVER');
}

sub getReady($)
{
    my ($self) = @_;

    return $self->getGeneric('RDY');
}

sub setRatio($$$)
{
    my ($self, $scale, $offset) = @_;

    return $self->setGeneric('RATIO', "$scale,$offset");
}


sub measure($$$)
{
    my ($self, $function, $range) = @_;

    # Change the function if necessary
    $self->setFunction($function, $range) if defined $function;
    my $v = $self->sendAndRead('DATA');
    chop($v);
    return $v;
}

1;
