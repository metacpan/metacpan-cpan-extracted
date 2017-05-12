package Device::Temperature::TMP102;
use Moose;

our $VERSION = '0.0.8'; # VERSION

extends 'Device::SMBus';

has '+I2CDeviceAddress' => (
    is      => 'ro',
    default => 0x48,
);

has debug => (
    is      => 'ro',
    default => 0,
);

sub getTemp {
    my ( $self ) = @_;

    my $results = $self->readWordData( $self->I2CDeviceAddress );

    unless ( $results ) {
        die( "ERROR: failed to get temperature reading" );
    }

    if ( $results eq "-1" ) {
        die( "ERROR: got back an error code from I2C Device" );
    }

    return $self->convertTemp( $results );
}

sub convertTemp {
    my ( $self, $value ) = @_;

    my $lsb = ( $value & 0xff00 );
    $lsb = $lsb >> 8;

    my $msb = $value & 0x00ff;

    printf( "results: %04x\n", $value ) if $self->debug;
    printf( "msb:     %02x\n", $msb )   if $self->debug;
    printf( "lsb:     %02x\n", $lsb )   if $self->debug;

    my $temp = ( $msb << 8 ) | $lsb;

    # The TMP102 temperature registers are left justified, correctly
    # right justify them
    $temp = $temp >> 4;

    # test for negative numbers
    if ( $temp & ( 1 << 11 ) ) {

        # twos compliment plus one, per the docs
        $temp = ~$temp + 1;

        # keep only our 12 bits
        $temp &= 0xfff;

        # negative
        $temp *= -1;
    }

    # convert to a celsius temp value
    $temp = $temp / 16;

    return $temp;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Device::Temperature::TMP102 - I2C interface to TMP102 temperature sensor using Device::SMBus

=head1 SYNOPSIS

  use Device::Temperature::TMP102;

  my $device = shift @ARGV || '/dev/i2c-1';

  my $dev = Device::Temperature::TMP102->new( I2CBusDevicePath => $device );

  my $temp = $dev->getTemp();

  print "Temp:\n";
  printf ( "\t%2.2f C\n", $temp );
  printf ( "\t%2.2f F\n", $temp * 1.8 + 32 );


=head1 DESCRIPTION

Read temperature for a TMP102 temperature sensor over I2C.

This library correctly handles temperatures below freezing (0 degrees Celsius).

=head1 TROUBLESHOOTING

Check for your device on i2cbus 1 using the i2cdetect command, e.g.:

  $ i2cdetect -y 1

       0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
  00:          -- -- -- -- -- -- -- -- -- -- -- -- --
  10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  40: -- -- -- -- -- -- -- -- 48 -- -- -- -- -- -- --
  50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
  70: -- -- -- -- -- -- -- --

This indicates my TMP102 chip address is 0x48 on i2cbus 1.

Use the command-line tool i2cget to try to get a 12-bit reading from
the device, e.g.:

  $ i2cget -y 1 0x48 0x00 w
  0x2003

Refer to the documentation on L<Device::SMBus> for information on
enabling the i2c driver.

I also found this page to be helpful:

  http://donalmorrissey.blogspot.co.uk/2012/09/raspberry-pi-i2c-tutorial.html

In the process of testing this on raspberry pi, I saw this error:

  perl: symbol lookup error: .../Device/SMBus/SMBus.so: undefined symbol: i2c_smbus_write_byte

The fix was to install the package libi2c-dev.

=head1 SEE ALSO

  https://www.sparkfun.com/products/11931

  https://www.sparkfun.com/datasheets/Sensors/Temperature/tmp102.pdf

  http://donalmorrissey.blogspot.com/2012/09/raspberry-pi-i2c-tutorial.html

  https://github.com/sparkfun/Digital_Temperature_Sensor_Breakout_-_TMP102

=head1 SOURCE

With code and comments taken from example code for the ATmega328:

  http://www.sparkfun.com/datasheets/Sensors/Temperature/tmp102.zip

  /*
    TMP Test Code
    5-31-10
    Copyright Spark Fun Electronics 2010
    Nathan Seidle

    Example code for the TMP102 11-bit I2C temperature sensor

    You will need to connect the ADR0 pin to one of four places. This
    code assumes ADR0 is tied to VCC.  This results in an I2C address
    of 0x93 for read, and 0x92 for write.

    This code assumes regular 12 bit readings. If you want the
    extended mode for higher temperatures, the code will have to be
    modified slightly.

  */

=head1 VERSION

=head1 ATTRIBUTES

=head2 I2CDeviceAddress

Contains the I2CDevice Address for the bus on which your TMP102 is
connected. The default value is 0x48.

=head1 METHODS

=head2 getTemp()

    $self->getTemp()

Returns the current temperature, in degrees Celsius.

=head2 convertTemp()

    $self->convertTemp( $reading )

Given a value read from the TMP102, convert the value to degrees
Celsius.

=head1 LICENSE

This software is Copyright (c) 2014 by Alex White.

This is free software, licensed under:

  The (three-clause) BSD License

The BSD License

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

  * Neither the name of Alex White nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
