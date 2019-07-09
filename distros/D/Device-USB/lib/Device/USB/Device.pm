package Device::USB::Device;

require 5.006;
use warnings;
use strict;
use Carp;

use constant MAX_BUFFER_SIZE => 256;

=encoding utf8

=head1 Device::USB::Device

This class encapsulates the USB device structure and the methods that may be
applied to it.

=head1 NAME

Device::USB::Device - Use libusb to access USB devices.

=head1 VERSION

Version 0.38

=cut

our $VERSION=0.38;


=head1 SYNOPSIS

Device:USB::Device provides a Perl object for accessing a USB device
using the libusb library.

    use Device::USB;

    my $usb = Device::USB->new();
    my $dev = $usb->find_device( $VENDOR, $PRODUCT );

    printf "Device: %04X:%04X\n", $dev->idVendor(), $dev->idProduct();
    print "Manufactured by ", $dev->manufacturer(), "\n",
          " Product: ", $dev->product(), "\n";

    $dev->set_configuration( $CFG );
    $dev->control_msg( @params );
    ...

See the libusb manual for more information about most of the methods. The
functionality is generally the same as the libusb function whose name is
the method name prepended with "usb_".

=head1 DESCRIPTION

This module defines a Perl object that represents the data and functionality
associated with a USB device. The object interface provides read-only access
to the important data associated with a device. It also provides methods for
almost all of the functions supplied by libusb. Where necessary, the interfaces
to these methods were changed to better match Perl usage. However, most of the
methods are straight-forward wrappers around their libusb counterparts.

=head2 METHODS

=over 4

=item DESTROY

Close the device connected to the object.

=cut

sub DESTROY
{
    my $self = shift;
    Device::USB::libusb_close( $self->{handle} ) if $self->{handle};
    return;
}

# Make certain the device is open.
sub _assert_open
{
    my $self = shift;

    if(!defined $self->{handle})
    {
        $self->open() or croak "Cannot open device: $!\n";
    }
    return;
}


# I need to build a lot of accessors
sub _make_descr_accessor
{
    my $name = shift;
    ## no critic (ProhibitStringyEval)

    return eval <<"EOE";
sub $name
        {
            my \$self = shift;
            return \$self->{descriptor}->{$name};
        }
EOE
}

=item filename

Retrieve the filename associated with the device.

=cut

sub filename
{
    my $self = shift;
    return $self->{filename};
}

=item config

In list context, return a list of the configuration structures for this device.
In scalar context, return a reference to that list. This method is deprecated
in favor of the two new methods: configurations and get_configuration.

=cut

sub config
{
    my $self = shift;
    return wantarray ? @{$self->{config}} : $self->{config};
}

=item configurations

In list context, return a list of the configuration structures for this device.
In scalar context, return a reference to that list.

=cut

sub configurations
{
    my $self = shift;
    return wantarray ? @{$self->{config}} : $self->{config};
}

=item get_configuration

Retrieve the configuration requested by index. The legal values are from 0
to bNumConfigurations() - 1. Negative values access from the back of the list
of configurations.

=over 4

=item index numeric index of the index to return. If not supplied, use 0.

=back

Returns an object encapsulating the configuration on success, or C<undef> on
failure.

=cut

sub get_configuration
{
    my $self = shift;
    my $index = shift || 0;
    return $self->configurations()->[$index];
}

=item accessors

There a several accessor methods that return data from the device and device
descriptor. Each is named after the field that they return. All of the BCD
fields have been changed to floating point numbers, so that you don't have to
decode them yourself.

The methods include:

=over 4

=item bcdUSB

=item bDeviceClass

=item bDeviceSubClass

=item bDeviceProtocol

=item bMaxPacketSize0

=item idVendor

=item idProduct

=item bcdDevice

=item iManufacturer

=item iProduct

=item iSerialNumber

=item bNumConfigurations

=back

=cut

