use strict;
use warnings;

package Device::Accelerometer::LSM303DLHC;

# PODNAME: Device::Accelerometer::LSM303DLHC
# ABSTRACT: I2C interface to Accelerometer on the LSM303DLHC 3 axis magnetometer(compass) and accelerometer using Device::SMBus
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
    default => 0x19,
);


use constant { PI => 3.14159265359, };


# Registers for the Accelerometer
use constant {
    CTRL_REG1_A => 0x20,
    CTRL_REG4_A => 0x23,
};


# X, Y and Z Axis magnetic Field Data value in 2's complement
use constant {
    OUT_X_H_A => 0x29,
    OUT_X_L_A => 0x28,

    OUT_Y_H_A => 0x2b,
    OUT_Y_L_A => 0x2a,

    OUT_Z_H_A => 0x2d,
    OUT_Z_L_A => 0x2c,
};


has 'gCorrectionFactor' => (
    is      => 'ro',
    default => 256
);


has 'gravitationalAcceleration' => (
    is      => 'ro',
    default => 9.8
);


has 'mssCorrectionFactor' => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_mssCorrectionFactor {
    my ($self) = @_;
    $self->gCorrectionFactor / $self->gravitationalAcceleration;
}


sub enable {
    my ($self) = @_;
    $self->writeByteData( CTRL_REG1_A, 0b01000111 );
    $self->writeByteData( CTRL_REG4_A, 0b00101000 );
}


sub getRawReading {
    my ($self) = @_;

    use integer
      ; # Use arithmetic right shift instead of unsigned binary right shift with >> 4
    my $retval = {
        x => (
            $self->_typecast_int_to_int16(
                ( $self->readByteData(OUT_X_H_A) << 8 ) |
                  $self->readByteData(OUT_X_L_A)
            )
          ) >> 4,
        y => (
            $self->_typecast_int_to_int16(
                ( $self->readByteData(OUT_Y_H_A) << 8 ) |
                  $self->readByteData(OUT_Y_L_A)
            )
          ) >> 4,
        z => (
            $self->_typecast_int_to_int16(
                ( $self->readByteData(OUT_Z_H_A) << 8 ) |
                  $self->readByteData(OUT_Z_L_A)
            )
        ) >> 4,
    };
    no integer;

    return $retval;
}


sub getAccelerationVectorInG {
    my ($self) = @_;

    my $raw = $self->getRawReading;
    return {
        x => ( $raw->{x} ) / $self->gCorrectionFactor,
        y => ( $raw->{y} ) / $self->gCorrectionFactor,
        z => ( $raw->{z} ) / $self->gCorrectionFactor,
    };
}


sub getAccelerationVectorInMSS {
    my ($self) = @_;

    my $raw = $self->getRawReading;
    return {
        x => ( $raw->{x} ) / $self->mssCorrectionFactor,
        y => ( $raw->{y} ) / $self->mssCorrectionFactor,
        z => ( $raw->{z} ) / $self->mssCorrectionFactor,
    };
}


sub getAccelerationVectorAngles {
    my ($self) = @_;

    my $raw = $self->getRawReading;

    my $rawR =
      sqrt( $raw->{x}**2 + $raw->{y}**2 + $raw->{z}**2 );    #Pythagoras theorem
    return {
        Axr => _acos( $raw->{x} / $rawR ),
        Ayr => _acos( $raw->{y} / $rawR ),
        Azr => _acos( $raw->{z} / $rawR ),
    };
}


sub getRollPitch {
    my ($self) = @_;

    my $raw = $self->getRawReading;

    return {
        Roll  => atan2( $raw->{x}, $raw->{z} ) + PI,
        Pitch => atan2( $raw->{y}, $raw->{z} ) + PI,
    };
}

sub _acos {
    atan2( sqrt( 1 - $_[0] * $_[0] ), $_[0] );
}

sub _typecast_int_to_int16 {
    return unpack 's' => pack 'S' => $_[1];
}


sub calibrate {
    my ($self) = @_;

}

1;

__END__

=pod

=head1 NAME

Device::Accelerometer::LSM303DLHC - I2C interface to Accelerometer on the LSM303DLHC 3 axis magnetometer(compass) and accelerometer using Device::SMBus

=head1 VERSION

version 0.014

=head1 ATTRIBUTES

=head2 I2CDeviceAddress

Contains the I2CDevice Address for the bus on which your Accelerometer is connected. It would look like 0x6b. Default is 0x19.

=head2 gCorrectionFactor

This is a correction factor for converting raw values of acceleration in units of g or gravitational acceleration. It depends on the sensitivity set in the registers.

=head2 gravitationalAcceleration

This is the acceleration due to gravity in meters per second square usually represented as g. default on earth is around 9.8 although it differs from 9.832 near the poles to 9.780 at equator. This might also be different if you are on a different planet or in space.

=head2 mssCorrectionFactor

This attribute is built from the above two attributes automatically. This is usually gCorrectionFactor divided by gravitationalAcceleration. This is the inverse of relation between raw accelerometer values and its value in meters per seconds.

=head1 METHODS

=head2 enable 

    $self->enable()

Initializes the device, Call this before you start using the device. This function sets up the appropriate default registers.
The Device will not work properly unless you call this function

=head2 getRawReading

    $self->getRawReading()

Return raw readings from accelerometer registers

=head2 getAccelerationVectorInG

returns four acceleration vectors with accelerations in multiples of g - (9.8 meters per second square)
note that even when stationary on the surface of earth(or a earth like planet) there is a acceleration vector g that applies perpendicular to the surface of the earth pointing opposite of the surface. 

=head2 getAccelerationVectorInMSS

returns four acceleration vectors with accelerations in meters per second square
note that even when stationary on the surface of earth(or a earth like planet) there is a acceleration vector g that applies perpendicular to the surface of the earth pointing opposite of the surface. 

=head2 getAccelerationVectorAngles

returns  coordinate angles between the acceleration vector(R) and the cartesian Coordinates(x,y,z). 

=head2 getRollPitch

returns  Roll and Pitch from the accelerometer. This is a bare reading from accelerometer and it assumes gravity is the only force on the accelerometer, which means it will be quiet inaccurate for a accelerating accelerometer.

=head2 calibrate

placeholder for calibration function

=head1 REGISTERS

=head2 CTRL_REG1_A

=head2 CTRL_REG4_A

=head2 OUT_X_H_A

=head2 OUT_X_L_A

=head2 OUT_Y_H_A

=head2 OUT_Y_L_A

=head2 OUT_Z_H_A

=head2 OUT_Z_L_A

=head1 CONSTANTS

=head2 PI

=head1 AUTHOR

Shantanu Bhadoria <shantanu at cpan dott org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
