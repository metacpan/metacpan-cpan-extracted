use strict;
use warnings;
use Test::More;
use Geo::Google::StaticMaps::Navigation;
use URI;

my $map = Geo::Google::StaticMaps::Navigation->new(
    key => 'mymapsapikey',
    size => [365,365],
    center => [0, 0],
    zoom => 9,
);
isa_ok $map, 'Geo::Google::StaticMaps';
ok $map->url, $map->url;
ok my $clone = $map->_clone;
isa_ok $clone, 'Geo::Google::StaticMaps::Navigation';
my $zoom = $map->zoom_out;
is $zoom->{zoom}, 8;
is sprintf("%.4f", Geo::Google::StaticMaps::Navigation::_degree(365,9)), '1.0005';
my $north = $map->north;
is_deeply [ map {sprintf("%.4f", $_) } @{$north->{center}} ], ['1.0005', '0.0000'];
my $east = $map->east;
is_deeply [ map {sprintf("%.4f", $_) } @{$east->{center}} ], ['0.0000', '1.0005'];
is_deeply [ 
    map {sprintf("%.4f", $_) } @{$map->zoom_out->east->{center}} 
], ['0.0000', '2.0011'];
ok $map->zoom_in->zoom_out->north->west->south->east->url;

my $old_url = URI->new('http://localhost:5000/test?lat=1&lng=-1&zoom=8&foo=bar');
is_deeply { $map->pageurl($old_url)->query_form }, {
    lat => 0,
    lng => 0,
    zoom => 9,
    foo => 'bar',
};

done_testing;
