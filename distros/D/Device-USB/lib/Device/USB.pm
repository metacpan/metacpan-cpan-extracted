package Device::USB;

require 5.006;
use warnings;
use strict;
use Carp;

use Inline (
        C => "DATA",
        ($ENV{LIBUSB_LIBDIR}
            ? ( LIBS => "-L\"$ENV{LIBUSB_LIBDIR}\" " .
                        ($^O eq 'MSWin32' ? ' -llibusb -L\"$ENV{WINDDK}\\lib\\crt\\i386\" -lmsvcrt ' : '-lusb') )
            : ( LIBS => '-lusb', )
        ),
        ($ENV{LIBUSB_INCDIR} ? ( INC => "-I\"$ENV{LIBUSB_INCDIR}\"" ) : () ),
        NAME => 'Device::USB',
        VERSION => '0.37',
   );

Inline->init();

#
# Now the Perl code.
#

use Device::USB::Device;
use Device::USB::DevConfig;
use Device::USB::DevInterface;
use Device::USB::DevEndpoint;
use Device::USB::Bus;

use constant CLASS_PER_INSTANCE => 0;
use constant CLASS_AUDIO => 1;
use constant CLASS_COMM =>  2;
use constant CLASS_HID =>   3;
use constant CLASS_PRINTER => 7;
use constant CLASS_MASS_STORAGE => 8;
use constant CLASS_HUB =>     9;
use constant CLASS_DATA =>   10;
use constant CLASS_VENDOR_SPEC => 0xff;

=encoding utf8

=head1 NAME

Device::USB - Use libusb to access USB devices. (DEPRECATED)

=head1 VERSION

Version 0.37

=cut

our $VERSION=0.37;


=head1 SYNOPSIS

Device::USB provides a Perl wrapper around the libusb library. This
supports Perl code controlling and accessing USB devices.

    use Device::USB;

    my $usb = Device::USB->new();
    my $dev = $usb->find_device( $VENDOR, $PRODUCT );

    printf "Device: %04X:%04X\n", $dev->idVendor(), $dev->idProduct();
    $dev->open();
    print "Manufactured by ", $dev->manufacturer(), "\n",
          " Product: ", $dev->product(), "\n";

    $dev->set_configuration( $CFG );
    $dev->control_msg( @params );
    ...

See the libusb manual for more information about most of the methods. The
functionality is generally the same as the libusb function whose name is
the method name prepended with "usb_".

=head1 DESCRIPTION

This module is deprecated as of version 0.37. I have not had the time
or need to update the module, and no one has been willing to take it
over.

This module provides a Perl interface to the C library libusb. This library
supports a relatively full set of functionality to access a USB device. In
addition to the libusb, functioality, Device::USB provides a few
convenience features that are intended to produce a more Perl-ish interface.

These features include:

=over 4

=item *

Using the library initializes it, no need to call the underlying usb_init
function.

=item *

Object interface reduces namespace pollution and provides a better interface
to the library.

=item *

The find_device method finds the device associated with a vendor id and
product id and creates an appropriate Device::USB::Device object to
manipulate the USB device.

=item *

Object interfaces to the bus and device data structures allowing read access
to information about each.

=back

=head1 Device::USB

This class provides an interface to the non-bus and non-device specific
functions of the libusb library. In particular, it provides interfaces to
find busses and devices. It also provides convenience methods that simplify
some of the tasks above.

=head2 CONSTANTS

This class provides a set of constants for the defined device classes. The
constants defined at this time are:

=over 4

=item *

CLASS_PER_INSTANCE

=item *

CLASS_AUDIO

=item *

CLASS_COMM

=item *

CLASS_HID

=item *

CLASS_PRINTER

=item *

CLASS_MASS_STORAGE

=item *

CLASS_HUB

=item *

CLASS_DATA

=item *

CLASS_VENDOR_SPEC

=back

=head2 FUNCTIONS

=over 4

=cut

#
#  Internal-only, one-time init function.
my $init_ref;
$init_ref = sub
{
    libusb_init();
    $init_ref = sub {};
};

=item new

Create a new Device::USB object for accessing the library.

=cut

sub new
{
    my $class = shift;

    $init_ref->();

    return bless {}, $class;
}

=item debug_mode

This class method enables low-level debugging messages from the library
interface code.

