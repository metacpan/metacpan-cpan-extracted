#
# Note that the package line is different from the file name. We only need to add
#   functionality to the Device::USB::Device package, and this is a convenient way.
#
package Device::USB::Win32Async;

use warnings;
use strict;

our $VERSION = 0.36;

require 5.006;
use Carp;

use Inline (
        C => "DATA",
        ($ENV{LIBUSB_LIBDIR}
            ? ( LIBS => "-L\"$ENV{LIBUSB_LIBDIR}\" " .
                        ($^O eq 'MSWin32' ? ' -llibusb -L\"$ENV{WINDDK}\\lib\\crt\\i386\" -lmsvcrt ' : '-lusb') )
            : ( LIBS => '-lusb', )
        ),
        ($ENV{LIBUSB_INCDIR} ? ( INC => "-I\"$ENV{LIBUSB_INCDIR}\"" ) : () ),
        NAME => 'Device::USB::Win32Async',
        VERSION => '0.36',
   );

Inline->init();


=head1 NAME

Device::USB::Win32Async - Add async functions to Device::USB

=head1 VERSION

Version 0.36

=head1 SYNOPSIS

Device::USB provides a Perl wrapper around the libusb library.

Device::USB::Win32Async adds the async functions from libusb-win32 to Device::USB.
This is only available for Win32 systems.

    use Device::USB;
    use Device::USB::Win32Async;

    my $usb = Device::USB->new();
    my $dev = $usb->find_device( $VENDOR, $PRODUCT );

    ...

    my $Context;                # Context variable for asynch I/O
    my $Buffer;                 # Buffer for results (input) or to transmit (output)
    my $NumBytes = 5000;        # of bytes to transfer

    $dev->bulk_setup_async($Context,$Endpoint);
    $Status = $dev->submit_async($Context,$Buffer,$NumBytes);   # Start the transfer

    while( 1 ) {
        $Response = $dev->reap_async_nocancel($Context,50);     # 50 mS wait time

        last
            if $Response != Device::USB::Device::ETIMEDOUT;
        #
        # Do other tasks while waiting, such as update the GUI
        #
        # For example, a TK program might call $MainWindow->update();
        #
        <Other Task code>
        }

See the libusb-win32 manual for more information about the methods. The
functionality is the same as the libusb function whose name is
the method name prepended with "usb_".

Generally, define a $Context variable which the library will use to keep track of
the asynchronous call. Activate the transfer (read or write, depending on the
endpoint) using submit_async() as shown, then loop calling reap_async_nocancel()
while checking the return code.

You can have any number of async operations pending on different endpoints - just
define multiple context variables as needed (ie - $Context1, $Context2, &c).

=cut


##########################################################################################
#
# Version 0.34 - Added support for asynchronous I/O
#
# The caller supplies a scalar $Context which we use to keep opaque (from the caller)
#   information about the I/O operation.
#
# The libusb driver will malloc some data and pass back a pointer to use as the context,
#   but we need to keep track of the buffer as well as this malloc'd context.
#
# So in the caller's $Context we store a ref to an anonymous array with two elements:
#   [0] => the libusb context, and [1] => ref to the user's buffer.
#
# We do this using $_[1], which is an alias to the user's var.
#
=over

=item isochronous_setup_async($Context,$Endpoint,$Packetsize)

Setup a Context for use in subsequent asynchronous operations

=over 4

=item Context

A scalar to store opaque information about the operation

=item Endpoint

The endpoint the asynchronous operation will use

=item Packetsize

The size of the isochronous packets

=back

Returns 0 on success, < 0 on error (consult errno.h for explanation)

=cut

sub isochronous_setup_async {
    my $self = shift;
    $self->_assert_open();

    #
    # ($Context,$Endpoint,$Packetsize) = @_;
    #
    $_[0] = [ 0, "" ];      # User's var is now anonymous array

    return libusb_isochronous_setup_async($self->{handle},$_[0][0],$_[1],$_[2]);
    }

=item bulk_setup_async($Context,$Endpoint)

Setup a Context for use in subsequent asynchronous operations

=over 4

=item Context

A scalar to store opaque information about the operation

=item Endpoint