_make_descr_accessor( 'bcdUSB' );
_make_descr_accessor( 'bDeviceClass' );
_make_descr_accessor( 'bDeviceSubClass' );
_make_descr_accessor( 'bDeviceProtocol' );
_make_descr_accessor( 'bMaxPacketSize0' );
_make_descr_accessor( 'idVendor' );
_make_descr_accessor( 'idProduct' );
_make_descr_accessor( 'bcdDevice' );
_make_descr_accessor( 'iManufacturer' );
_make_descr_accessor( 'iProduct' );
_make_descr_accessor( 'iSerialNumber' );
_make_descr_accessor( 'bNumConfigurations' );

=item manufacturer

Retrieve the manufacture name from the device as a string.
Return undef if the device read fails.

=cut

sub manufacturer
{
    my $self = shift;

    return $self->get_string_simple( $self->iManufacturer() );
}

=item product

Retrieve the product name from the device as a string.
Return undef if the device read fails.

=cut

sub product
{
    my $self = shift;

    return $self->get_string_simple( $self->iProduct() );
}

=item serial_number

Retrieve the serial number from the device as a string.
Return undef if the device read fails.

=cut

sub serial_number
{
    my $self = shift;

    return $self->get_string_simple( $self->iSerialNumber() );
}

=item open

Open the device. If the device is already open, close it and reopen it.

If the device fails to open, the reason will be available in $!.

=cut

sub open  ## no critic (ProhibitBuiltinHomonyms)
{
    my $self = shift;
    Device::USB::libusb_close( $self->{handle} ) if $self->{handle};
    local $! = 0;
    $self->{handle} = Device::USB::libusb_open( $self->{device} );

    return 0 == $!;
}

=item set_configuration

Sets the active configuration of the device.

=over 4

=item configuration

the integer specified in the descriptor field bConfigurationValue.

=back

returns 0 on success or <0 on error

When using libusb-win32 under Windows, it is important to call
C<set_configuration()> after the C<open()> but before any other method calls.
Without this call, other methods may not work. This call is not required under
Linux.

=cut

sub set_configuration
{
    my $self = shift;
    my $configuration = shift;
    $self->_assert_open();

    return Device::USB::libusb_set_configuration( $self->{handle}, $configuration );
}

=item set_altinterface

Sets the active alternative setting of the current interface for the device.

=over 4

=item alternate

the integer specified in the descriptor field bAlternateSetting.

=back

returns 0 on success or <0 on error

=cut

sub set_altinterface
{
    my $self = shift;
    my $alternate = shift;
    $self->_assert_open();

    return Device::USB::libusb_set_altinterface( $self->{handle}, $alternate );
}

=item clear_halt

Clears any halt status on the supplied endpoint.

=over 4

=item alternate

the integer specified bEndpointAddress descriptor field.

=back

returns 0 on success or <0 on error

=cut

sub clear_halt
{
    my $self = shift;
    my $ep = shift;
    $self->_assert_open();

    return Device::USB::libusb_clear_halt( $self->{handle}, $ep );
}

=item reset

Resets the device. This also closes the handle and invalidates this device.
This device will be unusable.

=cut

sub reset  ## no critic (ProhibitBuiltinHomonyms)
{
    my $self = shift;

    return 0 unless defined $self->{handle};

    my $ret = Device::USB::libusb_reset( $self->{handle} );
    delete $self->{handle} unless $ret;

    return $ret;
}

=item claim_interface

Claims the specified interface with the operating system.

=over 4

=item interface

The interface value listed in the descriptor field bInterfaceNumber.

=back

Returns 0 on success, <0 on failure.

=cut

sub claim_interface
{
    my $self = shift;
    my $interface = shift;
    $self->_assert_open();

    return Device::USB::libusb_claim_interface( $self->{handle}, $interface );
}

=item release_interface

Releases the specified interface back to the operating system.

=over 4

=item interface

The interface value listed in the descriptor field bInterfaceNumber.

=back

Returns 0 on success, <0 on failure.

=cut

sub release_interface
{
    my $self = shift;
    my $interface = shift;
    $self->_assert_open();

    return Device::USB::libusb_release_interface( $self->{handle}, $interface );
}

=item control_msg

Performs a control request to the default control pipe on a device.

=over 4

=item requesttype

=item request

=item value

=item index

=item bytes

Any returned data is placed here. If you don't want any returned data,
pass undef.

=item size

Size of supplied buffer.

=item timeout

