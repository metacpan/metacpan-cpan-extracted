package Device::USB::PCSensor::HidTEMPer;

use strict;
use warnings;

use Device::USB;
use Device::USB::PCSensor::HidTEMPer::Device;
use Device::USB::PCSensor::HidTEMPer::NTC;
use Device::USB::PCSensor::HidTEMPer::TEMPer;
use Device::USB::PCSensor::HidTEMPer::TEMPer2;

=head1 NAME

Device::USB::PCSensor::HidTEMPer - Device overview

=head1 VERSION

Version 0.04

=cut

our $VERSION = 0.04;

=head1 SYNOPSIS

Shared code:

  use Device::USB::PCSensor::HidTEMPer;
  my $pcsensor = Device::USB::PCSensor::HidTEMPer->new();

Single-device systems:

  my $device = $pcsensor->device();
  print $device->external()->fahrenheit() if defined $device->external();
  
Multi-device systems:

  my @devices = $pcsensor->list_devices();

  foreach my $device ( @devices ){
    print $device->internal()->celsius() if defined $device->internal();
  }

=head1 DESCRIPTION

This module is a simplified interface to the HidTEMPer thermometers created 
by PCSensor. It hides any problems recognizing the correct objects to 
initialize and the dependency on Device::USB. Use of the connected 
thermometers can be done by either creating a array of objects if 
multiple devices are connected, or the function device() if 
only one device is present.

One example of its usage can be found in the Linux Journal August 2010, 
"Cool Projects edition" page 32-34.

=head2 CONSTANTS

The following constants are declared

=over 3

=item * PRODUCT_ID

Contains the hex value of the product id on the usb chip, in this case 0x660c

=cut

use constant PRODUCT_ID => 0x660c; 

=item * VENDOR_ID

Contains the hex value representing the manufacturer of the chip, in this
case "Tenx Technology, Inc."

=cut

use constant VENDOR_ID => 0x1130;

=item * SUPPORTED_DEVICES

Contains the mapping between name and identifiers for all supported 
thermometers.

 Hex value   Product         Internal sensor    External sensor
 0x5b        HidTEMPerNTC    Yes                Yes
 0x58        HidTEMPer       Yes                No
 0x59        HidTEMPer2      Yes                Yes

=back

=cut

use constant SUPPORTED_DEVICES => {
    0x5b    => {
        'name'      => 'HidTEMPerNTC',
        'module'    => 'Device::USB::PCSensor::HidTEMPer::NTC'
    },
    0x58    => {
        'name'      => 'HidTEMPer',
        'module'    => 'Device::USB::PCSensor::HidTEMPer::TEMPer'
    },
    0x59    => {
        'name'      => 'HidTEMPer2',
        'module'    => 'Device::USB::PCSensor::HidTEMPer::TEMPer2'
    }
};

=head2 METHODS

=over 3

=item * new()

Initialize the system, and the USB-connection to be used.

=cut

sub new
{
    my $class   = shift;
    my $self    = {
        'usb'   => Device::USB->new()
    };

    return bless $self, $class;
}

=item * device()

Return a single thermometer instance. ONLY to be used in systems using a 
single thermometer device. Returns undef if no devices was found.

=cut

sub device
{
    my $self    = shift;
    my $device  = $self->{usb}->find_device( VENDOR_ID, PRODUCT_ID );

    return undef unless defined $device;
    return _init_device($device);
}

=item * list_devices()

Returns an array of recognized thermometer instances if an array value is 
expected, otherwise it returns a scalar with the number of devices found.

=cut

sub list_devices
{
    my $self    = shift;
    my @list    = ();

    @list = grep( defined($_), 
                  map( _init_device($_), 
                       $self->{usb}->list_devices( VENDOR_ID, 
                                                   PRODUCT_ID )));

    return wantarray() ? return @list : scalar @list;
}

# This functions detects the correct object to be created and returned. 
# Returns undef if not supported device was found.
sub _init_device
{
    my $prototype   = Device::USB::PCSensor::HidTEMPer::Device->new( $_[0] );
    my $parameters  = SUPPORTED_DEVICES->{$prototype->identifier()};
    
    return undef unless defined $parameters;
    
    bless $prototype, $parameters->{module};
    return $prototype->init();
}

=back

=head1 DEPENDENCIES

This module internally includes and takes use of the following packages:

 use Device::USB;
 use Device::USB::PCSensor::HidTEMPer::Device;
 use Device::USB::PCSensor::HidTEMPer::NTC;
 use Device::USB::PCSensor::HidTEMPer::TEMPer;
 use Device::USB::PCSensor::HidTEMPer::TEMPer2;

This module uses the strict and warning pragmas. 

=head1 BUGS

Please report any bugs or missing features using the CPAN RT tool.

=head1 FOR MORE INFORMATION

None

=head1 AUTHOR

Magnus Sulland < msulland@cpan.org >

=head1 ACKNOWLEDGEMENTS

Thanks to Elan Ruusamäe for fixing some compatibility issues with perl 5.8.

Thanks to Daniel Fahlgren for adding the TEMPer2 device.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2011 Magnus Sulland

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