=over 4

=item level

0 disables debugging, 1 enables some debug messages, and 2 enables verbose
debug messages

Any other values are forced to the nearest endpoint.

=back

=cut

sub debug_mode
{
    my ($class, $level) = @_;

    lib_debug_mode( $level );
    return;
}


=item find_busses

Returns the number of changes since previous call to the function: the
number of busses added or removed.

=cut

sub find_busses
{
    my $self = shift;
    return libusb_find_busses();
}

=item find_devices

Returns the number of changes since previous call to the function: the
number of devices added or removed. Should be called after find_busses.

=cut

sub find_devices
{
    my $self = shift;
    return libusb_find_devices();
}

=item find_device

Find a particular USB device based on the vendor and product ids. If more
than one device has the same product id from the same vendor, the first one
found is returned.

=over 4

=item vendor

the vendor id

=item product

product id for that vendor

=back

returns a device reference or undef if none was found.

=cut

sub find_device
{
    my $self = shift;
    my $vendor = shift;
    my $product = shift;

    return lib_find_usb_device( $vendor, $product );
}

=item find_device_if

Find a particular USB device based on the supplied predicate coderef. If
more than one device would satisfy the predicate, the first one found is
returned.

=over 4

=item pred

the predicate used to select a device

=back

returns a device reference or undef if none was found.

=cut

sub find_device_if
{
    my $self = shift;
    my $pred = shift;

    croak( "Missing predicate for choosing a device.\n" )
        unless defined $pred;

    croak( "Predicate must be a code reference.\n" )
        unless 'CODE' eq ref $pred;

    foreach my $bus ($self->list_busses())
    {
        my $dev = $bus->find_device_if( $pred );
        return $dev if defined $dev;
    }

    return;
}

=item list_devices

Find all devices matching a vendor id and optional product id. If called
with no parameters, returns a list of all devices. If no product id is
given, returns all devices found with the supplied vendor id. If a product
id is given, returns all devices matching both the vendor id and product id.

=over 4

=item vendor

the optional vendor id

=item product

optional product id for that vendor

=back

returns a list of devices matching the supplied criteria or a reference
to that array in scalar context

=cut

sub list_devices
{
    my $self = shift;
    my $vendor = shift;
    my $product = shift;
    my $pred = undef;

    if(!defined $vendor)
    {
        $pred = sub { defined };
    }
    elsif(!defined $product)
    {
        $pred = sub { $vendor == $_->idVendor() };
    }
    else
    {
        $pred =
            sub { $vendor == $_->idVendor() && $product == $_->idProduct() };
    }

    return $self->list_devices_if( $pred );
}

=item list_devices_if

This method provides a more flexible interface for finding devices. It
takes a single coderef parameter that is used to test each discovered
device. If the coderef returns a true value, the device is returned in the
list of matching devices, otherwise it is not.

=over 4

=item pred

coderef to test devices.

=back

For example,

    my @devices = $usb->list_devices_if(
        sub { Device::USB::CLASS_HUB == $_->bDeviceClass() }
    );

Returns all USB hubs found. The device to test is available to the coderef
in the C<$_> variable for simplicity.

=cut

sub list_devices_if
{
    my $self = shift;
    my $pred = shift;

    croak( "Missing predicate for choosing devices.\n" )
        unless defined $pred;

    croak( "Predicate must be a code reference.\n" )
        unless 'CODE' eq ref $pred;

    my @devices = ();
    local $_ = undef;

    foreach my $bus ($self->list_busses())
    {
        # Push all matching devices for this bus on list.
        push @devices, $bus->list_devices_if( $pred );
    }

    return wantarray ? @devices : \@devices;
}

=item list_busses

Return the complete list of information after finding busses and devices.

By using this function, you do not need to do the find_* calls yourself.

returns a reference to an array of busses.

=cut

sub list_busses
{
    my $self = shift;
    my $busses = lib_list_busses();

    return wantarray ? @{$busses} : $busses;
}

=item get_busses

Return the complete list of information after finding busses and devices.

Before calling this function, remember to call find_busses and find_devices.

returns a reference to an array of busses.

=cut

sub get_busses
{
    my $self = shift;
    my $busses = lib_get_usb_busses();

    return wantarray ? @{$busses} : $busses;
}

