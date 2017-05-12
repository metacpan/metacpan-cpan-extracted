use Test::More 'no_plan';

use HTTP::MobileAgent::Plugin::Locator;

{
    my $orig_params = { lat => '35.21.03.342', lon => '138.34.45.725', geo => 'wgs84' };
    my $prepared_params = HTTP::MobileAgent::Plugin::Locator::_prepare_params( $orig_params );
    is_deeply $prepared_params, $orig_params;
}

