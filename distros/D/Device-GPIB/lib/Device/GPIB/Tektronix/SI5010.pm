# SI5010.pm
# Perl module to control a Tektronix SI5010 scanner
#
# Fast responses to reads requires the SI5010 to be configured for LF/EOI
# with GPIB configuraiotn switch at rear

# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix::SI5010;
@ISA = qw(Device::GPIB::Tektronix);
use Device::GPIB::Tektronix;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    if ($self->id() !~ /TEK\/SI5010/)
    {
	warn "Not a Tek SI5010 at $self->{Address}: $self->{Id}";
	return;
    }
    # Device specific error and Spoll strings
    # from page 5-1
    $self->{ErrorStrings} = {
	0   => 'No errors or events',
	101 => 'Command header error',
	102 => 'Header delimiter error',
	103 => 'Command argument error',
	104 => 'Argument delimiter error',
	105 => 'Nonnumeric argument (numeric expected)',
	106 => 'Missing argument',
	107 => 'Invalid message unit delimiter',
	203 => 'I/O buffers full, output dumped',
	204 => 'Settings conflict',
	205 => 'Argument out of range',
	206 => 'Group execute trigger ignored',
	341 => 'RAM error',
	361 => 'ROM error',
	401 => 'Power on',
	402 => 'Operation Complete',
	403 => 'User request',
	605 => 'Time-of-day clock no initialised and WAIT UNTI command was to be executed',
	741 => 'Cannot access PIAs with all 1s',
	742 => 'Cannot access PIAs with all 0s',
	791 => 'EXT TRIG ocurred under ARM SRQ or ARM ON status',
    };
    $self->{SpollStrings} = {
	0  => 'No errors or events',
	97 => 'Command error',
	98 => 'Execution error',
	99 => 'Internal error',
	65 => 'Power on',
	66 => 'Operation Complete',
	67 => 'User request',
	102 => 'Time-of-day clock no initialised and WAIT UNTI command was to be executed',
	225 => 'Cannot access PIAs',
	226 => 'Hardware errors on card in slot x',
	193 => 'EXT TRIG ocurred under ARM SRQ or ARM ON status',
    };
    
    return $self;
}

# INit the time-of-day clock
sub setLocalTime($$$)
{
    my ($self, $time, $hertz) = @_;

    $time = time() unless defined $time;
    my ($sec, $min, $hour) = localtime($time);
    my $cmd = sprintf("TIME %02d:%02d:%02d", $hour, $min, $sec);
    $cmd .= ",$hertz" if defined $hertz;
    $self->send($cmd);
}

sub getTime($)
{
    my ($self) = @_;

    my $time = $self->getGeneric('TIME');
    if ($time =~ /(.*),(.*)/)
    {
	return ($1, $2);
    }
    return; # Error
}

sub setUntil($$)
{
    my ($self, $time) = @_;

    $time = time() unless defined $time;
    my ($sec, $min, $hour) = localtime($time);
    my $cmd = sprintf("UNTI %02d:%02d:%02d", $hour, $min, $sec);
    $self->send($cmd);
}

sub getUntil($)
{
    my ($self) = @_;
    return $self->getGeneric('UNTI');
}

# Values TRIG, COND, UNTI, n
# n is number of seconds
sub setWait($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('WAI', $value);
}

sub getWait($)
{
    my ($self) = @_;

    return $self->getGeneric('WAI');
}

# Values ON, COND, SRQ, OFF
sub setArm($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('ARM', $value);
}

sub getArm($)
{
    my ($self) = @_;

    return $self->getGeneric('ARM');
}

# Set flag for wait command
sub setCond($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('COND', $value);
}

sub getCond($)
{
    my ($self) = @_;

    return $self->getGeneric('COND');
}

# Device Trigger setting SET or OFF
sub setDT($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('DT', $value);
}

sub getDT($)
{
    my ($self) = @_;

    return $self->getDT('COND');
}

# @conf is an array of 4 numbers totalling 16
sub setConf($@)
{
    my ($self, @conf) = @_;

    my $cmd = 'CONF ' . join(',', @conf);
    $self->send($cmd);
}

sub getConf($)
{
    my ($self) = @_;

    my $data = $self->getGeneric('CONF');
    return split(/,/, $data);
}

# array of relay numbers
sub setClosed($@)
{
    my ($self, @relays) = @_;

    my $cmd = 'CLO ' . join(',', @relays);
    $self->send($cmd);
}

sub getClosed($)
{
    my ($self) = @_;

    my $data = $self->getGeneric('CLO');
    return split(/,/, $data);
}

# array of relay numbers
sub setOpen($@)
{
    my ($self, @relays) = @_;

    my $cmd = 'OPE ' . join(',', @relays);
    $self->send($cmd);
}

sub getOpen($)
{
    my ($self) = @_;

    my $data = $self->getGeneric('OPE');
    return split(/,/, $data);
}

# array of relay numbers
sub setScan($@)
{
    my ($self, @relays) = @_;

    my $cmd = 'SCA ' . join(',', @relays);
    $self->send($cmd);
}

sub getScan($)
{
    my ($self) = @_;

    my $data = $self->getGeneric('SCA');
    return split(/,/, $data);
}

sub exec($$)
{
   my ($self, $count) = @_;

    $self->send("EXEC $count");
}

sub stop($)
{
   my ($self) = @_;

    $self->send('STOP');
}

sub trig($)
{
   my ($self) = @_;

    $self->send('TRIG');
}

# Next in SCA scanning sequence
sub next($)
{
   my ($self) = @_;

    $self->send('NEXT');
}



;
