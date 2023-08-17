# HP3456A.pm
# Perl module to control a HP 3456A precision voltmeter from perl
# For fast response Requires EOI set with GPIB command '01'
#
# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::HP::HP3456A;
@ISA = qw(Device::GPIB::Generic);
use Device::GPIB::Generic;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    # Hmmm, no ID support in this device?
    return $self
}

# Set the measuring function
# Valid function names are:
# SHIFT 0:              
# DCV                   
# ACV                   
# ACV+DCV               
# 2 wire K Ohms         
# 4 wire K ohms         
# SHIFT 1:                      
# DCV/ACV Ratio         
# ACV/DCV Ratio         
# ACV + DCV/DCV Ratio   
# O.C 2 wire K ohms     
# O.C 4 wire K ohms     
my %functionNames = (
    'DCV'         => 'S0F1',
    'ACV'         => 'S0F2',
    'ACV+DCV'     => 'S0F3',
    '2WOHMS'      => 'S0F4',
    '4WOHMS'      => 'S0F5',
    'DCV/ACV'     => 'S1F1',
    'ACV/DCV'     => 'S1F2',
    'ACV+DCV/DCV' => 'S1F3',
    'OC2WOHMS'    => 'S1F4',
    'OC4WOHMS'    => 'S1F5',
);

sub setFunction($$)
{
    my ($self, $function) = @_;

    $function = uc($function);
    if (exists $functionNames{$function})
    {
	if ($function ne $self->{Function})
	{
	    $self->send($functionNames{$function});
	    $self->{Function} = $function; # Cache it for later
	}
	return 1;
    }
    else
    {
	warn "Invalid function name in setFunction: $function\n";
	return;
    }
}

sub getFunction($)
{
    my ($self) = @_;

    # Cant query this from the HP
    return $self->{Function};
}

# Set the range
# Valid range names are:
# Auto
# 100mV or .1KOhms
# 1000mV or 1KOhms
# 10V or 10KOhms
# 100V or 100KOhms
# 1000V or 1MOhms
# 10MOhms
# 100MOhms
# 1000MOhms
my %rangeNames = (
    'AUTO'      => 'R1',
    '100MV'     => 'R2', # Thats really mV
    '1000MV'    => 'R3', # Thats really mV
    '1V'        => 'R3',
    '10V'       => 'R4',
    '100V'      => 'R5',
    '1000V'     => 'R6',
    '100OHMS'   => 'R1',
    '.1KOHMS'   => 'R1',
    '1KOHMS'    => 'R2',
    '10KOHMS'   => 'R3',
    '1MOHMS'    => 'R4',
    '10MOHMS'   => 'R5',
    '100MOHMS'  => 'R7',
    '1000MOHMS' => 'R7',
    );

sub setRange($$)
{
    my ($self, $range) = @_;

    $range = uc($range);
    if (exists $rangeNames{$range})
    {
	if ($range ne $self->{Range})
	{
	    $self->send($rangeNames{$range});
	    $self->{Range} = $range; # Cache it for later
	}
	return 1;
    }
    else
    {
	warn "Invalid range name in setRange: $range\n";
	return;
    }
}

sub getRange($)
{
    my ($self) = @_;

    # Cant query this from the HP
    return $self->{Range};
}

# Set the trigger type
# Valid range names are:
# Internal
# External
# Single
# Hold
my %triggerNames = (
    'INTERNAL'  => 'T1',
    'EXTERNAL'  => 'T2',
    'SINGLE'    => 'T3',
    'HOLD'      => 'T4',
    );

sub setTrigger($$)
{
    my ($self, $trigger) = @_;

    $trigger = uc($trigger);
    if (exists $triggerNames{$trigger})
    {
	if ($trigger ne $self->{Trigger})
	{
	    $self->send($triggerNames{$trigger});
	    $self->{Trigger} = $trigger; # Cache it for later
	}
	return 1;
    }
    else
    {
	warn "Invalid trigger name in setTrigger: $trigger\n";
	return;
    }
}

sub getTrigger($)
{
    my ($self) = @_;

    # Cant query this from the HP
    return $self->{Trigger};
}

sub setAutozero($$)
{
    my ($self, $value) = @_;

    $self->send($value ? 'Z1' : 'Z0');
}

sub setFilter($$)
{
    my ($self, $value) = @_;

    $self->send($value ? 'FL1' : 'FL0');
}

sub setTest($$)
{
    my ($self, $value) = @_;

    $self->send($value ? 'TE1' : 'TE0');
}

# Returns true if the Terminals switch is set to FRONT
sub getFront($$)
{
    my ($self, $value) = @_;

    $self->send('SW1');
    my $v = $self->read();
    return $v eq '1';
}

sub setPowerlineCycles($$)
{
    my ($self, $value) = @_;

    $self->send("${value}STI");
}

sub setDigitsDisplayed($$)
{
    my ($self, $value) = @_;

    if ($value >= 3 && $value <= 6)
    {
	$self->send("${value}STG");
	return 1;
    }
    else
    {
	warn "Digits out of range in setDigitsDisplayed: $value";
	return;
    }
}

# Sigh: there appears to be no way to detect data ready in INTERNAL trigger mode
# so we might get empty reading if data is not ready with the timeout period.
sub measure($$)
{
    my ($self, $function) = @_;

    # Change the function if necessary
    $self->setFunction($function) if defined $function;
    my $v = $self->read();
    chop($v);
    return $v;
}


sub waitFrontPanelSRQ()
{
    my ($self) = @_;
    
    $self->send('SM004'); # Front panel SRQ mask
    $self->{Device}->loc(); # Back to local mode else cant press SRQ!
    while (1) # Caution, could block forever
    {
	if ($self->{Device}->srq())
	{
	    my @spoll = $self->spoll();
	    print "GOT @spoll\n";
	    return @spoll;
	}
    }
}

# Mask is the OCTAL status bts mask per table 3-7
sub waitSRQ()
{
    my ($self, $mask) = @_;
    
    $self->send("SM$mask"); # SRQ mask
#    $self->{Device}->loc(); # Back to local mode else cant press SRQ!
    while (1) # Caution, could block forever
    {
	if ($self->{Device}->srq())
	{
	    my @spoll = $self->spoll();
	    #print "GOT SPOLL @spoll\n";
	    return @spoll;
	}
    }
}

# Caution, the HP must be set to LOCAL mode after this, else cant press the SRQ button!
sub waitFrontPanelSRQ()
{
     my ($self) = @_;

     return $self->waitSRQ('001');
}

# This will only work if not continuously triggered, otherwise the SRQ is never asserted.
# eg EXTERNAL or SINGLE trigger (in local mode)
sub waitDataReadySRQ()
{
     my ($self) = @_;

     return $self->waitSRQ('004');
}

1;
