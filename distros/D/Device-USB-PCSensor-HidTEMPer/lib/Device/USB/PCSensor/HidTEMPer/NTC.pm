package Device::USB::PCSensor::HidTEMPer::NTC;

use strict;
use warnings;

use Device::USB::PCSensor::HidTEMPer::Device;
use Device::USB::PCSensor::HidTEMPer::NTC::Internal;
use Device::USB::PCSensor::HidTEMPer::NTC::External;
our @ISA = 'Device::USB::PCSensor::HidTEMPer::Device';

=head1

Device::USB::PCSensor::HidTEMPer::NTC - The HidTEMPerNTC thermometer

=head1 VERSION

Version 0.03

=cut

our $VERSION = 0.03;

=head1 SYNOPSIS

None

=head1 DESCRIPTION

This is the implementation of the HidTEMPerNTC thermometer that has both one 
internal and one external sensor measuring the temperature.

=head2 CONSTANTS

None

=head2 METHODS

=over 3

=item * init()

Initialize the device, connects the sensors and makes the object ready 
for use.

=cut

sub init
{
    my $self = shift;
    
    # Add sensor references to this instance
    $self->{sensor}->{internal} = Device::USB::PCSensor::HidTEMPer::NTC::Internal->new( $self );
    $self->{sensor}->{external} = Device::USB::PCSensor::HidTEMPer::NTC::External->new( $self );

    # Set configuration
    $self->_write(0x43);
    
    # Rebless
    bless $self, 'Device::USB::PCSensor::HidTEMPer::NTC';
}

sub DESTROY
{
    $_[0]->SUPER::DESTROY;
}

=back

=head1 INHERIT METHODS FROM

Device::USB::PCSensor::HidTEMPer::Device

=head1 DEPENDENCIES

This module internally includes and takes use of the following packages:

  use Device::USB::PCSensor::HidTEMPer::Device;
  use Device::USB::PCSensor::HidTEMPer::NTC::Internal;
  use Device::USB::PCSensor::HidTEMPer::NTC::External;

This module uses the strict and warning pragmas. 

=head1 BUGS

Please report any bugs or missing features using the CPAN RT tool.

=head1 FOR MORE INFORMATION

None

=head1 AUTHOR

Magnus Sulland < msulland@cpan.org >

=head1 ACKNOWLEDGEMENTS

Thanks to Jeremy G for the fix on initializing the device configuration.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2011 Magnus Sulland

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
