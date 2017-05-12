use strict;
use warnings;
use Test::More;
plan skip_all => "this module requires Geo::Coordinates::Converter && Geo::Coordinates::Converter::iArea" unless eval "use Geo::Coordinates::Converter; use Geo::Coordinates::Converter::iArea; 1;";
plan tests => 1;

use HTTP::MobileAttribute::Plugin::Locator;

{
    package Mock::ApacheRequest;
    sub new {
        my ( $class, $args ) = @_;
        bless { param => $args }, $class;
    }
    sub param {
        my $self = shift;
        if ( @_ == 0 ) {
            return keys %{ $self->{ param } };
        }
        elsif ( @_ == 1 ) {
            return $self->{ param }->{ $_[ 0 ] };
        }
    }
}

{
    local $ENV{HTTP_USER_AGENT} = 'DoCoMo/2.0 SH904i(c100;TB;W24H16)';
    my $orig_params = { lat => '35.21.03.342', lon => '138.34.45.725', geo => 'wgs84' };
    my $r = Mock::ApacheRequest->new( $orig_params );
    my $prepared_params = HTTP::MobileAttribute::Plugin::Locator::_prepare_params( $r );
    is_deeply $prepared_params, $orig_params;
}
