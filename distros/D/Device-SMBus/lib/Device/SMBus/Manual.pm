use strict;
use warnings;

package Device::SMBus::Manual;

# PODNAME: Device::SMBus::Manual
# ABSTRACT: Manual for writing device drivers using L<Device::SMBus>
#
# This file is part of Device-SMBus
#
# This software is copyright (c) 2016 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '1.15'; # VERSION

1;

__END__

=pod

=head1 NAME

Device::SMBus::Manual - Manual for writing device drivers using L<Device::SMBus>

=head1 VERSION

version 1.15

=head1 DESCRIPTION

This manual describes the process for writing your own modules for specific devices using Device::SMBus. For real world examples refer to L<Device::LSM303DLHC>, L<Device::LPS331AP>, L<Device:L3GD20> or L<Device::PCA9685>.

=head1 FIGURING OUT YOUR DEVICE

i2c device control usually starts and ends with writingE<sol>reading specific registers on a tiny chipset to either read some data or make the device that you are working with perform specific actions. 

Each i2c chipset shows up at a specific two byte i2c device address once connected properly. To get the address for your device, refer the chipset manual for the device or if unavailable connect it to your development board and see which address your device shows up using the following command :

     $ i2cdetect -y 1
 
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
     00:          -- -- -- -- -- -- -- -- -- -- -- -- --
     10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     40: -- -- -- -- -- -- -- 47 -- -- -- -- -- -- -- --
     50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     70: -- -- -- -- -- -- -- --

The device address is in hex i.e. 0x47 is the device address in the above result. If the above command doesn't work(Angstrom on Beaglebone Black) you can use -r instead

     $ i2c-detect -r 1
 
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
     00:          -- -- -- -- -- -- -- -- -- -- -- -- --
     10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     40: -- -- -- -- -- -- -- 47 -- -- -- -- -- -- -- --
     50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     70: -- -- -- -- -- -- -- --

Note that the 1 here refers to the i2c device file number for the i2c connectors where your device is connected. You can see the list of i2c devices with the following command:

     ls -l /dev/i2c*
 
     /dev/i2c-0
     /dev/i2c-1

Now you know your device address, refer the manual for your device to know the register numbers to read or write to. I will use LSM303DLHC as my example and show you how I built the driver for it from scratch. You can read the see the module on CPAN in L<Device::LSM303DLHC>.

LSM303DLHC is a 3 axis magnetometer and accelerometer chip that is found in quiet a few IMU boards like the pololu AltIMU. This chip is a good example to keep in mind because it sports two sensors on distinct addresses. The compass(magnetometer) provides readings for angular orientation along the three axis, while the accelerometer provides the direction of acceleration. For stationary objects near gravitationally significant planetary bodies like earth, the acceleration is equal to g(9.8 meters per seconds square) and it points in the direction opposite of the direction to gravitational center i.e for a stationary body on earth the accelerometer will show a acceleration pointing straight up into the sky. This is a useful set of orientation data to be used in robotics and controller systems. I bought the AltIMU and had a raspberry Pi to connect it on.

As a first step I connect the AltIMU to the raspberry Pi and try to find the address for the gyroscope:

     $ i2cdetect -y 1
 
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
     00:          -- -- -- -- -- -- -- -- -- -- -- -- --
     10: -- -- -- -- -- -- -- -- -- 19 -- UU -- -- 1e --
     20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     30: -- -- -- -- -- -- -- -- -- -- -- UU -- -- -- --
     40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
     50: -- -- -- -- -- -- -- -- -- -- -- -- -- 5d -- --
     60: -- -- -- -- -- -- -- -- -- -- -- 6b -- -- -- --
     70: -- -- -- -- -- -- -- --

Aha the AltIMU has four chipsets on it, the L3GD20 gyroscope(0x6b), LSM303DLHC magnetometer(0x1e) and accelerometer(0x19), LPS331AP thermometer and barometer(both on 0x20). I got the addresses from the user manuals for each chipset on AltIMU.

We are only concerned with LSM303DLHC here so we will ignore the other chipsets on the board.

To provide third party controller programs a mechanism to look for available drivers for a particular type of sensor we should try to put all the sensors of a particular type in their own namespaces i.e. L3GD20 Gyroscope is place in Device::Gyroscope::* namespace on account of it being a gyroscope. This way autopilot and other programs can look for gyroscopes by simply looking at modules installed in that namespace using L<Class::MOP> and load them and see if the device is available using functions with in the module. When there is a Gyroscope like the L3GD20 connected it automatically detects the gyroscope as long as the driver module for L3GD20([Device::Gyroscope::L3GD20] as part of L<Device::L3GD20> package) is installed.

