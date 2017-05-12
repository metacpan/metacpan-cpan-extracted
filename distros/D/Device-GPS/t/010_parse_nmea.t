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
use Test::More tests => 4;
use v5.14;
use Device::GPS;
use Device::GPS::Connection;
use lib 't/lib';
use ConnectionMock;

my @SENTENCES = (
    '$GPGGA,123519,4807.038,N,01131.000,E,8,08,0.9,545.4,M,46.9,M,,*47',
    '$GPVTG,054.7,T,034.4,M,005.5,N,010.2,K*48',
);

my $connection = ConnectionMock->new({
    sentences => \@SENTENCES,
});

my $gps = Device::GPS->new({
    connection => $connection,
});
isa_ok( $gps => 'Device::GPS' );


$gps->add_callback( $gps->CALLBACK_POSITION, sub {
    my ($time, $lat_deg, $lat_min, $lat_sec, $ns,
        $long_deg, $long_min, $long_sec, $ew,
        $quality, $satellites, $horz_dil, $altitude, $height, 
        $time_since_last_dgps, $dgps_station_id) = @_;
    # Check within acceptable floating point error
    note( "Lat: $lat_deg\N{U+00B0} $lat_min.$lat_sec' $ns" );
    note( "Long: $long_deg\N{U+00B0} $long_min.$lat_sec' $ew" );
    is_deeply({
        deg => $lat_deg,
        min => $lat_min,
        sec => $lat_sec,
    }, {
        deg => '48',
        min => '07',
        sec => '038',
    });
    is_deeply({
        deg => $long_deg,
        min => $long_min,
        sec => $long_sec,
    }, {
        deg => '011',
        min => '31',
        sec => '000',
    });
});
$gps->add_callback( $gps->CALLBACK_VELOCITY, sub {
    my ($true_track, undef, $mag_track, undef, $ground_speed_knots, undef,
        $ground_speed_kph, undef) = @_;
    cmp_ok( $ground_speed_kph, '==', 10.2, "Ground speed kph correct" );
});

$gps->parse_next for 0 .. $#SENTENCES;
