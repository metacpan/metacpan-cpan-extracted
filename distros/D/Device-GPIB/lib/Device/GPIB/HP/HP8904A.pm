# HP3456A.pm
# Perl module to control a HP 8904A Multifunction Synthesizer from perl
#
# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::HP::HP8904A;
@ISA = qw(Device::GPIB::Generic);
use Device::GPIB::Generic;
use strict;

# Status byte and Service Mask definitions for use with
# waitSRQ and spoll
use constant "Device::GPIB::HP::HP8904A::STATUS_MASK_INVALID_COMMAND"     => 0x01;
use constant "Device::GPIB::HP::HP8904A::STATUS_MASK_TIMEBASE_NOT_LOCKED" => 0x02;
use constant "Device::GPIB::HP::HP8904A::STATUS_MASK_SIGNALLING_START"    => 0x04;
use constant "Device::GPIB::HP::HP8904A::STATUS_MASK_SIGNALLING_STOP"     => 0x08;
use constant "Device::GPIB::HP::HP8904A::STATUS_MASK_REVERSE_POWER"       => 0x10;
use constant "Device::GPIB::HP::HP8904A::STATUS_MASK_RQS"                 => 0x40;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    # Hmmm, no ID support in this device?
    return $self
}


# Mask is the OCTAL status bts mask per table 3-7
sub waitSRQ()
{
    my ($self, $mask) = @_;

    print "mask $mask\n";
    $self->send("SM$mask"); # SRQ mask
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


1;