The endpoint the asynchronous operation will use

=back

Returns 0 on success, < 0 on error (consult errno.h for explanation)

=cut

sub bulk_setup_async {
    my $self = shift;
    $self->_assert_open();

    #
    # ($Context,$Endpoint) = @_;
    #
    $_[0] = [ 0, "" ];      # User's var is now anonymous array

    return libusb_bulk_setup_async($self->{handle},$_[0][0],$_[1]);
    }

=item interrupt_setup_async($Context,$Endpoint)

Setup a Context for use in subsequent asynchronous operations

=over 4

=item Context

A scalar to store opaque information about the operation

=item Endpoint

The endpoint the asynchronous operation will use

=back

Returns 0 on success, < 0 on error (consult errno.h for explanation)

=cut

sub interrupt_setup_async {
    my $self = shift;
    $self->_assert_open();

    #
    # ($Context,$Endpoint) = @_;
    #
    $_[0] = [ 0, "" ];      # User's var is now anonymous array

    return libusb_interrupt_setup_async($self->{handle},$_[0][0],$_[1]);
    }

=item submit_async($Context,$Buffer,$Size)

Start an asynchronous I/O operation

=over 4

=item Context

A previously prepared context generated by one of the xxx_setup_async functions above

=item Buffer

A string buffer to receive the resulting data

=item Size

The number of bytes to pre-allocate to hold the incoming data.

=back

Returns 0 on success, < 0 on error (consult errno.h for explanation)

=cut

sub submit_async {
    my $self = shift;
    $self->_assert_open();

    #
    # ($Context,$Buffer,$Size) = @_;
    #
    $_[0][1] = \$_[1];      # Save user's buffer for reap (below)

    return libusb_submit_async($_[0][0],$_[1],$_[2]);
    }

=item reap_async($Context,$Timeout)

Get the results of an asynchronous operation and cancel if not complete.

=over 4

=item Context

A previously prepared context generated by one of the xxx_setup_async functions above

=item Timeout

Number of milliseconds to wait before timeout

=back

Returns 0 on success, < 0 on error (consult errno.h for explanation)

=cut

sub reap_async {
    my $self = shift;
    $self->_assert_open();

    #
    # ($Context,$Timeout) = @_;
    #
    my $Status = libusb_reap_async($_[0][0],$_[1]);

    #
    # We kept the buffer so that we could set the actual number of bytes read.
    #
    ${$_[0][1]} = substr(${$_[0][1]},0,$Status)
        if( $Status >= 0 );

    return $Status;
    }

=item reap_async_nocancel($Context,$Timeout)

Get the results of an asynchronous operation, but continue request (return
Device::USB::Device::ETIMEDOUT => -116) if not complete yet.

=over 4

=item Context

A previously prepared context generated by one of the xxx_setup_async functions above

=item Timeout

Number of milliseconds to wait before timeout

=back

Returns 0 on success, < 0 on error (consult errno.h for explanation)

=cut

use constant ETIMEDOUT => -116;

use Data::Dumper;

sub reap_async_nocancel {
    my $self = shift;
    $self->_assert_open();

    #
    # ($Context,$Timeout) = @_;
    #
    my $Status = libusb_reap_async_nocancel($_[0][0],$_[1]);

    #
    # We kept the buffer so that we could set the actual number of bytes read.
    #
    ${$_[0][1]} = substr(${$_[0][1]},0,$Status)
        if( $Status >= 0 );

    return $Status;
    }

=item cancel_async($Context)

Cancel an asynchronous operation in progress

=over 4

=item Context

A previously prepared context generated by one of the xxx_setup_async functions above

=back

Returns 0 on success, < 0 on error (consult errno.h for explanation)

=cut

sub cancel_async {
    my $self = shift;
    $self->_assert_open();

    #
    # ($Context) = @_;
    #
    return libusb_cancel_async($_[0][0]);
    }

=item free_async($Context)

Free up resources allocated for the asynchrounous context

=over 4

=item Context

A previously prepared context generated by one of the xxx_setup_async functions above

=back

Returns 0 on success, < 0 on error (consult errno.h for explanation)

=cut

