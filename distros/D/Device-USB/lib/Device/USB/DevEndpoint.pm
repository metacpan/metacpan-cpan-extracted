package Device::USB::DevEndpoint;

require 5.006;
use warnings;
use strict;
use Carp;

=head1 Device::USB::DevEndpoint

This class encapsulates a USB Device endpoint and the methods that object
would support.

=head1 NAME

Device::USB::DevEndpoint - Access a device endpoint returned by libusb.

=head1 VERSION

Version 0.36

=cut

our $VERSION=0.36;

=head1 SYNOPSIS

Device::USB:DevEndpoint provides a Perl object for accessing an endpoint
of an interface of a USB device using the libusb library.

    use Device::USB;

    my $usb = Device::USB->new();
    my $dev = $usb->find_device( $VENDOR, $PRODUCT );

    printf "Device: %04X:%04X\n", $dev->idVendor(), $dev->idProduct();
    $dev->open();

    my $cfg = $dev->config()->[0];
    my $inter = $cfg->interfaces()->[0]->[0];
    my $ep = $inter->endpoints()->[0];
    print "Endpoint:", $inter->bEndpointAddress(),
       " name: ", $dev->get_string_simple($iter->iInterface()), "\n";

See USB specification for an explanation of the attributes of an
endpoint.

=head1 DESCRIPTION

This module defines a Perl object that represents the data associated with
a USB interface endpoint. The object provides read-only access to the
important data associated with the endpoint.

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

=item bEndpointAddress

=item bmAttributes

=item wMaxPacketSize

=item bInterval

=item bRefresh

=item bSynchAddress

=cut

_make_descr_accessor( 'bEndpointAddress' );
_make_descr_accessor( 'bmAttributes' );
_make_descr_accessor( 'wMaxPacketSize' );
_make_descr_accessor( 'bInterval' );
_make_descr_accessor( 'bRefresh' );
_make_descr_accessor( 'bSynchAddress' );

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
