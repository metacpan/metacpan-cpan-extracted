use strict;
use warnings;
use Test::More;
plan skip_all => "this module requires Geo::Coordinates::Converter && Geo::Coordinates::Converter::iArea" unless eval "use Geo::Coordinates::Converter; use Geo::Coordinates::Converter::iArea; 1;";
plan tests => 1;

use HTTP::MobileAttribute::Plugin::Locator;
use CGI;

{
    my $orig_params = { lat => '35.21.03.342', lon => '138.34.45.725', geo => 'wgs84' };
    my $q = CGI->new( $orig_params );
    my $prepared_params = HTTP::MobileAttribute::Plugin::Locator::_prepare_params( $q );
    is_deeply $prepared_params, $orig_params;
}
