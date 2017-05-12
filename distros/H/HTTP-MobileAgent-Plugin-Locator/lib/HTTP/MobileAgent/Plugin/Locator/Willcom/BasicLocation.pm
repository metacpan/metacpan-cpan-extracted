package HTTP::MobileAgent::Plugin::Locator::Willcom::BasicLocation;

use strict;
use base qw( HTTP::MobileAgent::Plugin::Locator );
use Geo::Coordinates::Converter;

sub get_location {
    my ( $self, $params ) = @_;
    my ( $lat, $lng ) = $params->{ pos } =~ /^N([^E]+)E(.+)$/;
    return Geo::Coordinates::Converter->new(
        lat   => $lat || undef,
        lng   => $lng || undef,
        datum => 'tokyo',
    )->convert( 'wgs84' );
}

1;