In LSM303DLHC we have a Magnetometer and Accelerometer onboard so we will use two namespaces in the module Device::Magnetometer::* and Device::Accelerometer::* . This means that the module L<Device::LSM303DLHC> that we will create will have two additional packages : L<Device::Magnetometer::LSM303DLHC> and L<Device::Accelerometer::LSM303DLHC>

Lets start by defining the package L<Device::LSM303DLHC>. This is a small package that contains attributes that are objects of its constituent sensor modules for the Accelerometer and the Magnetometer.

     use strict;
     use warnings;
     package Device::LSM303DLHC;
 
     use Moo;
     extends 'Device::SMBus';
 
     # We will define these two modules in the next steps 
     use Device::Magnetometer::LSM303DLHC; 
     use Device::Accelerometer::LSM303DLHC;
 
     has 'I2CBusDevicePath' => (
         is       => 'ro',
         required => 1,
     );
 
     # This attribute contains an object of Device::Magnetometer::LSM303DLHC
     has Magnetometer => (
         is => 'ro',
         isa => 'Device::Magnetometer::LSM303DLHC',
         lazy_build => 1,
     );
 
     # Lazy build function for building the Magnetometer attribute when used
     sub _build_Magnetometer {
         my ($self) = @_;
         my $obj = Device::Magnetometer::LSM303DLHC->new(
             I2CBusDevicePath => $self->I2CBusDevicePath
         );
         return $obj;
     }
 
     # This attribute contains an object of Device::Accelerometer::LSM303DLHC
     has Accelerometer => (
         is => 'ro',
         isa => 'Device::Accelerometer::LSM303DLHC',
         lazy_build => 1,
     );
 
     # Lazy build function for building the Accelerometer attribute when used
     sub _build_Accelerometer {
         my ($self) = @_;
         my $obj = Device::Accelerometer::LSM303DLHC->new(
             I2CBusDevicePath => $self->I2CBusDevicePath
         );
         return $obj;
     }
 
     1;

Next we will define the accelerometer module in the Device::Accelerometer namespace. We will call it L<Device::Accelerometer::LSM303DLHC> because we are sticking to the convention of calling the package by the name of the chipset. This is also because we want our auto load program to know which chipset it is using for accelerometer data reading from its name.

     use strict;
     use warnings;
     package Device::Accelerometer::LSM303DLHC;
 
     use POSIX;
 
     use Moo;
     extends 'Device::SMBus';
 
     has '+I2CDeviceAddress' => (
         is      => 'ro',
         default => 0x19,
     );
 
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
         $self->gCorrectionFactor/$self->gravitationalAcceleration;
     }
 
     use constant {
         PI => 3.14159265359,
     };
 
     # Registers to read for the Accelerometer, get this from the chipset manual 
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
 
     sub enable {
         my ($self) = @_;
         $self->writeByteData(CTRL_REG1_A,0b01000111);
         $self->writeByteData(CTRL_REG4_A,0b00101000);
     }
 
     sub getRawReading {
         my ($self) = @_;
 
         use integer; # Use arithmetic right shift instead of unsigned binary right shift with >> 4
         my $retval = {
             x => ( $self->_typecast_int_to_int16( ($self->readByteData(OUT_X_H_A) << 8) | $self->readByteData(OUT_X_L_A) ) ) >> 4,
             y => ( $self->_typecast_int_to_int16( ($self->readByteData(OUT_Y_H_A) << 8) | $self->readByteData(OUT_Y_L_A) ) ) >> 4,
             z => ( $self->_typecast_int_to_int16( ($self->readByteData(OUT_Z_H_A) << 8) | $self->readByteData(OUT_Z_L_A) ) ) >> 4,
         };
         no integer;
 
         return $retval;
     }
 
     sub getAccelerationVectorInG {
         my ($self) = @_;
 
         my $raw = $self->getRawReading;
         return {
             x => ($raw->{x})/$self->gCorrectionFactor,
             y => ($raw->{y})/$self->gCorrectionFactor,
             z => ($raw->{z})/$self->gCorrectionFactor,
         };
     }
 
     sub getAccelerationVectorInMSS {
         my ($self) = @_;
 
         my $raw = $self->getRawReading;
         return {
             x => ($raw->{x})/$self->mssCorrectionFactor,
             y => ($raw->{y})/$self->mssCorrectionFactor,
             z => ($raw->{z})/$self->mssCorrectionFactor,
         };
     }
 
     sub getAccelerationVectorAngles {
         my ($self) = @_;
 
         my $raw = $self->getRawReading;
 
         my $rawR = sqrt($raw->{x}**2+$raw->{y}**2+$raw->{z}**2); #Pythagoras theorem
         return {
             Axr => _acos($raw->{x}/$rawR),
             Ayr => _acos($raw->{y}/$rawR),
             Azr => _acos($raw->{z}/$rawR),
         };
     }
 
     sub getRollPitch {
         my ($self) = @_;
 
         my $raw = $self->getRawReading;
 
         return {
             Roll  => atan2($raw->{x},$raw->{z})+PI,
             Pitch => atan2($raw->{y},$raw->{z})+PI,
         };
     }
 
     sub _acos { 
         atan2( sqrt(1 - $_[0] * $_[0]), $_[0] ) 
     }
     sub _typecast_int_to_int16 {
         return  unpack 's' => pack 'S' => $_[1];
     }
 
     1;