=back

=head1 LIBRARY INTERFACE

The raw api of the libusb library is also :

=over 4

=item DeviceUSBDebugLevel()


=item libusb_init()


=item libusb_find_busses()


=item libusb_find_devices()


=item libusb_get_busses()


=item libusb_open(void *dev)


=item libusb_close(void *dev)


=item libusb_set_configuration(void *dev, int configuration)


=item libusb_set_altinterface(void *dev, int alternate)


=item libusb_clear_halt(void *dev, unsigned int ep)


=item libusb_reset(void *dev)


=item libusb_get_driver_np(void *dev, int interface, char *name, unsigned int namelen)


=item libusb_detach_kernel_driver_np(void *dev, int interface)


=item libusb_claim_interface(void *dev, int interface)


=item libusb_release_interface(void *dev, int interface)


=item libusb_control_msg(void *dev, int requesttype, int request, int value, int index, char *bytes, int size, int timeout)


=item libusb_get_string(void *dev, int index, int langid, char *buf, size_t buflen)


=item libusb_get_string_simple(void *dev, int index, char *buf, size_t buflen)


=item libusb_get_descriptor(void *dev, unsigned char type, unsigned char index, char *buf, int size)


=item libusb_get_descriptor_by_endpoint(void *dev, int ep, unsigned char type, unsigned char index, char *buf, int size)


=item libusb_bulk_write(void *dev, int ep, char *bytes, int size, int timeout)


=item libusb_bulk_read(void *dev, int ep, char *bytes, int size, int timeout)


=item libusb_interrupt_write(void *dev, int ep, char *bytes, int size, int timeout)


=item libusb_interrupt_read(void *dev, int ep, char *bytes, int size, int timeout)


=item lib_get_usb_busses()

Return the complete list of information after finding busses and devices.

Before calling this function, remember to call find_busses and find_devices.

returns a reference to an array of busses.

=item lib_list_busses()

Return the complete list of information after finding busses and devices.

By using this function, you do not need to do the find_* calls yourself.

returns a reference to an array of busses.

=item lib_find_usb_device( int vendor, int product )

Find a particular device

   vendor  - the vendor id
   product - product id for that vendor

returns a pointer to the device if it is found, NULL otherwise.

=item lib_debug_mode( int unsafe_level )

Set debugging level: 0: off, 1: some messages, 2: verbose
Values outside range are forced into range.

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

Original author: David Davis

=head1 BUGS

Please report any bugs or feature requests to
C<bug-device-usb@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Device::USB>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 FOR MORE INFORMATION

The project is hosted at github L<https://github.com/gwadej/perl-device-usb/>.
More information on the project, including installation help is avaliable on the
Wiki.

=head1 LIMITATIONS

So far, this module has only been tested on Linux. It should work on any
OS that supports the libusb library. Several people have reported problems
compiling the module on Windows. In theory, it should be possible to make
the library work with LibUsb-Win32 L<http://libusb-win32.sourceforge.net/>.
Without access to a Windows development system, I can't make those changes.

The Interfaces and Endpoints are not yet proper objects. The code to extract
this information is not yet written.

=head1 ACKNOWLEDGEMENTS

Thanks go to various members of the Houston Perl Mongers group for input
on the module. But thanks mostly go to Paul Archer who proposed the project
and helped with the development.

Thanks to Josep Monés Teixidor for fixing the C<bInterfaceClass> bug.

Thanks to Mike McCauley for support of C<usb_get_driver_np> and
C<usb_detach_kernel_driver_np>.

Thanks to Vadim Mikhailov for fixing a compile problem with VC6 on Windows
and then chipping in again for VS 2005 on Windows, and yet again to fix
warnings on C99-compliant compilers.

Thanks to John R. Hogheruis for information about modifying the Inline
parameters for compiling with Strawberry Perl on Windows.

Thanks to Tony Shadwick for helping me resolve a problem with bulk_read and
interrupt_read.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2013 Houston Perl Mongers

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

__DATA__

__C__

#include <usb.h>

static unsigned debugLevel = 0;

unsigned DeviceUSBDebugLevel()
{
    return debugLevel;
}

void libusb_init()
{
    usb_init();
}

int libusb_find_busses()
{
    return usb_find_busses();
}

int libusb_find_devices()
{
    return usb_find_devices();
}

