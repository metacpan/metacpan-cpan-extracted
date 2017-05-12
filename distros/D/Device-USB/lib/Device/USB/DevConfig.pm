package Device::USB::DevConfig;

require 5.006;
use warnings;
use strict;
use Carp;

=head1 Device::USB::DevConfig

This class encapsulates a USB Device Configuration and the methods that
object would support.

=head1 NAME

Device::USB::DevConfig - Access the device configuration returned by libusb.

=head1 VERSION

Version 0.36

=cut

our $VERSION=0.36;

=head1 SYNOPSIS

Device::USB:DevConfig provides a Perl object for accessing a configuration
of a USB device using the libusb library.

    use Device::USB;

    my $usb = Device::USB->new();
    my $dev = $usb->find_device( $VENDOR, $PRODUCT );

    printf "Device: %04X:%04X\n", $dev->idVendor(), $dev->idProduct();
    $dev->open();

    my $cfg = $dev->config()->[0];
    print "Config:", $cfg->iConfiguration(), ": interface count: ",
       $cfg->nNumInterfaces(), "\n";

See USB specification for an explanation of the attributes of a
configuration.

=head1 DESCRIPTION

This module defines a Perl object that represents the data associated with
a USB device's configuration. The object provides read-only access to the
important data associated with the configuration. 

=head2 METHODS

There are several accessor methods that return data from the configuration.
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

=item wTotalLength

Returns the total length of the data returned for this configuration.

=item bNumInterfaces

Returns the number of interfaces supported by this configuration.

=item interfaces

Returns a list of lists of interface objects associated with this
configuration. Each of the inner lists is a set of alternate versions
of that interface.

=cut

sub interfaces
{
    my $self = shift;
    return wantarray ? @{$self->{interfaces}} : $self->{interfaces};
}

=item bConfigurationValue

Returns the value passed to SetConfiguration to select this configuration.

=item iConfiguration

Returns the index of the string descriptor describing this configuration.
The string can be retrieved using the method
C<Device::USB::Device::get_string_simple>.

=item bmAttributes

Returns a bitmap listing the attributes. The bits a number starting with
the LSB as 0. Bit 6 is 1 if the device is self-powered. Bit 5 is 1 if the
device supports Remote Wakeup.

=item MaxPower

Returns the Maximum power consumption in mA. This value is not in units of
2mA as in the spec, but in actual mA.

=back

=cut

_make_descr_accessor( 'wTotalLength' );
_make_descr_accessor( 'bNumInterfaces' );
_make_descr_accessor( 'bConfigurationValue' );
_make_descr_accessor( 'iConfiguration' );
_make_descr_accessor( 'bmAttributes' );
_make_descr_accessor( 'MaxPower' );


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
