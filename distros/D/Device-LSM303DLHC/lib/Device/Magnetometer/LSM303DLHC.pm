use strict;
use warnings;

package Device::Magnetometer::LSM303DLHC;

# PODNAME: Device::Magnetometer::LSM303DLHC
# ABSTRACT: I2C interface to Magnetometer on the LSM303DLHC 3 axis magnetometer(compass) and accelerometer using Device::SMBus
#
# This file is part of Device-LSM303DLHC
#
# This software is copyright (c) 2016 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.014'; # VERSION

# Dependencies
use 5.010;
use POSIX;

use Moose;
extends 'Device::SMBus';


has '+I2CDeviceAddress' => (
    is      => 'ro',
    default => 0x1e,
);


# Registers for the Magnetometer
use constant { MR_REG_M => 0x02, };


# X, Y and Z Axis magnetic Field Data value in 2's complement
use constant {
    OUT_X_H_M => 0x03,
    OUT_X_L_M => 0x04,

    OUT_Y_H_M => 0x07,
    OUT_Y_L_M => 0x08,

    OUT_Z_H_M => 0x05,
    OUT_Z_L_M => 0x06,
};

has magnetometerMaxVector => (
    is      => 'rw',
    default => sub {
        return {
            x => 424,
            y => 295,
            z => 472,
        };
    },
);

has magnetometerMinVector => (
    is      => 'rw',
    default => sub {
        return {
            x => -421,
            y => -639,
            z => -238,
        };
    },
);


sub enable {
    my ($self) = @_;
    $self->writeByteData( MR_REG_M, 0x00 );
}


sub getRawReading {
    my ($self) = @_;

    return {
        x => $self->_typecast_int_to_int16(
            ( $self->readByteData(OUT_X_H_M) << 8 ) |
              $self->readByteData(OUT_X_L_M)
        ),
        y => $self->_typecast_int_to_int16(
            ( $self->readByteData(OUT_Y_H_M) << 8 ) |
              $self->readByteData(OUT_Y_L_M)
        ),
        z => $self->_typecast_int_to_int16(
            ( $self->readByteData(OUT_Z_H_M) << 8 ) |
              $self->readByteData(OUT_Z_L_M)
        ),
    };
}


sub getMagnetometerScale1 {
    my ($self)                = @_;
    my $rawReading            = $self->getRawReading;
    my $magnetometerMaxVector = $self->magnetometerMaxVector;
    my $magnetometerMinVector = $self->magnetometerMinVector;
    return {
        x => ( $rawReading->{x} - $magnetometerMinVector->{x} ) /
          ( $magnetometerMaxVector->{x} - $magnetometerMinVector->{x} ),
        y => ( $rawReading->{y} - $magnetometerMinVector->{y} ) /
          ( $magnetometerMaxVector->{y} - $magnetometerMinVector->{y} ),
        z => ( $rawReading->{z} - $magnetometerMinVector->{z} ) /
          ( $magnetometerMaxVector->{z} - $magnetometerMinVector->{z} ),
    };
}

sub _typecast_int_to_int16 {
    return unpack 's' => pack 'S' => $_[1];
}

1;

__END__

=pod

=head1 NAME

Device::Magnetometer::LSM303DLHC - I2C interface to Magnetometer on the LSM303DLHC 3 axis magnetometer(compass) and accelerometer using Device::SMBus

=head1 VERSION

version 0.014

=head1 ATTRIBUTES

=head2 I2CDeviceAddress

Contains the I2CDevice Address for the bus on which your Magnetometer is connected. It would look like 0x6b. Default is 0x1e.

=head1 METHODS

=head2 enable 

    $self->enable()

Initializes the device, Call this before you start using the device. This function sets up the appropriate default registers.
The Device will not work properly unless you call this function

=head2 getRawReading

    $self->getRawReading()

Return raw readings from accelerometer registers

=head2 getMagnetometerScale1

    $self->getMagnetometerScale1()

Return proper calculated readings from the magnetometer scaled between +0.5 and
-0.5

=head1 REGISTERS

=head2 MR_REG_M

=head2 OUT_X_H_M

=head2 OUT_X_L_M

=head2 OUT_Y_H_M

=head2 OUT_Y_L_M

=head2 OUT_Z_H_M

=head2 OUT_Z_L_M

=head1 AUTHOR

Shantanu Bhadoria <shantanu at cpan dott org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
