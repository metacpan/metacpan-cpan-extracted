use strict;
use warnings;

use Test::More;
use Geo::Coder::GooglePlaces;

plan tests => 7;

{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, components => { country => 'GB' } );
    is($geocoder->_get_components_query_params, 'country:GB', 'filter country = GB');
}

{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, components => { route => 'route 55' });
    is($geocoder->_get_components_query_params, 'route:route 55', 'filter route = route 55');
}

{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, components => { administrative_area => 'TX' });
    is($geocoder->_get_components_query_params, 'administrative_area:TX', 'filter administrative_area = TX');
}

{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, components => { locality => 'anylocality' });
    is($geocoder->_get_components_query_params, 'locality:anylocality', 'filter locality = anylocality');
}

{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, components => { postal_code => '123456' });
    is($geocoder->_get_components_query_params, 'postal_code:123456', 'filter postal_code = 123456');
}

{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, components => { invalid_filter => '123456' });
    is($geocoder->_get_components_query_params, undef, 'invalid filter');
}

{
    my $geocoder = Geo::Coder::GooglePlaces->new(apiver => 3, components => { postal_code => '123456', country => 'anycountry' });
    is($geocoder->_get_components_query_params, 'country:anycountry|postal_code:123456', 'multiple filters');
}
