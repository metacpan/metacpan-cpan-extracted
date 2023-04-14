# AFG5101.pm
# Perl module to control a Tektronix AFG5101 by GPIB
# Implements commands from https://w140.com/tekwiki/images/7/75/070-3888-00.pdf
#
# Fast responses to reads requires the AFG5101 to be configured for LF/EOI
# with front panel command SPCL 241 ENTER incr/decr ENTER

# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix::AFG5101;
@ISA = qw(Device::GPIB::Tektronix);
use Device::GPIB::Tektronix;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    if ($self->id() !~ /TEK\/AFG5101/)
    {
	warn "Not a Tek AFG5101 at $self->{Address}: $self->{Id}";
	return;
    }
    # Device specific error and Spoll strings
    # from page 3-40
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
	204 => 'Settings conflict',
	205 => 'Argument out of range',
	206 => 'Group execute trigger ignored',
	207 => 'ARB I-TRIG conflict',
	208 => 'SWEEP I-TRIG conflict',
	250 => 'AMPL-OFFSET conflict',
	251 => 'DATA out of range',
	253 => 'INCREMENT out of range',
	255 => 'Bad setting buffer',
	256 => 'ADDR out of range',
	261 => 'SWEEP operation error',
	262 => 'SYNT not installed',
	270 => 'NBURST out of range',
	271 => 'RATE out of range',
	272 => 'MARK out of range',
	273 => 'FREQ out of range',
	274 => 'AMPL out of range',
	275 => 'OFST  out of range',
	276 => 'START out of range',
	277 => 'STOP out of range',
	278 => 'ARBCLR start/stop out of range',
	280 => 'DC out of range',
	290 => 'SYNT illegal parameter',
	801 => 'Store binary block error',
	340 => 'SAve RAM failure',
	350 => 'SYNT out of lock',
	401 => 'Power on',
	402 => 'Operation Complete',
	403 => 'User request',
	650 => 'Low battery',
	660 => 'Output overload',
    };
    $self->{SpollStrings} = {
	0  => 'No errors or events',
	97 => 'Command error',
	98 => 'Execution error',
	99 => 'Internal error',
	65 => 'Power on',
	66 => 'Operation Complete',
	67 => 'User request',
	102 => 'Output overload',
    };
    
    return $self;
}

# Frequency can be in Hz, or followed by units:
# 1234
# 1.2:khz
# 11E6
# 60E2:HZ
sub setFrequency($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('FREQ', $value);
}

sub getFrequency($)
{
    my ($self) = @_;

    return $self->getGeneric('FREQ');
}

# Amplitude is in volts
sub setAmplitude($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('AMPL', $value);
}

sub getAmplitude($)
{
    my ($self) = @_;

    return $self->getGeneric('AMPL');
}

# mode can be CONT TRIG BURST GATE SYNT
sub setMode($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('MODE', $value);
}

sub getMode($)
{
    my ($self) = @_;

    return $self->getGeneric('MODE');
}

# Offset is in volts
sub setOffset($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('OFFS', $value);
}

sub getOffset($)
{
    my ($self) = @_;

    return $self->getGeneric('OFFS');
}

# 
sub setRate($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('RATE', $value);
}

sub getRate($)
{
    my ($self) = @_;

    return $self->getGeneric('RATE');
}

sub setNburst($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('NBURST', $value);
}

sub getNburst($)
{
    my ($self) = @_;

    return $self->getGeneric('NBURST');
}

# Trigger can be INT EXT MAN
sub setTrigger($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('TRIG', $value);
}

sub getTrigger($)
{
    my ($self) = @_;

    return $self->getGeneric('TRIG');
}

# Sweep can be LIN LOG IARB OFF
sub setSweep($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('SWEEP', $value);
}

sub getSweep($)
{
    my ($self) = @_;

    return $self->getGeneric('SWEEP');
}

# Offset is in volts
sub setDC($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('DC', $value);
}

sub getDC($)
{
    my ($self) = @_;

    return $self->getGeneric('DC');
}

sub setFunction($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('FUNC', $value);
}

sub getFunction($)
{
    my ($self) = @_;

    return $self->getGeneric('FUNC');
}


sub setFrqmark($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('FRQMARK', $value);
}

sub getFrqmark($)
{
    my ($self) = @_;

    return $self->getGeneric('FRQMARK');
}
sub setFrqstart($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('FRQSTART', $value);
}

sub getFrqstart($)
{
    my ($self) = @_;

    return $self->getGeneric('FRQSTART');
}
sub setFrqstop($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('FRQSTOP', $value);
}

sub getFrqstop($)
{
    my ($self) = @_;

    return $self->getGeneric('FRQSTOP');
}

sub setAM($$)
{
    my ($self, $value) = @_;

    $self->send($value ? 'AM ON' : 'AM OFF');
}

sub getAM($)
{
    my ($self) = @_;

    return $self->getGeneric('AM');
}

sub setFM($$)
{
    my ($self, $value) = @_;

    $self->send($value ? 'FM ON' : 'FM OFF');
}

sub getFM($)
{
    my ($self) = @_;

    return $self->getGeneric('FM');
}

sub setOutput($)
{
    my ($self, $state) = @_;

    if ($state > 0)
    {
	$self->send('OUT ON');
    }
    elsif ($state < 0)
    {
	$self->send('OUT FLOAT');
    }
    else
    {
	$self->send('OUT OFF');
    }
}

# Reads all the arb data (or 
sub arbRead($$$)
{
    my ($self, $banknum, $points, $startpoint) = @_;

    $points = 8192 unless defined $points;
    $startpoint = 0 unless defined $startpoint;
    return unless $banknum == 1 or $banknum == 2;

    $self->send("ARBSEL $banknum");
    $self->send("ARBADRS $startpoint");
    my $data = $self->sendAndRead("ARBDATA? $points:A"); # Getting in ASCII
    if ($data =~ /ARBDATA (.+);/)
    {
	# Return an array of integers
	return (split(/,/, $1));
    }
    return; # Something wrong
    
}

sub arbWrite($$@)
{
    my ($self, $banknum, @data) = @_;

    return unless $banknum == 1 or $banknum == 2;

    $self->send("ARBSEL $banknum;ARBCLR ALL;ARBADRS 0");
    $self->send('ARBDATA ' . join(',', @data));
    return scalar @data; # Number of points we sent
}
	      
1;
