package HTTP::MobileAgent::Plugin::Locator::SoftBank::GPS;
# S!GPS

use strict;
use base qw( HTTP::MobileAgent::Plugin::Locator );
use Geo::Coordinates::Converter;

sub get_location {
    my ( $self, $params ) = @_;
    my ( $lat, $lng ) = $params->{ pos } =~ /^[NS]([\d\.]+)[EW]([\d\.]+)$/;
    my $datum = $params->{ geo } || 'wgs84';
    return Geo::Coordinates::Converter->new(
        lat   => $lat,
        lng   => $lng,
        datum => $datum,
    )->convert;
}

1;
