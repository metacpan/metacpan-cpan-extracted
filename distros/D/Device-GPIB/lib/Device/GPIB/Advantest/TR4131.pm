# TR4131.pm
# Perl module to control Advantest TR4131 series Spectrum Analyser
# Implements commands from https://www.advantest.com/global-services/ps/electronic-measuring/pdf/pdf_mn_ER4131_OPERATING_MANUAL.pdf

# Author: Mike McCauley (mikem@airspayce.com),
# Copyright (C) AirSpayce Pty Ltd
# $Id: $

package Device::GPIB::Advantest::TR4131;
@ISA = qw(Device::GPIB::Generic);
use Device::GPIB::Generic;
use strict;

sub new($$$)
{
    my ($class, $device, $address) = @_;

    my $self = $class->SUPER::new($device, $address);

    # Hmm does not seem to implement an ID command :-(
    return $self;
}

# Read the trace data in binary format
# Return as an array of 701 16 bit integers
# range is 70 to 470 full scale
# from screen of height 0 to 511
sub readData($)
{
    my ($self) = @_;

    my $data = $self->sendAndRead('OPTBW'); # Read 701 data points in 1402 bytes
    die "Could not read screen data" unless defined $data;
    my $length = length($data);
    die "Screen data wrong length $length" unless $length == 1402;
    my @decoded = unpack("n701", $data);
    return @decoded;
}

1;
