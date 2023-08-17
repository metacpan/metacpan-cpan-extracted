# HP5342A.pm
# Perl module to control a HP 5342A Microwave Frequency Counter from perl
#
# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::HP::HP5342A;
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


### CAUTION:
# On some HP5342A, the GPIB board is not configured to enable SRQ. The W1 link is missing and must be soldered in.
# Its not even marked on the board and has to be found by belling out. It is near pin 13A on the edge connector.
# Without that link, SRQ is never asserted and this will hang forever.
###
sub waitSRQ()
{
    my ($self) = @_;
    
    while (1) # Caution, could block forever
    {
	if ($self->{Device}->srq())
	{
	    my @spoll = $self->spoll(); # Expect decimal 80 when data available
	    #print "GOT SPOLL @spoll\n";
	    return @spoll;
	}
    }
}


1;