sub free_async {
    my $self = shift;
    $self->_assert_open();

    #
    # ($Context) = @_;
    #
    return libusb_free_async($_[0][0]);
    }

# Patch the new methods into the Device::USB::Device class.
{
    package Device::USB::Device;
    *free_async = \&Device::USB::Win32Async::free_async;
    *cancel_async = \&Device::USB::Win32Async::cancel_async;
    *reap_async_nocancel = \&Device::USB::Win32Async::reap_async_nocancel;
    *reap_async = \&Device::USB::Win32Async::reap_async;
    *submit_async = \&Device::USB::Win32Async::submit_async;
    *interrupt_setup_async = \&Device::USB::Win32Async::interrupt_setup_async;
    *bulk_setup_async = \&Device::USB::Win32Async::bulk_setup_async;
    *isochronous_setup_async = \&Device::USB::Win32Async::isochronous_setup_async;
    *ETIMEDOUT = \&Device::USB::Win32Async::ETIMEDOUT;
}

=item ETIMEDOUT

Constant representing a return from an asynchronous routine due to timeout.

=back

=head1 DEPENDENCIES

L<Carp>, L<Inline::C>, and L<Device::USB>.

Also depends on the libusb-win32 library.

=head1 AUTHOR

Rajstennaj Barrabas wrote the code.

The module is maintained by G. Wade Johnson (wade at anomaly dot org).

=head1 BUGS

Please report any bugs or feature requests to
C<bug-device-usb-win32async@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Device::USB::Win32Async>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 LIMITATIONS

This module depends on extensions to the libusb library added in the
LibUsb-Win32 library. As such, the module is only expected to work on a
Win32-based system.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Rajstennaj Barrabas

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0.

=cut

1;

__DATA__

__C__

#include <usb.h>

//unsigned DeviceUSBDebugLevel();           // Defined in Device::USB::USB.pm

int libusb_isochronous_setup_async(void *dev, SV *Context, unsigned char ep, int pktsize) {
    void *TempContext;                      // Place to received returned ptr

//    if( DeviceUSBDebugLevel() > 0 )
//        printf("libusb_isochronous_setup_async( %p, %u, %u //)\n",SvIVX(Context),ep,pktsize);

    int Status = usb_isochronous_setup_async((usb_dev_handle *)dev,&TempContext,
                                  ep, pktsize);
    SvIV_set(Context,(int) TempContext);    // Put ptr into perl var as int

    return Status;
    }

int libusb_bulk_setup_async(void *dev, SV *Context, unsigned char ep) {
    void *TempContext;                      // Place to received returned ptr

//    if( DeviceUSBDebugLevel() > 0 )
//        printf("libusb_bulk_setup_async( %p, %u )\n",SvIVX(Context),ep);

    int Status = usb_bulk_setup_async((usb_dev_handle *)dev,&TempContext, ep);

    SvIV_set(Context,(int) TempContext);    // Put ptr into perl var as int

    return Status;
    }

int libusb_interrupt_setup_async(void *dev, SV *Context, unsigned char ep) {
    void *TempContext;                      // Place to received returned ptr

//    if( DeviceUSBDebugLevel() > 0 )
//        printf("libusb_interrupt_setup_async( %p, %u )\n",SvIVX(Context),ep);

    int Status = usb_interrupt_setup_async((usb_dev_handle *)dev,&TempContext, ep);
    SvIV_set(Context,(int) TempContext);    // Put ptr into perl var as int

    return Status;
    }

int libusb_submit_async(void *context, SV *bytes, int size) {
    SvPOK_on(bytes);                        // Force perl var type to string
    char *Buffer = SvGROW(bytes,size);      // Grow to <size> bytes
    SvCUR_set(bytes,size);                  // Set length of string to <size>

    return usb_submit_async(context,SvPV_nolen(bytes),size);
    }

int libusb_reap_async(void *context, int timeout) {
    return usb_reap_async(context,timeout);
    }

int libusb_reap_async_nocancel(void *context, int timeout) {
    return usb_reap_async_nocancel(context,timeout);
    }

int libusb_cancel_async(void *context) {
    return usb_cancel_async(context);
    }

int libusb_free_async(void *context) {
    return usb_free_async(&context);
    }
