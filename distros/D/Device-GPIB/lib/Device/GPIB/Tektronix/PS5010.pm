# PM5010.pm
# Perl module to control a Tektronix PM5010 by GPIB
# Implements commands from https://w140.com/tekwiki/images/e/e8/070-3391-00.pdf

# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix::PS5010;
@ISA = qw(Device::GPIB::Tektronix);
use Device::GPIB::Tektronix;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    if ($self->id() !~ /TEK\/PS5010/)
    {
	warn "Not a Tek PS5010 at $self->{Address}: $self->{Id}";
	return;
    }
    # Device specific error and Spoll strings
    # from page 3-21
    $self->{ErrorStrings} = {
	0   => 'No errors or events',
	101 => 'Command header error',
	102 => 'Header delimiter error',
	103 => 'Command argument error',
	104 => 'Argument delimiter error',
	105 => 'Nonnumeric argument (numeric expected)',
	106 => 'Missing argument',
	107 => 'Invalid message unit delimiter',
	108 => 'Binary block checksum error',
	109 => 'Binary block byte counter error',
	201 => 'Command not executable in local',
	202 => 'Settings lost due to "rtl"',
	203 => 'I/O buffers full, output dumped',
	205 => 'Argument out of range',
	206 => 'Group execute trigger ignored',
	301 => 'Interrupt fault',
	302 => 'System error',
	303 => 'Math pack error',
	401 => 'Power on',
	402 => 'Operation Complete',
	403 => 'User request',
	721 => 'Negative supply goes to contant voltage mode',
	722 => 'Negative supply goes to contant current mode',
	723 => 'Negative supply goes to unregulated mode',
	724 => 'Positive supply goes to contant voltage mode',
	725 => 'Positive supply goes to contant current mode',
	726 => 'Positive supply goes to unregulated mode',
	727 => 'Logic supply goes to contant voltage mode',
	728 => 'Logic supply goes to contant current mode',
	729 => 'Logic supply goes to unregulated mode',
    };
    $self->{SpollStrings} = {
	0  => 'No errors or events',
	97 => 'Command error',
	98 => 'Execution error',
	99 => 'Internal error',
	65 => 'Power on',
	66 => 'Operation Complete',
	67 => 'User request',
	197 => 'Negative supply goes to contant voltage mode',
	198 => 'Negative supply goes to contant current mode',
	199 => 'Negative supply goes to unregulated mode',
	201 => 'Positive supply goes to contant voltage mode',
	202 => 'Positive supply goes to contant current mode',
	203 => 'Positive supply goes to unregulated mode',
	205 => 'Logic supply goes to contant voltage mode',
	206 => 'Logic supply goes to contant current mode',
	207 => 'Logic supply goes to unregulated mode',
    };
    
    return $self;
}

sub setVPositive($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('VPOS', $value);
}

sub getVPositive($)
{
    my ($self) = @_;

    return $self->getGeneric('VPOS');
}

sub setIPositive($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('IPOS', $value);
}

sub getIPositive($)
{
    my ($self) = @_;

    return $self->getGeneric('IPOS');
}

sub setVNegative($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('VNEG', $value);
}

sub getVNegative($)
{
    my ($self) = @_;

    return $self->getGeneric('VNEG');
}

sub setINegative($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('INEG', $value);
}

sub getINegative($)
{
    my ($self) = @_;

    return $self->getGeneric('INEG');
}

sub setVLogic($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('VLOG', $value);
}

sub getVLogic($)
{
    my ($self) = @_;

    return $self->getGeneric('VLOG');
}

sub setILogic($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('ILOG', $value);
}

sub getILogic($)
{
    my ($self) = @_;

    return $self->getGeneric('ILOG');
}

sub setVTrack($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('VTRA', $value);
}

sub getVTrack($)
{
    my ($self) = @_;

    return $self->getGeneric('VTRA');
}

sub setITrack($$)
{
    my ($self, $value) = @_;

    return $self->setGeneric('ITRA', $value);
}

sub getITrack($)
{
    my ($self) = @_;

    return $self->getGeneric('ITRA');
}

sub output($$)
{
    my ($self, $value) = @_;

    if ($value)
    {
	$self->send('OUT ON');
    }
    else
    {
	$self->send('OUT OFF');
    }
    return;
}

sub on($)
{
    my ($self) = @_;

    return $self->output(1);
}

sub off($)
{
    my ($self) = @_;

    return $self->output(0);
}

1;
