package HTTP::MobileAgent::Plugin::Locator::DoCoMo::GPS;
# GPS

use strict;
use base qw( HTTP::MobileAgent::Plugin::Locator );
use Geo::Coordinates::Converter;

sub get_location {
    my ( $self, $params ) = @_;
    my $lat   = $params->{ lat };
    my $lng   = $params->{ lon };
    my $datum = $params->{ geo };
    return Geo::Coordinates::Converter->new(
        lat   => $lat,
        lng   => $lng,
        datum => lc $datum,
    )->convert( 'wgs84' );
}

1;
