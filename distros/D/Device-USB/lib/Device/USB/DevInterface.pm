package Device::USB::DevInterface;

require 5.006;
use warnings;
use strict;
use Carp;

=encoding utf8

=head1 Device::USB::DevInterface

This class encapsulates a USB Device Interface and the methods that object
would support.

=head1 NAME

Device::USB::DevInterface - Access a device interface returned by libusb.

=head1 VERSION

Version 0.38

=cut

our $VERSION=0.38;

=head1 SYNOPSIS

Device::USB:DevInterface provides a Perl object for accessing an
interface of a configuration of a USB device using the libusb library.

    use Device::USB;

    my $usb = Device::USB->new();
    my $dev = $usb->find_device( $VENDOR, $PRODUCT );

    printf "Device: %04X:%04X\n", $dev->idVendor(), $dev->idProduct();
    $dev->open();

    my $cfg = $dev->config()->[0];
    my $inter = $cfg->interfaces()->[0];
    print "Interface:", $inter->bInterfaceNumber(),
       " name: ", $dev->get_string_simple($iter->iInterface()), 
       ": endpoint count: ", $inter->nNumEndpoints(), "\n";

See USB specification for an explanation of the attributes of an
interface.

=head1 DESCRIPTION

This module defines a Perl object that represents the data associated with
a USB device configuration's interface. The object provides read-only access
to the important data associated with the interface.

=head2 METHODS

There are several accessor methods that return data from the interface.
Each is named after the field that they return. These accessors include:

=cut

# I need to build a lot of accessors
sub _make_descr_accessor
{
    my $name = shift;
    ## no critic (ProhibitStringyEval)

    return eval <<"EOE";
sub $name
        {
            my \$self = shift;
            return \$self->{$name};
        }
EOE
}

=over 4

=item bInterfaceNumber

The 0-based number of this interface.

=item bAlternateSetting

Value used to select this alternate setting for the interface specified
in bInterfaceNumber.

=item bNumEndpoints

Number of endpoints (excluding endpoint 0) available on this interface.
If the value  is 0, only the control interface is supported.

=item bInterfaceClass

Class code as specified by the USB-IF. A value of 0xff is a vendor-specific
interface class.

=item bInterfaceSubClass

Subclass code specified by the USB-IF. If bInterfaceClass is not 0xff,
this field must use only subclasses specified by the USB-IF.

=item bInterfaceProtocol

The InterfaceProtocol as specified by the USB-IF. A value of 0xff uses
a vendor-specific protocol.

=item iInterface

Returns the index of the string descriptor describing this interface.
The string can be retrieved using the method
C<Device::USB::Device::get_string_simple>.

=cut

_make_descr_accessor( 'bInterfaceNumber' );
_make_descr_accessor( 'bAlternateSetting' );
_make_descr_accessor( 'bNumEndpoints' );
_make_descr_accessor( 'bInterfaceClass' );
_make_descr_accessor( 'bInterfaceSubClass' );
_make_descr_accessor( 'bInterfaceProtocol' );
_make_descr_accessor( 'iInterface' );

=item endpoints

Returns a list of endpoint objects associated with this interface.

=cut

sub endpoints
{
    my $self = shift;
    return wantarray ? @{$self->{endpoints}} : $self->{endpoints};
}

=back

=head1 DIAGNOSTICS

This is an explanation of the diagnostic and error messages this module
can generate.

=head1 DEPENDENCIES

This module depends on the Carp, Inline and Inline::C modules, as well as
the strict and warnings pragmas. Obviously, libusb must be available since
that is the entire reason for the module's existence.

=head1 AUTHOR

G. Wade Johnson (gwadej at cpan dot org)
Paul Archer (paul at paularcher dot org)

Houston Perl Mongers Group

=head1 BUGS

Please report any bugs or feature requests to
C<bug-device-usb@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Device::USB>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks go to various members of the Houston Perl Mongers group for input
on the module. But thanks mostly go to Paul Archer who proposed the project
and helped with the development.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2013 Houston Perl Mongers

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
