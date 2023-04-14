# PFG5105.pm
# Perl module to control a Tektronix PFG5105 by GPIB
#
# Very similar to AFG5101, this module based on AFG5101.pm
# Fast responses to reads requires the PFG5105 to be configured for LF/EOI
# with front panel command SPCL 241 ENTER incr/decr ENTER

# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix::PFG5105;
@ISA = qw(Device::GPIB::Tektronix);
use Device::GPIB::Tektronix;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    if ($self->id() !~ /TEK\/PFG5105/)
    {
	warn "Not a Tek PFG5105 at $self->{Address}: $self->{Id}";
	return;
    }
    # Device specific error and Spoll strings
    # from page 3-31
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
	250 => 'AMPL-OFFSET conflict',
	251 => 'DATA out of range',
	255 => 'Bad setting buffer',
	256 => 'ADDR out of range',
	261 => 'SWEEP operation error',
	262 => 'SYNT not installed',
	263 => 'Pulse error',
	270 => 'NBURST out of range',
	271 => 'RATE out of range',
	272 => 'MARK out of range',
	273 => 'FREQ out of range',
	274 => 'AMPL out of range',
	275 => 'OFST  out of range',
	276 => 'START out of range',
	277 => 'STOP out of range',
	280 => 'DC out of range',
	281 => 'WIDTH out of range',
	282 => 'DELAY out of range',
	283 => 'W + D > 0,85 P',
	284 => 'P - (W + D) <= 40ns',
	285 => 'D <= W',
	286 => 'D <= W + NI',
	290 => 'SYNT illegal parameter',
	340 => 'Save RAM failure',
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

# Period can be in s, or followed by units:
# 10
# 5:MS
# 5E-3
sub setPeriod($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('PERIOD', $value);
}

sub getPeriod($)
{
    my ($self) = @_;

    return $self->getGeneric('PERIOD');
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

# Sweep can be ON OFF
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

# Prelevl is one of TTL CMOS ECL
sub setPrelevel($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('PRELEVEL', $value);
}

sub getPrelevel($)
{
    my ($self) = @_;

    return $self->getGeneric('PRELEVEL');
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

# Delay time from trigger to first pulse (single pulse mode)
# or delay between firstand second pulse in double pulse mode
# 40:ns
# 90:ms
# 100E-9
sub setDelay($$)
{
    my ($self, $value) = @_;

    $self->setGeneric('DELAY', $value);
}

# Manual says this is not supported but it is in my device
sub getDelay($)
{
    my ($self) = @_;

    return $self->getGeneric('DELAY');
}

# Duty cycle in % between 10 and 85
sub setDcycle($$)
{
    my ($self, $value) = @_;
    $self->setGeneric('DCYCLE', $value);
}

sub getDcycle($)
{
    my ($self) = @_;

    return $self->getGeneric('DCYCLE');
}

# pulse width default unit is seconds
# 40 ns to 99.9 ms
sub setWidth($$)
{
    my ($self, $value) = @_;
    $self->setGeneric('WIDTH', $value);
}

sub getWidth($)
{
    my ($self) = @_;

    return $self->getGeneric('WIDTH');
}

# one of TRIG GATE SET OFF
sub setDeviceTrigger($$)
{
    my ($self, $value) = @_;
    $self->setGeneric('DT', $value);
}

sub getDeviceTrigger($)
{
    my ($self) = @_;

    return $self->getGeneric('DT');
}

    
1;