void *libusb_get_busses()
{
    return usb_get_busses();
}

void *libusb_open(void *dev)
{
    return usb_open( (struct usb_device*)dev );
}

int libusb_close(void *dev)
{
    return usb_close((usb_dev_handle *)dev);
}

int libusb_set_configuration(void *dev, int configuration)
{
    if(DeviceUSBDebugLevel())
    {
        printf( "libusb_set_configuration( %d )\n", configuration );
    }
    return usb_set_configuration((usb_dev_handle *)dev, configuration);
}

int libusb_set_altinterface(void *dev, int alternate)
{
    if(DeviceUSBDebugLevel())
    {
        printf( "libusb_set_altinterface( %d )\n", alternate );
    }
    return usb_set_altinterface((usb_dev_handle *)dev, alternate);
}

int libusb_clear_halt(void *dev, unsigned int ep)
{
    if(DeviceUSBDebugLevel())
    {
        printf( "libusb_clear_halt( %d )\n", ep );
    }
    return usb_clear_halt((usb_dev_handle *)dev, ep);
}

int libusb_reset(void *dev)
{
    return usb_reset((usb_dev_handle *)dev);
}

int libusb_get_driver_np(void *dev, int interface, char *name, unsigned int namelen)
{
    int ret = 0;
    if(DeviceUSBDebugLevel())
    {
        printf( "libusb_get_driver_np( %d )\n", interface );
    }
#if LIBUSB_HAS_GET_DRIVER_NP
    ret = usb_get_driver_np((usb_dev_handle *)dev, interface, name, namelen);
    if (ret >= 0) return strlen(name);
    return ret;
#else
    return 0;
#endif
}

int libusb_detach_kernel_driver_np(void *dev, int interface)
{
    if(DeviceUSBDebugLevel())
    {
        printf( "libusb_detach_kernel_driver_np( %d )\n", interface );
    }
#if LIBUSB_HAS_DETACH_KERNEL_DRIVER_NP
    return usb_detach_kernel_driver_np((usb_dev_handle *)dev, interface);
#else
    return 0;
#endif
}

int libusb_claim_interface(void *dev, int interface)
{
    if(DeviceUSBDebugLevel())
    {
        printf( "libusb_claim_interface( %d )\n", interface );
    }
    return usb_claim_interface((usb_dev_handle *)dev, interface);
}

int libusb_release_interface(void *dev, int interface)
{
    if(DeviceUSBDebugLevel())
    {
        printf( "libusb_release_interface( %d )\n", interface );
    }
    return usb_release_interface((usb_dev_handle *)dev, interface);
}

void libusb_control_msg(void *dev, int requesttype, int request, int value, int index, char *bytes, int size, int timeout)
{
    int i = 0;
    int retval = 0;

    Inline_Stack_Vars;

    if(DeviceUSBDebugLevel())
    {
        printf( "libusb_control_msg( %#04x, %#04x, %#04x, %#04x, %p, %d, %d )\n",
            requesttype, request, value, index, bytes, size, timeout
        );
        /* maybe need to add support for printing the bytes string. */
    }
    retval = usb_control_msg((usb_dev_handle *)dev, requesttype, request, value, index, bytes, size, timeout);
    if(DeviceUSBDebugLevel())
    {
        printf( "\t => %d\n",retval );
    }

    /* quiet compiler warnings. */
    (void)i;
    (void)ax;
    (void)items;
    /*
     * For some reason, I could not get this string transferred back to the Perl side
     * through a direct copy like in get_simple_string. So, I resorted to returning
     * it on the stack and doing the fixup on the Perl side.
     */
    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSViv(retval)));
    if(retval > 0)
    {
        Inline_Stack_Push(sv_2mortal(newSVpv(bytes, retval)));
    }
    else
    {
        Inline_Stack_Push(sv_2mortal(newSVpv(bytes, 0)));
    }
    Inline_Stack_Done;
}

int libusb_get_string(void *dev, int index, int langid, char *buf, size_t buflen)
{
    if(DeviceUSBDebugLevel())
    {
        printf( "libusb_get_string( %d, %d, %p, %lu )\n",
            index, langid, buf, (unsigned long)buflen
        );
    }
    return usb_get_string((usb_dev_handle *)dev, index, langid, buf, buflen);
}

