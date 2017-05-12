use strict;
use warnings;

package Device::Altimeter::LPS331AP;

# PODNAME: Device::Altimeter::LPS331AP
# ABSTRACT: I2C interface to LPS331AP Altimeter using Device::SMBus
#
# This file is part of Device-LPS331AP
#
# This software is copyright (c) 2016 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.006'; # VERSION

# Dependencies
use 5.010;
use POSIX;

use Moose;
extends 'Device::SMBus';

# Registers for the Altimeter


use constant { CTRL_REG1 => 0x20, };

# X, Y and Z Axis magnetic Field Data value in 2's complement


use constant {
    PRESS_OUT_H  => 0x2a,
    PRESS_OUT_L  => 0x29,
    PRESS_OUT_XL => 0x28,

    TEMP_OUT_H => 0x2c,
    TEMP_OUT_L => 0x2b,
};


has '+I2CDeviceAddress' => (
    is      => 'ro',
    default => 0x5d,
);


sub enable {
    my ($self) = @_;
    $self->writeByteData( CTRL_REG1, 0b11100000 );
}


sub getRawReading {
    my ($self) = @_;

    return (
        pressure    => $self->readNBytes( PRESS_OUT_XL, 3 ),
        temperature => (
            $self->_typecast_int_to_int16(
                ( $self->readByteData(TEMP_OUT_H) << 8 ) |
                  $self->readByteData(TEMP_OUT_L)
            )
        ),
        temp => $self->readNBytes( TEMP_OUT_L, 2 ),
    );
}


sub getPressureMillibars {
    my ($self) = @_;
    return $self->readNBytes( PRESS_OUT_XL, 3 ) / 4096;
}


sub getPressureInchesHg {
    my ($self) = @_;
    return $self->readNBytes( PRESS_OUT_XL, 3 ) / 138706.5;
}


sub getPressureToAltitudeMeters {
    my ( $self, $pressure, $qnh ) = @_;
    $qnh |= 1013.25;
    my $altitude = ( 1 - ( ( $pressure / $qnh )**(0.190263) ) ) * 44330.8;
}


sub getTemperatureCelsius {
    my ($self) = @_;

    return 42.5 +
      $self->_typecast_int_to_int16( $self->readNBytes( TEMP_OUT_L, 2 ) ) / 480;
}


sub getTemperatureFahrenheit {
    my ($self) = @_;

    return 108.5 +
      $self->_typecast_int_to_int16( $self->readNBytes( TEMP_OUT_L, 2 ) ) /
      480 * 1.8;
}

sub _typecast_int_to_int16 {
    return unpack 's' => pack 'S' => $_[1];
}

sub _typecast_int_to_int32 {
    return unpack 'ss' => pack 'SS' => $_[1];
}


sub calibrate {
    my ($self) = @_;

}

1;

__END__

=pod

=head1 NAME

Device::Altimeter::LPS331AP - I2C interface to LPS331AP Altimeter using Device::SMBus

=head1 VERSION

version 0.006

=head1 ATTRIBUTES

=head2 I2CDeviceAddress

Contains the I2CDevice Address for the bus on which your altimeter is connected. It would look like 0x6b. Default is 0x5d.

=head1 METHODS

=head2 enable 

    $self->enable()

Initializes the device, Call this before you start using the device. This function sets up the appropriate default registers.
The Device will not work properly unless you call this function

CTRL_REG1
power: {0:off,1:on}
ODR2:output data rate
ODR1
ODR0
DIFF_EN: Interrupt generation{0:disabled,1:enabled}
BDU: Block Data Update{0:continuous update, 1: output registers not updated until MSB and LSB reading}
DELTA_EN: (1: delta pressure registers enabled. 0: disable)
SIM: SPI Serial Interface Mode selection (0: 4-wire interface; 1: 3-wire interface)
default = 1 111 0 1 1 0

=head2 getRawReading

    $self->getRawReading()

Return raw readings from registers

=head2 getPressureMillibars

Get pressure in Millibars

=head2 getPressureInchesHg

Get pressure in inches of mercury

=head2 getPressureToAltitudeMeters

converts pressure in mbar to altitude in meters, using 1976 US
Standard Atmosphere model (note that this formula only applies to a
height of 11 km, or about 36000 ft)
If altimeter setting (QNH, barometric pressure adjusted to sea
level) is given, this function returns an indicated altitude
compensated for actual regional pressure; otherwise, it returns
the pressure altitude above the standard pressure level of 1013.25
mbar or 29.9213 inHg

QNH is the Barometric pressure adjusted to sea level for a particular region. This value helps altitude corrections based on base barometric pressure in your region.

(a-((x/b)^c))*d;
d - (x^c)*(d/b^c);

=head2 getTemperatureCelsius

Get Temperature in degrees celsius

=head2 getTemperatureFahrenheit

Get Temperature in Fahrenheit

=head2 calibrate

Placeholder for a calibration function

=head1 REGISTERS

=head2 CTRL_REG1

=head2 PRESS_OUT_H

=head2 PRESS_OUT_L

=head2 PRESS_OUT_XL

=head2 TEMP_OUT_H

=head2 TEMP_OUT_L

=head1 AUTHOR

Shantanu Bhadoria <shantanu at cpan dott org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
