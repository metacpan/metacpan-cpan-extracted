use strict;
use warnings;
package Device::Chip::MAX31855;

use base qw/Device::Chip/;

=head1 NAME

Device::Chip::MAX31855 - chip driver for MAX31855 thermocouple amplifier

=head1 SYNOPSIS

    use Device::Chip::MAX31855;
    my $chip = Device::Chip:MAX31855->new;
    $chip->mount(Device::Chip::Adapter::...->new)->get;
    
    my $temp = $chip->read_thermocouple()->get;

=head1 DESCRIPTION

Device::Chip::MAX31855 communicates with the MAX31855 SPI thermocouple amplifier.

The MAX31855 is a digital thermocouple amplifier and converter
containing a thermocouple measurement circuit, cold junction
compensator, and digital SPI interface. It provides temperature
measurements of an attached K-type thermocouple and the local cold
junction sensor, and can detect faults such as open circuit and short
to ground (reading faults is not implemented yet).

=cut

use constant PROTOCOL => 'SPI';

sub SPI_options {
    return ( mode => 0,
             max_bitrate => 1000000 );
}

sub _read_data {
    my $self = shift;

    my @bytes = unpack('C*', $self->protocol->read(4)->get);

    return ($bytes[0] << 24) + ($bytes[1] << 16) + ($bytes[2] << 8) + $bytes[3];
}

=head1 METHODS

=head2 read_thermocouple

Returns the termperature of the attached thermocouple in degrees Celsius.

=cut

sub read_thermocouple {
    my $self = shift;

    my $reg = $self->_read_data();

    my $temp = ($reg >> 18) & 0x3fff;
    $temp = -(16384 - $temp) if ($temp & 0x2000);
    $temp /= 4;

    Future->done($temp);
}

=head2 read_cold_junction

Returns the temperature of the local (cold) junction in degrees Celsius.

=cut

sub read_cold_junction {
    my $self = shift;

    my $reg = $self->_read_data();

    my $localtemp = ($reg >> 4) & 0xfff;
    $localtemp = -(4096 - $localtemp) if ($localtemp & 0x800);
    $localtemp /= 16;

    Future->done($localtemp);
}

=head1 AUTHOR

Stephen Cavilia <sac+cpan@atomicradi.us>

=cut

1;