int libusb_get_string_simple(void *dev, int index, char *buf, size_t buflen)
{
    if(DeviceUSBDebugLevel())
    {
        printf( "libusb_get_string_simple( %d, %p, %lu )\n",
            index, buf, (unsigned long)buflen
        );
    }
    return usb_get_string_simple((usb_dev_handle *)dev, index, buf, buflen);
}

int libusb_get_descriptor(void *dev, unsigned char type, unsigned char index, char *buf, int size)
{
    return usb_get_descriptor((usb_dev_handle *)dev, type, index, buf, size);
}

int libusb_get_descriptor_by_endpoint(void *dev, int ep, unsigned char type, unsigned char index, char *buf, int size)
{
    return usb_get_descriptor_by_endpoint((usb_dev_handle *)dev, ep, type, index, buf, size);
}

int libusb_bulk_write(void *dev, int ep, char *bytes, int size, int timeout)
{
    return usb_bulk_write((usb_dev_handle *)dev, ep, bytes, size, timeout);
}

int libusb_bulk_read(void *dev, int ep, char *bytes, int size, int timeout)
{
    return usb_bulk_read((usb_dev_handle *)dev, ep, bytes, size, timeout);
}

int libusb_interrupt_write(void *dev, int ep, char *bytes, int size, int timeout)
{
    return usb_interrupt_write((usb_dev_handle *)dev, ep, bytes, size, timeout);
}

int libusb_interrupt_read(void *dev, int ep, char *bytes, int size, int timeout)
{
    return usb_interrupt_read((usb_dev_handle *)dev, ep, bytes, size, timeout);
}


/* ------------------------------------------------------------
 * Provide Perl-ish interface for accessing busses and devices.
 */

/*
 * Utility function to store BCD encoded number as an appropriate string
 * in a hash under the supplied key.
 */
static void hashStoreBcd( HV *hash, const char *key, long value )
{
    int major = (value >> 8) & 0xff;
    int minor = (value >> 4) & 0xf;
    int subminor = value & 0xf;

    // should not be able to exceed 6.
    char buffer[10] = "";

    sprintf( buffer, "%d.%d%d", major, minor, subminor );

    (void) hv_store( hash, key, strlen( key ), newSVpv( buffer, strlen( buffer ) ), 0 );
}

/*
 * Utility function to store an integer value in a hash under the supplied key.
 */
static void hashStoreInt( HV *hash, const char *key, long value )
{
    (void) hv_store( hash, key, strlen( key ), newSViv( value ), 0 );
}

/*
 * Utility function to store a C-style string in a hash under the supplied key.
 */
static void hashStoreString( HV *hash, const char *key, const char *value )
{
    (void) hv_store( hash, key, strlen( key ), newSVpv( value, strlen( value ) ), 0 );
}

/*
 * Utility function to store an SV in a hash under the supplied key.
 */
static void hashStoreSV( HV *hash, const char *key, SV *value )
{
    (void) hv_store( hash, key, strlen( key ), value, 0 );
}

/*
 * Given a pointer to an array of usb_device, create a hash
 * reference containing the descriptor information.
 */
static SV* build_descriptor(struct usb_device *dev)
{
    HV* hash = newHV();

    hashStoreInt( hash, "bDescriptorType", dev->descriptor.bDescriptorType );
    hashStoreBcd( hash, "bcdUSB", dev->descriptor.bcdUSB );
    hashStoreInt( hash, "bDeviceClass", dev->descriptor.bDeviceClass );
    hashStoreInt( hash, "bDeviceSubClass", dev->descriptor.bDeviceSubClass );
    hashStoreInt( hash, "bDeviceProtocol", dev->descriptor.bDeviceProtocol );
    hashStoreInt( hash, "bMaxPacketSize0", dev->descriptor.bMaxPacketSize0 );
    hashStoreInt( hash, "idVendor", dev->descriptor.idVendor );
    hashStoreInt( hash, "idProduct", dev->descriptor.idProduct );
    hashStoreBcd( hash, "bcdDevice", dev->descriptor.bcdDevice );
    hashStoreInt( hash, "iManufacturer", dev->descriptor.iManufacturer );
    hashStoreInt( hash, "iProduct", dev->descriptor.iProduct );
    hashStoreInt( hash, "iSerialNumber", dev->descriptor.iSerialNumber );
    hashStoreInt( hash, "bNumConfigurations", dev->descriptor.bNumConfigurations );

    return newRV_noinc( (SV*)hash );
}

