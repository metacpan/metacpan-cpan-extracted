package Device::USB::PCSensor::HidTEMPer::TEMPer2::Internal;

use strict;
use warnings;

use Device::USB::PCSensor::HidTEMPer::Sensor;
our @ISA = 'Device::USB::PCSensor::HidTEMPer::Sensor';

=head1

Device::USB::PCSensor::HidTEMPer::TEMPer2::Internal - The HidTEMPer2 internal sensor

=head1 VERSION

Version 0.01

=cut

our $VERSION = 0.01;

=head1 SYNOPSIS

None

=head1 DESCRIPTION

This is the implementation of the HidTEMPer2 internal sensor.

=head2 CONSTANTS

=over 3

=item * MAX_TEMPERATURE

The highest temperature(120 degrees celsius) this sensor can detect.

=cut

use constant MAX_TEMPERATURE    => 120;

=item * MIN_TEMPERATURE

The lowest temperature(-40 degrees celsius) this sensor can detect.

=back

=cut

use constant MIN_TEMPERATURE    => -40;

=head2 METHODS

=over 3

=item * celsius()

Returns the current temperature from the device in celsius degrees.

=cut

sub celsius
{
    my $self    = shift;
    my @data    = ();
    my $reading = 0;
    
    # Command 0x54 will return the following 8 byte result, repeated 4 times.
    # Position 0: Signed int returning the main temperature reading
    # Position 1: Unsigned int divided by 256 to give presision.
    # Position 2: unknown
    # Position 3: unused
    # Position 4: unused
    # Position 5: unused
    # Position 6: unused
    # Position 7: unused
    
    # First reading
    @data       = $self->{unit}->_read( 0x54 );
    $reading    = ($data[0] < 128) ? $data[0] + ( $data[1] / 256 ) : ($data[0] - 255) - ( $data[1] / 256 );
    
    # Secound reading
    @data       = $self->{unit}->_read( 0x54 );
    $reading    += ($data[0] < 128) ? $data[0] + ( $data[1] / 256 ) : ($data[0] - 255) - ( $data[1] / 256 );

    # Return the average, this adds precision
    return $reading / 2;
}

=back

=head1 INHERIT METHODS FROM

Device::USB::PCSensor::HidTEMPer::Sensor

=head1 DEPENDENCIES

This module internally includes and takes use of the following packages:

  use Device::USB::PCSensor::HidTEMPer::Sensor;

This module uses the strict and warning pragmas. 

=head1 BUGS

Please report any bugs or missing features using the CPAN RT tool.

=head1 FOR MORE INFORMATION

None

=head1 AUTHOR

Daniel Fahlgren

(Based on code by Magnus Sulland < msulland@cpan.org >)

=head1 ACKNOWLEDGEMENTS

Thanks to Jean F. Delpech for the temperature fix that solves the problem
with temperatures bellow 0 Celsius.


This code is inspired by Relavak's source code and the comments found 
at: http://relavak.wordpress.com/2009/10/17/
temper-temperature-sensor-linux-driver/

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2011 Magnus Sulland

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
