# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package Device::GPS;
$Device::GPS::VERSION = '0.714874475569562';
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;
use Device::GPS::Connection;

# ABSTRACT: Read GPS (NMEA) data over a wire

use constant {
    'CALLBACK_POSITION'     => '$GPGGA',
    'CALLBACK_ACTIVE_SATS'  => '$GPGSA',
    'CALLBACK_SATS_IN_VIEW' => '$GPGSV',
    'CALLBACK_REC_MIN'      => '$GPRMC',
    'CALLBACK_GEO_LOC'      => '$GPGLL',
    'CALLBACK_VELOCITY'     => '$GPVTG',
};

has 'connection' => (
    is       => 'ro',
    isa      => 'Device::GPS::Connection',
    required => 1,
);

has '_callbacks' => (
    is  => 'ro',
    isa => 'HashRef[ArrayRef[CodeRef]]',
    default => sub {{
        CALLBACK_POSITION     => [],
        CALLBACK_ACTIVE_SATS  => [],
        CALLBACK_SATS_IN_VIEW => [],
        CALLBACK_REC_MIN      => [],
        CALLBACK_GEO_LOC      => [],
        CALLBACK_VELOCITY     => [],
    }},
);


sub add_callback
{
    my ($self, $type, $callback) = @_;
    push @{ $self->_callbacks->{$type} }, $callback;
    return 1;
}

sub parse_next
{
    my ($self) = @_;
    my $sentence = $self->connection->read_nmea_sentence;
    return unless $sentence;
    my ($type, @data) = split /,/, $sentence;
    my $checksum = pop @data;
    # TODO verify checksum
    @data = $self->_convert_data_by_type( $type, @data );

    foreach my $callback (@{ $self->_callbacks->{$type} }) {
        $callback->(@data);
    }

    return 1;
}

sub _convert_data_by_type
{
    my ($self, $type, @data) = @_;
    $type =~ s/\A\$//;
    my $method = '_convert_data_for_' . $type;
    @data = $self->$method( @data ) if $self->can( $method );
    return @data;
}

sub _convert_data_for_GPGGA
{
    my ($self, @data) = @_;

    my $convert = sub {
        my ($datapoint) = @_;
        my ($deg, $arcmin, $arcsec) = $datapoint =~ /\A
            (\d{2,3})
            (\d{2})
            \.
            (\d+)
        \z/x;

        return ($deg, $arcmin, $arcsec);
    };

    splice @data, 3, 1, $convert->( $data[3] );
    splice @data, 1, 1, $convert->( $data[1] );
    return @data;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

  Device::GPS - Read GPS (NMEA) data over a wire

=head1 SYNOPSIS

    my $gps = Device::GPS->new({
        connection => Device::GPS::Connection::Serial->new({
            port => '/dev/ttyACM0',
            baud => 9600,
        }),
    });
    $gps->add_callback( $gps->CALLBACK_POSITION, sub {
        my ($time, $lat_deg, $lat_min, $lat_sec, $ns,
            $long_deg, $long_min, $long_sec, $ew,
            $quality, $satellites, $horz_dil, $altitude, $height, 
            $time_since_last_dgps, $dgps_station_id) = @_;
        say "Lat: $lat_deg deg $lat_min.$lat_sec' $ns";
        say "Long: $long_deg deg $long_min.$lat_sec' $ew";
    });


    while(1) { $gps->parse_next }

=head1 DESCRIPTION

Captures GPS data using a callback system.

=head1 METHODS

=head2 new

    my $gps = Device::GPS->new({
        connection => Device::GPS::Connection::Serial->new({
            port => '/dev/ttyACM0',
            baud => 9600,
        }),
    });

Constructor.  The C<connection> parameter needs to be some object that 
does the C<Device::GPS::Connection> role.

=head2 parse_next

Call this continually in a loop to get the next set of data.

=head2 add_callback

  add_callback( $callback_type, $callback )

Set a callback that will be called when we parse a given GPS command.  
There are constants provided for the types.  Below is a list of the 
constants and the arguments your callback will get for each one.

=head3 CALLBACK_POSITION (GPGGA)

  ($time, $lat_deg, $lat_min, $lat_sec, $ns,
      $long_deg, $long_min, $long_sec, $ew,
      $quality, $satellites, $horz_dil, $altitude, $height, 
      $time_since_last_dgps, $dgps_station_id);

=over

=item * time - Time of capture

=item * lat_deg - Latitude degrees

=item * lat_min - Latitude arcminutes

=item * lat_sec - Latitude arcseconds

=item * ns - "N" or "S" for latitude

=item * long_deg - Longitude degrees

=item * long_min - Longitude arcminutes

=item * long_sec - Longitude arcseconds

=item * ew - "E" or "W" for longitude

=item * quality - Quality number

=item * satellites - Number of satellites being tracked

=item * horz_dil - Horizontal dilution of position

=item * altitude - Altitude in meters above sealevel

=item * height - Height of geoid

=item * time_since_last_dgps - time (in seconds) since last DGPS update

=item * dgps_station_id - DGPS station ID number

=back

=head3 CALLBACK_VELOCITY (GPVTG)

  ($true_track, 'T', $mag_track, 'M', $ground_speed_knots, 'N',
      $ground_speed_kph, 'K');

=over

=item * true_track - True track made good (degrees)

=item * mag_track - Magnetic track made good

=item * ground_speed_knots - Ground speed in knots

=item * ground_speed_kph - Ground speed in kph

=back

=for TODO

CALLBACK_ACTIVE_SATS (GPGSA)
CALLBACK_SATS_IN_VIEW (GPGSV)
CALLBACK_REC_MIN (GPRMC)
CALLBACK_GEO_LOC (GPGLL)

=cut

=head1 SEE ALSO

L<GPS::NMEA>

=head1 LICENSE

Copyright (c) 2015  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

=cut