/*
 * Given a pointer to a usb_endpoint_descriptor struct, create a reference
 * to a Device::USB::DevEndpoint object that represents it.
 */
static SV* build_endpoint( struct usb_endpoint_descriptor* endpt )
{
    HV* hash = newHV();

    hashStoreInt( hash, "bDescriptorType", endpt->bDescriptorType );
    hashStoreInt( hash, "bEndpointAddress", endpt->bEndpointAddress );
    hashStoreInt( hash, "bmAttributes", endpt->bmAttributes );
    hashStoreInt( hash, "wMaxPacketSize", endpt->wMaxPacketSize );
    hashStoreInt( hash, "bInterval", endpt->bInterval );
    hashStoreInt( hash, "bRefresh", endpt->bRefresh );
    hashStoreInt( hash, "bSynchAddress", endpt->bSynchAddress );

    return sv_bless( newRV_noinc( (SV*)hash ),
        gv_stashpv( "Device::USB::DevEndpoint", 1 )
    );
}

/*
 * Given a pointer to an array of usb_endpoint_descriptor structs, create a
 * reference to a Perl array containing the same data.
 */
static SV* list_endpoints( struct usb_endpoint_descriptor* endpt, unsigned count )
{
    AV* array = newAV();
    unsigned i = 0;

    for(i=0; i < count; ++i)
    {
        av_push( array, build_endpoint( endpt+i ) );
    }

    return newRV_noinc( (SV*)array );
}


/*
 * Build the object that contains the interface descriptor.
 *
 * inter - the usb_interface_descriptor describing this interface.
 *
 * returns the appropriate pointer to a reference.
 */
static SV* build_interface( struct usb_interface_descriptor* inter )
{
    HV* hash = newHV();

    hashStoreInt( hash, "bDescriptorType", inter->bDescriptorType );
    hashStoreInt( hash, "bInterfaceNumber", inter->bInterfaceNumber );
    hashStoreInt( hash, "bAlternateSetting", inter->bAlternateSetting );
    hashStoreInt( hash, "bNumEndpoints", inter->bNumEndpoints );
    hashStoreInt( hash, "bInterfaceClass", inter->bInterfaceClass );
    hashStoreInt( hash, "bInterfaceSubClass", inter->bInterfaceSubClass );
    hashStoreInt( hash, "bInterfaceProtocol", inter->bInterfaceProtocol );
    hashStoreInt( hash, "iInterface", inter->iInterface );
    hashStoreSV( hash, "endpoints",
        list_endpoints( inter->endpoint, inter->bNumEndpoints )
    );
    /* TODO: handle the 'extra' data */

    return sv_bless( newRV_noinc( (SV*)hash ),
        gv_stashpv( "Device::USB::DevInterface", 1 )
    );
}

/*
 * Given a pointer to an array of usb_interface structs, create a
 * reference to a Perl array containing the same data.
 */
static SV* list_interfaces( struct usb_interface* ints, unsigned count )
{
    AV* array = newAV();
    unsigned i = 0;

    for(i=0; i < count; ++i)
    {
        AV* inters = newAV();
        unsigned j = 0;
        for(j=0; j < ints[i].num_altsetting; ++j)
        {
            av_push( inters, build_interface( (ints[i].altsetting+j) ) );
        }
        av_push( array, newRV_noinc( (SV*)inters ) );
    }

    return newRV_noinc( (SV*)array );
}

/*
 * Given a pointer to a usb_config_descriptor struct, create a Perl
 * object that contains the same data.
 */
static SV* build_configuration( struct usb_config_descriptor *cfg )
{
    HV* hash = newHV();
    hashStoreInt( hash, "bDescriptorType", cfg->bDescriptorType );
    hashStoreInt( hash, "wTotalLength", cfg->wTotalLength );
    hashStoreInt( hash, "bNumInterfaces", cfg->bNumInterfaces );
    hashStoreInt( hash, "bConfigurationValue", cfg->bConfigurationValue );
    hashStoreInt( hash, "iConfiguration", cfg->iConfiguration );
    hashStoreInt( hash, "bmAttributes", cfg->bmAttributes );
    hashStoreInt( hash, "MaxPower", cfg->MaxPower*2 );
    hashStoreSV( hash, "interfaces",
        list_interfaces( cfg->interface, cfg->bNumInterfaces )
    );

    return sv_bless( newRV_noinc( (SV*)hash ),
        gv_stashpv( "Device::USB::DevConfig", 1 )
    );
}