Do not get intimidated by the longer piece of code. A lot of this is just mathematical functions and typecast functions to convert register bit data to human readable values.

In the entire code we can sum up our steps as follows:

=over

=item 1.

define the enable function for LSM303DLHC magnetometer which requires us to set two registers defined by CTRL_REG1_A and CTRL_REG4_A.

=item 2.

Read raw register data(2 bytes per coordinate axis) OUT_X_H_A, OUT_X_L_A, OUT_Y_H_A, OUT_Y_L_A, OUT_Z_H_A, OUT_Z_L_A. Each register stores a single byte so make sure to get both high and low bytes for each coordinate.

=item 3.

once you have the register values combine high and low bytes to get a full reading for each coordinate.

=item 4.

use the raw values in other functions to return the values in a different form AccelerationVectorInG, AccelerationVectorInMSS(meters per second square), AccelerationVectorAngles Roll & Pitch 

=back

The register addresses and the values we must set for them can be seen in the manual for LSM303DLHC L<https://www.pololu.com/file/0J703/LSM303D.pdf>.

We can now write the second module to read magnetometer data.

     use strict;
     use warnings;
     package Device::Magnetometer::LSM303DLHC;
 
     use POSIX;
 
     use Moo;
     extends 'Device::SMBus';
 
     has '+I2CDeviceAddress' => (
         is      => 'ro',
         default => 0x1e,
     );
 
     use constant {
         MR_REG_M    => 0x02,
     };
 
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
         $self->writeByteData(MR_REG_M,0x00);
     }
     sub getRawReading {
         my ($self) = @_;
 
         return {
             x => $self->_typecast_int_to_int16( ($self->readByteData(OUT_X_H_M) << 8) | $self->readByteData(OUT_X_L_M) ),
             y => $self->_typecast_int_to_int16( ($self->readByteData(OUT_Y_H_M) << 8) | $self->readByteData(OUT_Y_L_M) ),
             z => $self->_typecast_int_to_int16( ($self->readByteData(OUT_Z_H_M) << 8) | $self->readByteData(OUT_Z_L_M) ),
         };
     }
 
     sub getMagnetometerScale1 {
         my ($self) = @_;
         my $rawReading            = $self->getRawReading;
         my $magnetometerMaxVector = $self->magnetometerMaxVector;
         my $magnetometerMinVector = $self->magnetometerMinVector;
         return {
             x => ($rawReading->{x} - $magnetometerMinVector->{x})
                 / ($magnetometerMaxVector->{x} - $magnetometerMinVector->{x}),
             y => ($rawReading->{y} - $magnetometerMinVector->{y})
                 / ($magnetometerMaxVector->{y} - $magnetometerMinVector->{y}),
             z => ($rawReading->{z} - $magnetometerMinVector->{z})
                 / ($magnetometerMaxVector->{z} - $magnetometerMinVector->{z}),
         };
     }
 
     sub _typecast_int_to_int16 {
         return  unpack 's' => pack 'S' => $_[1];
     }
 
     1;

This package does a similar job as previous one, reading magnetic north direction along 3 axis coordinates. This module implements a few mathematical functions to convert magnetic north vector to scale of 1(unit vector) for ease of calculations.

This is it, that is basiclly how you go about writing drivers for a i2c device using L<Device::SMBus>. Hope that was helpful and it helps you write your own drivers for the i2c chipsets you use for your robotics projects.

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
