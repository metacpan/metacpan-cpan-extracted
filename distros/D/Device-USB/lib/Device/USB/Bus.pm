package Device::USB::Bus;

require 5.006;
use warnings;
use strict;
use Carp;

=encoding utf8

=head1 NAME

Device::USB::Bus - Use libusb to access USB devices.

=head1 VERSION

Version 0.38

=cut

our $VERSION=0.38;

=head1 SYNOPSIS

This class encapsulates the USB bus structure and provides methods for
retrieving data from it. This class is not meant to be used alone, it is
part of the Device::USB package.

Device:USB:LibUSB provides a Perl wrapper around the libusb library. This
supports Perl code controlling and accessing USB devices.

    use Device::USB;

    my $usb = Device::USB->new();

    foreach my $bus ($usb->list_busses())
    {
        print $bus->dirname(), ":\n";
        foreach my $dev ($bus->devices())
        {
            print "\t", $dev->filename(), "\n";
        }
    }


=head1 DESCRIPTION

This module provides a Perl interface to the bus structures returned by the
libusb library. This library supports a read-only interface to the data libusb
returns about a USB bus.

=head1 FUNCTIONS

=over 4

=item dirname

Return the directory name associated with this bus.

=cut

sub dirname
{
    my $self = shift;

    return $self->{dirname};
}

=item location

Return the location value associated with this bus.

=cut

sub location
{
    my $self = shift;

    return $self->{location};
}

=item devices

In array context, it returns a list of Device::USB::Device objects
representing all of the devices on this bus. In scalar context, it returns a
reference to that array.

=cut

sub devices
{
    my $self = shift;

    return wantarray ? @{$self->{devices}} : $self->{devices};
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

    local $_ = undef;

    foreach($self->devices())
    {
        return $_ if $pred->();
    }

    return;
}

=item list_devices_if
This method provides a flexible interface for finding devices. It
takes a single coderef parameter that is used to test each discovered
device. If the coderef returns a true value, the device is returned in the
list of matching devices, otherwise it is not.

=over 4

=item pred

coderef to test devices.

=back

For example,

    my @devices = $bus->list_devices_if(
        sub { Device::USB::CLASS_HUB == $_->bDeviceClass() }
    );

Returns all USB hubs found on this bus. The device to test is available to
the coderef in the C<$_> variable for simplicity.

=cut

sub list_devices_if
{
    my $self = shift;
    my $pred = shift;

    croak( "Missing predicate for choosing devices.\n" )
        unless defined $pred;

    croak( "Predicate must be a code reference.\n" )
        unless 'CODE' eq ref $pred;

    local $_ = undef;

    my @devices = grep { $pred->() } $self->devices();

    return wantarray ? @devices : \@devices;
}

=back

=head1 DIAGNOSTICS

This is an explanation of the diagnostic and error messages this module
can generate.

=head1 DEPENDENCIES

This module depends on the Carp and Device::USB, as well as
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

Thanks also go to Josep Monés Teixidor, Mike McCauley, and Tony Awtrey for
spotting, reporting, and (sometimes) fixing bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2013 Houston Perl Mongers

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
