package Device::USB::PCSensor::HidTEMPer::TEMPer;

use strict;
use warnings;

use Device::USB::PCSensor::HidTEMPer::Device;
use Device::USB::PCSensor::HidTEMPer::TEMPer::Internal;
our @ISA = 'Device::USB::PCSensor::HidTEMPer::Device';

=head1

Device::USB::PCSensor::HidTEMPer::TEMPer - The HidTEMPer thermometer

=head1 VERSION

Version 0.03

=cut

our $VERSION = 0.03;

=head1 SYNOPSIS

None

=head1 DESCRIPTION

This is the implementation of the HidTEMPer thermometer that have only 
one internal sensor measuring the temperature. It is important to notice
that the TEMPer device with one external sensor will not function,
although being recognized correctly.

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
    $self->{sensor}->{internal} = Device::USB::PCSensor::HidTEMPer::TEMPer::Internal->new( $self );    

    # Set configuration
    $self->_write(0x43);

    # Rebless
    bless $self, 'Device::USB::PCSensor::HidTEMPer::TEMPer';
}

sub DESTROY
{
    $_[0]->SUPER::DESTROY();
}

=back

=head1 INHERIT METHODS FROM

Device::USB::PCSensor::HidTEMPer::Device

=head1 DEPENDENCIES

This module internally includes and takes use of the following packages:

  use Device::USB::PCSensor::HidTEMPer::Device;
  use Device::USB::PCSensor::HidTEMPer::TEMPer::Internal;

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
