# Tektronix.pm
# Superclass for a range of tektronix GPIB devices
# Implements many commands common to Tek instruments
# Subclass in tektronix director

# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Tektronix;
@ISA = qw(Device::GPIB::Generic);
use Device::GPIB::Generic;
use strict;


sub getError($)
{
    my ($self) = @_;
    return $self->getGeneric('ERR');
}

# Get all errors until 0 and return as an array
sub getErrors($)
{
    my ($self) = @_;

    my @ret;
    while (1)
    {
	my $error = $self->getGeneric('ERR');
	return @ret if $error == 0;
	push(@ret, $error);
    }
}

sub getErrorsAsStrings($)
{
    my ($self) = @_;

    my @errors = $self->getErrors();
    return map $self->errorToString($_), @errors;
}


# Generic code to set any simple value via a setting command
sub setGeneric($$$)
{
    my ($self, $name, $value) = @_;

    $self->send("$name $value");
    return;
}

sub getGeneric($$)
{
    my ($self, $name) = @_;

    my $ret;
    my $f = $self->sendAndRead("$name?"); # Result is eg 'VPOS 1.23'
    if ($f =~ /$name\s+(.+);/) # Can be a varying number of spaces after the query name
    {
	$ret = $1;
    }
    return $ret;
}

# Run self test
sub test($)
{
    my ($self) = @_;

    return $self->getGeneric('TEST');
}

# Send device ini for power on conditions:
sub init($)
{
    my ($self) = @_;
    
    $self->send('INI');
}


1;