Milliseconds to wait for response.

=back

Returns number of bytes read or written on success, <0 on failure.

=cut

sub control_msg
{
    my $self = shift;
    ## no critic (RequireArgUnpacking)
    my ($requesttype, $request, $value, $index, $bytes, $size, $timeout) = @_;
    $bytes = q{} unless defined $bytes;
    $self->_assert_open();

    my ($retval, $out) = Device::USB::libusb_control_msg(
            $self->{handle}, $requesttype, $request, $value,
            $index, $bytes, $size, $timeout
       );
    # replace the input string in $bytes.
    $_[4] = $out if defined $_[4];
    return $retval;
}

=item get_string

Retrieve a string descriptor from the device.

=over 4

=item index

The index of the string in the string list.

=item langid

The language id used to specify which of the supported languages the string
should be encoded in.

=back

Returns a Unicode string. The function returns undef on error.

=cut

sub get_string
{
    my $self = shift;
    my $index = shift;
    my $langid = shift;

    $self->_assert_open();

    my $buf = "\0" x MAX_BUFFER_SIZE;

    my $retlen = Device::USB::libusb_get_string(
        $self->{handle}, $index, $langid, $buf, MAX_BUFFER_SIZE
    );

    return if $retlen < 0;

    return substr( $buf, 0, $retlen );
}

=item get_string_simple

Retrieve a string descriptor from the device.

=over 4

=item index

The index of the string in the string list.

=back

Returns a C-style string if successful, or undef on error.

=cut

sub get_string_simple
{
    my $self = shift;
    my $index = shift;
    $self->_assert_open();

    my $buf = "\0" x MAX_BUFFER_SIZE;

    my $retlen = Device::USB::libusb_get_string_simple(
        $self->{handle}, $index, $buf, MAX_BUFFER_SIZE
    );

    return if $retlen < 0;

    return substr( $buf, 0, $retlen );
}

=item get_descriptor

Retrieve a descriptor from the device

=over 4

=item type

The type of descriptor to retrieve.

=item index

The index of that descriptor in the list of descriptors of that type.

=back

TODO: This method needs major rewrite to be Perl-ish.
I need to provide a better way to specify the type (or at least document
which are available), and I need to return a Perl data structure, not
a buffer of binary data.      

=cut

sub get_descriptor
{
    my $self = shift;
    my $type = shift;
    my $index = shift;
    $self->_assert_open();

    my $buf = "\0" x MAX_BUFFER_SIZE;

    my $retlen = Device::USB::libusb_get_descriptor(
        $self->{handle}, $type, $index, $buf, MAX_BUFFER_SIZE
    );

    return if $retlen < 0;

    return substr( $buf, 0, $retlen );
}

=item get_descriptor_by_endpoint

Retrieve an endpoint-specific descriptor from the device

=over 4

=item ep

Endpoint to query.

=item type

The type of descriptor to retrieve.

=item index

The index of that descriptor in the list of descriptors.

=item buf

Buffer into which to write the requested descriptor

=item size

Max size to read into the buffer.

=back

TODO: This method needs major rewrite to be Perl-ish.
I need to provide a better way to specify the type (or at least document
which are available), and I need to return a Perl data structure, not
a buffer of binary data.      

=cut

sub get_descriptor_by_endpoint
{
    my $self = shift;
    my $ep = shift;
    my $type = shift;
    my $index = shift;

    $self->_assert_open();

    my $buf = "\0" x MAX_BUFFER_SIZE;

    my $retlen = Device::USB::libusb_get_descriptor_by_endpoint(
        $self->{handle}, $ep, $type, $index, $buf, MAX_BUFFER_SIZE
    );

    return if $retlen < 0;

    return substr( $buf, 0, $retlen );
}

=item bulk_read

Perform a bulk read request from the specified endpoint.

=over 4

=item ep

The number of the endpoint to read

=item bytes

Buffer into which to write the requested data.

=item size

Max size to read into the buffer.

=item timeout

Maximum time to wait (in milliseconds)

=back

The function returns the number of bytes returned or <0 on error.

USB is packet based, not stream based. So using C<bulk_read()> to read part
of the packet acts like a I<peek>. The next time you read, all of the packet
is still there.