/*
 * Given a pointer to an array of usb_config_descriptor structs, create a
 * reference to a Perl array containing the same data.
 */
static SV* list_configurations(struct usb_config_descriptor *cfg, unsigned count )
{
    AV* array = newAV();
    unsigned i = 0;

    for(i=0; i < count; ++i)
    {
        av_push( array, build_configuration( (cfg+i) ) );
    }

    return newRV_noinc( (SV*)array );
}

/*
 * Given a pointer to a usb device structure, return a reference to a
 * Perl object containing the same data.
 */
static SV* build_device(struct usb_device *dev)
{
    HV* hash = newHV();

    hashStoreString( hash, "filename", dev->filename );
    hashStoreSV( hash, "descriptor", build_descriptor( dev ) );
    hashStoreSV( hash, "config",
       list_configurations( dev->config, dev->descriptor.bNumConfigurations )
    );
    hashStoreInt( hash, "device", (unsigned long)dev );

    return sv_bless( newRV_noinc( (SV*)hash ),
        gv_stashpv( "Device::USB::Device", 1 )
    );
}

/*
 * Given a pointer to a list of devices, return a reference to a
 * Perl array of device objects.
 */
static SV* list_devices(struct usb_device *dev)
{
    AV* array = newAV();

    for(; 0 != dev; dev = dev->next)
    {
        av_push( array, build_device( dev ) );
    }

    return newRV_noinc( (SV*) array );
}


static SV* build_bus( struct usb_bus *bus )
{
    HV *hash = newHV();

    hashStoreString( hash, "dirname", bus->dirname );
    hashStoreInt( hash, "location", bus->location );
    hashStoreSV( hash, "devices", list_devices( bus->devices ) );

    return sv_bless( newRV_noinc( (SV*)hash ),
        gv_stashpv( "Device::USB::Bus", 1 )
    );
}


/*
 * Return the complete list of information after finding busses and devices.
 *
 * Before calling this function, remember to call find_busses and find_devices.
 *
 * returns a reference to an array of busses.
 */
SV* lib_get_usb_busses()
{
    AV* array = newAV();
    struct usb_bus *bus = 0;

    for(bus = usb_busses; 0 != bus; bus = bus->next)
    {
        av_push( array, build_bus( bus ) );
    }

    return newRV_noinc( (SV*) array );
}

/*
 * Return the complete list of information after finding busses and devices.
 *
 * By using this function, you do not need to do the find_* calls yourself.
 *
 * returns a reference to an array of busses.
 */
SV* lib_list_busses()
{
    usb_find_busses();
    usb_find_devices();

    return lib_get_usb_busses();
}

/*
 * Find a particular device
 *
 *  vendor  - the vendor id
 *  product - product id for that vendor
 *
 * returns a pointer to the device if it is found, NULL otherwise.
 */
SV *lib_find_usb_device( int vendor, int product )
{
    struct usb_bus *bus = 0;

    usb_find_busses();
    usb_find_devices();

    for(bus = usb_busses; 0 != bus; bus = bus->next)
    {
        struct usb_device *dev = 0;
        for(dev = bus->devices; 0 != dev; dev = dev->next)
        {
            if((dev->descriptor.idVendor == vendor) &&
              (dev->descriptor.idProduct == product))
            {
                return build_device( dev );
            }
        }
    }

    return &PL_sv_undef;
}

/*
 * Set debugging level: 0: off, 1: some messages, 2: verbose
 * Values outside range are forced into range.
 */
void  lib_debug_mode( int unsafe_level )
{
    static char* level_str[] = { "off", "on", "verbose" };

    int level = unsafe_level;
    if(level < 0)
    {
        level = 0;
    }
    else if(level > 2)
    {
        level = 2;
    }

    printf( "Debugging: %s\n", level_str[level] );
    usb_set_debug(level);
    debugLevel = level;
}

