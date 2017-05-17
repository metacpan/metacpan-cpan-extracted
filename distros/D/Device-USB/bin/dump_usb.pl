#!/usr/bin/perl

use Device::USB;
use Data::Dumper;
use Carp;
use strict;
use warnings;


=head1 NAME

dump_usb.pl - Use Device::USB to list USB devices.

=head1 VERSION

Version 0.37

=cut

our $VERSION=0.37;

=head1 SYNOPSIS

The C<dump_usb.pl> program provides a relatively crude dump of the information
available from any USB devices installed on the system.

=head1 DESCRIPTION

This module provides a Perl interface to the C library libusb. This library
supports a relatively full set of functionality to access a USB device. In
addition to the libusb, functioality, Device::USB provides a few
convenience features that are intended to produce a more Perl-ish interface.

If called without arguments, the program lists all installed USB devices on
all busses. This is just a Data::Dumper dump of the structures, so it is not
the most user friendly output in the world. (However, the program was only
intended as a I<quick hack> to verify that Device::USB was working.)

If called with arguments, they are expected to be a vendor id and a product id.
(These arguments can be in hex if you precede them with C<0x>.) The program
searches for a device that matches that vendor id and product id. If it finds
one, the device I<filename> is printed, along with the vendor and product ids.

If the program can open the device, it will also print the manufacture name
and product name as reported by the device.

=cut

my $usb = Device::USB->new();
$Data::Dumper::Indent = 1; ## no critic(ProhibitPackageVars)

if(@ARGV)
{
    my $dev = $usb->find_device( map { /^0/xm ? oct( $_ ) : $_ } @ARGV[0,1] );
    croak "Device not found.\n" unless defined $dev;

    print "Device found: ", $dev->filename(), ": ";
    printf "ID %04x:%04x\n", $dev->idVendor(), $dev->idProduct();
    if($dev->open())
    {
        print "\t", $dev->manufacturer(), ": ", $dev->product(), "\n";
        print Dumper( $dev );
    }
    else
    {
        print "Unable to open device.\n";
    }
}
else
{
    print Dumper( [ $usb->list_busses() ] );
}

=head1 DEPENDENCIES

This module depends on the Device::USB and Data::Dumper modules, as
well as the strict and warnings pragmas. Obviously, libusb must be available
for Device::USB to function.

=head1 AUTHOR

G. Wade Johnson (wade at anomaly dot org)
Paul Archer (paul at paularcher dot org)

Houston Perl Mongers Group

=head1 BUGS

The output format is extremely non-friendly.

The program only returns the first matching USB device.

Please report any bugs or feature requests to
C<bug-maze-svg1@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Device::USB>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Thanks go to various members of the Houston Perl Mongers group for input
on the module. But thanks mostly go to Paul Archer who proposed the project
and helped with the development.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Houston Perl Mongers

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