The data is only removed when you read the entire packet. For this reason, you
should always call C<bulk_read()> with the total packet size.

=cut

sub bulk_read
{
    my $self = shift;
    # Don't change to shifts, I need to write back to $bytes.
    my ($ep, $bytes, $size, $timeout) = @_;
    $bytes = q{} unless defined $bytes;

    $self->_assert_open();

    if(length $bytes < $size)
    {
        $bytes .= "\0" x ($size - length $bytes);
    }

    my $retlen = Device::USB::libusb_bulk_read(
        $self->{handle}, $ep, $bytes, $size, $timeout
    );

    # stick back in the bytes parameter.
    $_[1] = substr( $bytes, 0, $retlen );

    return $retlen;
}

=item interrupt_read

Perform a interrupt read request from the specified endpoint.

=over 4

=item ep

The number of the endpoint to read

=item bytes

Buffer into which to write the requested data.

=item size

Max size to read into the buffer.

=item timeout

Maximum time to wait (in milliseconds)

=back

The function returns the number of bytes returned or <0 on error.

=cut

sub interrupt_read
{
    my $self = shift;
    # Don't change to shifts, I need to write back to $bytes.
    my ($ep, $bytes, $size, $timeout) = @_;
    $bytes = q{} unless defined $bytes;

    $self->_assert_open();

    if(length $bytes < $size)
    {
        $bytes .= "\0" x ($size - length $bytes);
    }

    my $retlen = Device::USB::libusb_interrupt_read(
        $self->{handle}, $ep, $bytes, $size, $timeout
    );

    # stick back in the bytes parameter.
    $_[1] = substr( $bytes, 0, $retlen );

    return $retlen;
}

=item bulk_write

Perform a bulk write request to the specified endpoint.

=over 4

=item ep

The number of the endpoint to write

=item bytes

Buffer from which to write the requested data.

=item timeout

Maximum time to wait (in milliseconds)

=back

The function returns the number of bytes written or <0 on error.

=cut

sub bulk_write
{
    my $self = shift;
    my $ep = shift;
    my $bytes = shift;
    my $timeout = shift;

    $self->_assert_open();

    return Device::USB::libusb_bulk_write(
        $self->{handle}, $ep, $bytes, length $bytes, $timeout
    );
}

=item interrupt_write

Perform a interrupt write request to the specified endpoint.

=over 4

=item ep

The number of the endpoint to write

=item bytes

Buffer from which to write the requested data.

=item timeout

Maximum time to wait (in milliseconds)

=back

The function returns the number of bytes written or <0 on error.

=cut

sub interrupt_write
{
    my $self = shift;
    my $ep = shift;
    my $bytes = shift;
    my $timeout = shift;

    $self->_assert_open();

    return Device::USB::libusb_interrupt_write(
        $self->{handle}, $ep, $bytes, length $bytes, $timeout
    );
}

=item get_driver_np

This function returns the name of the driver bound to the interface
specified by the parameter interface.

=over 4

=item $interface

The interface number of interest.

=back

Returns C<undef> on error.

=cut

sub get_driver_np
{
    my $self = shift;
    my $interface = shift;
    my $name = shift;

    $self->_assert_open();

    my $buf = "\0" x MAX_BUFFER_SIZE;

    my $retlen = Device::USB::libusb_get_driver_np(
        $self->{handle}, $interface, $buf, MAX_BUFFER_SIZE
    );

    return if $retlen < 0;

    return substr( $buf, 0, $retlen );
}


=item detach_kernel_driver_np

This function will detach a kernel driver from the interface specified by
parameter interface. Applications using libusb can then try claiming the
interface. Returns 0 on success or < 0 on error.

=cut

sub detach_kernel_driver_np
{
    my $self = shift;
    my $interface = shift;
    $self->_assert_open();

    return Device::USB::libusb_detach_kernel_driver_np(
        $self->{handle}, $interface
    );
}

=back

=head1 DIAGNOSTICS

This is an explanation of the diagnostic and error messages this module
can generate.

=over 4

=item Cannot open device: I<reason string>

Unable to open the USB device for the reason given.

=back

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
