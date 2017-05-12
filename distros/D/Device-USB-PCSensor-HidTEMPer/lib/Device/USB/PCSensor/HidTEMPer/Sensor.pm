package Device::USB::PCSensor::HidTEMPer::Sensor;

use strict;
use warnings;

use Scalar::Util qw/ weaken /;

=head1

Device::USB::PCSensor::HidTEMPer::Sensor - Generic sensor class

=head1 VERSION

Version 0.0301

=cut

our $VERSION = 0.0301;

=head1 SYNOPSIS

None

=head1 DESCRIPTION

This module contains a generic class that all HidTEMPer sensors should inherit
from keeping the implemented methods consistent, and making it possible to 
use the same code to contact every supported device.

=head2 CONSTANTS

=over 3

=item * MAX_TEMPERATURE

The highest temperature(Celsius) this sensor can detect.

=cut

use constant MAX_TEMPERATURE    => 0;

=item * MIN_TEMPERATURE

The lowest temperature(Celsius) this sensor can detect.

=back

=cut

use constant MIN_TEMPERATURE    => 0;

=head2 METHODS

=over 3

=item * new( $device )

Generic initializing method, creating a sensor object.

Input parameter

$device = A pre-initialized Device::USB::PCSensor::HidTEMPer::Device that
the sensor is connected to. This device will be used to handle communication.

=cut

sub new
{
    my $class       = shift;
    my ( $unit )    = @_;
    
    # All devices are required to spesify the temperature range
    my $self    = {
        unit    => $unit,
    };
    
    weaken $self->{unit};
    
    bless $self, $class;
    return $self;
}

=item * fahrenheit()

Reads the current temperature and returns the corresponding value in 
fahrenheit degrees.

=cut

sub fahrenheit
{
    my $self    = shift;
	my $celsius = $self->celsius();
	$celsius = 0 unless defined $celsius;
    
    # Calculate and return the newly created degrees
    return ( ( $celsius * 9 ) / 5 ) + 32;
}

=item * max()

Returns the highest temperature(Celsius) the sensor can detect. 

=cut

sub max
{ 
    return $_[0]->MAX_TEMPERATURE;
}

=item * min()

Returns the lowest temperature(Celsius) the sensor can detect. 

=cut

sub min
{
    return $_[0]->MIN_TEMPERATURE;
}

=item * celsius()

Empty method that should be implemented in each sensor, returing the 
current degrees in celsius.

=cut

sub celsius { 
    return undef; 
}

=back

=head1 DEPENDENCIES

This module internally includes and takes use of the following packages:

  use Scalar::Util qw/ weaken /;

This module uses the strict and warning pragmas. 

=head1 BUGS

Please report any bugs or missing features using the CPAN RT tool.

=head1 FOR MORE INFORMATION

None

=head1 AUTHOR

Magnus Sulland < msulland@cpan.org >

=head1 ACKNOWLEDGEMENTS

Thanks to Elan Ruusamäe for fixing some compatibility issues with perl 5.8

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010-2011 Magnus Sulland

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;
