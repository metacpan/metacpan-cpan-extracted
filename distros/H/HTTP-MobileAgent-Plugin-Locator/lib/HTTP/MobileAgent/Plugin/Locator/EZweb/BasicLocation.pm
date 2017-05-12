package HTTP::MobileAgent::Plugin::Locator::EZweb::BasicLocation;
# Simple Location Information

use strict;
use base qw( HTTP::MobileAgent::Plugin::Locator );
use Geo::Coordinates::Converter;

sub get_location {
    my ( $self, $params ) = @_;
    my $lat = $params->{ lat };
    my $lng = $params->{ lon };
    my $datum = $params->{ datum } || 'wgs84';
    my $format = $params->{ unit } || 'dms';
    return Geo::Coordinates::Converter->new(
        lat    => $lat,
        lng    => $lng,
        datum  => $datum,
        format => $format,
    )->convert;
}

1;
