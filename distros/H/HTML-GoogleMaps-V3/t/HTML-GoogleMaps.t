#!perl -w

use Test::More 'no_plan';
use strict;

BEGIN { use_ok('HTML::GoogleMaps::V3') }

# Autocentering
{
  my $map = HTML::GoogleMaps::V3->new;
  $map->add_marker(point => [0, 0]);
  is_deeply( $map->_find_center, [0, 0], "Single point 1" );

  $map = HTML::GoogleMaps::V3->new;
  $map->add_marker(point => [90, 0]);
  is_deeply( $map->_find_center, [0, 90], "Single point 2" );

  $map = HTML::GoogleMaps::V3->new;
  $map->add_marker(point => [180, 45]);
  is_deeply( $map->_find_center, [45, 180], "Single point 3" );

  $map = HTML::GoogleMaps::V3->new;
  $map->add_marker(point => [-90, -10]);
  is_deeply( $map->_find_center, [-10, -90], "Single point 4" );

  $map = HTML::GoogleMaps::V3->new;
  $map->add_marker(point => [10, 10]);
  $map->add_marker(point => [20, 20]);
  is_deeply( $map->_find_center, [15, 15], "Double point 1" );

  $map = HTML::GoogleMaps::V3->new;
  $map->add_marker(point => [-10, 10]);
  $map->add_marker(point => [-20, 20]);
  is_deeply( $map->_find_center, [15, -15], "Double point 2" );

  $map = HTML::GoogleMaps::V3->new;
  $map->add_marker(point => [10, 10]);
  $map->add_marker(point => [-10, -10]);
  is_deeply( $map->_find_center, [0, 0], "Double point 3" );

  $map = HTML::GoogleMaps::V3->new;
  $map->add_marker(point => [-170, 0]);
  $map->add_marker(point => [150, 0]);
  is_deeply( $map->_find_center, [0, 170], "Double point 4" );
}

# API v3 support
{
  my $map = HTML::GoogleMaps::V3->new;
  my ($head, $html) = $map->onload_render;
  like( $head, qr!script.*maps.googleapis.com/maps/api/js!, 'Point to v3 API' );

  $map->zoom(2);
  is( $map->{zoom}, 2, '->zoom' );
  $map->v2_zoom(3);
  is( $map->{zoom}, 3, '->v2_zoom' );
    
  $map->center([12,13]);
  $map->add_marker(point => [13,14]);
  $map->add_polyline(points => [ [14,15], [15,16] ]);
  ($html, $head) = $map->onload_render;

  $map->map_type('map_type');
  ($html, $head) = $map->onload_render;
  like( $html, qr/NORMAL/, 'map_type' );
  $map->map_type('satellite_type');
  ($html, $head) = $map->onload_render;
  like( $html, qr/SATELLITE/, 'satellite_type' );
  $map->map_type('normal');
  ($html, $head) = $map->onload_render;
  like( $html, qr/NORMAL/, 'normal' );
  $map->map_type('satellite');
  ($html, $head) = $map->onload_render;
  like( $html, qr/SATELLITE/, 'satellite' );
  $map->map_type('hybrid');
  ($html, $head) = $map->onload_render;
  like( $html, qr/HYBRID/, 'hybrid' );
  $map->map_type('road');
  ($html, $head) = $map->onload_render;
  like( $html, qr/ROADMAP/, 'road' );
}

# Geo::Coder::Google
{
  my $map = HTML::GoogleMaps::V3->new;
  no warnings 'redefine';
  no warnings 'once';
  *Geo::Coder::Google::V3::geocode = sub { +{geometry => {location => {lat => 3925, lng => 3463}}} };

  $map->add_marker(point => 'result_democritean');
  my ($html, $head) = $map->onload_render;
  like( $html, qr/\Qnew google.maps.LatLng({lat: 3925, lng: 3463})\E/,
  'Geocoding with Geo::Coder::Google' );
}

# dragging
{
  my $map = HTML::GoogleMaps::V3->new;
  $map->dragging(0);
  my ($html, $head) = $map->onload_render;
  like( $html, qr/draggable: false/,'dragging' );

  $map->dragging(1);
  ($html, $head) = $map->onload_render;
  unlike( $html, qr/draggable: false/,'! dragging' );
}

# map_id
{
  my $map = HTML::GoogleMaps::V3->new;
  $map->map_id('electrometrical_nombles');
  $map->add_marker(point => [21, 31]);
  $map->add_polyline(points => [[21, 31], [22, 32]]);

  my ($head, $div) = $map->onload_render;
  like( $head, qr/getElementById\('electrometrical_nombles'\)/, 'Correct map ID for getElementById' );
  like( $div, qr/id="electrometrical_nombles"/, 'Correct map ID for div' );

  ok( $map->add_polyline( color => '#0000ff', points => [[21, 31], [22, 32]]) );
  ok( $map->add_polyline( weight => 10, points => [[21, 31], [22, 32]]) );
  ok( $map->add_polyline( opacity => .3, points => [[21, 31], [22, 32]]) );
}

# width and height
{
   my $map = HTML::GoogleMaps::V3->new( api_key => 'foo', width => 11, height => 22 );
   my ($head, $div) = $map->onload_render;
   like( $div, qr/width.+11px/, 'Correct width for div' );
   like( $div, qr/height.+22px/, 'Correct height for div' );

   $map = HTML::GoogleMaps::V3->new( api_key => 'foo', width => '33%', height => '44em' );
   ($head, $div) = $map->onload_render;
   like( $head, qr/key=foo\b/, 'api_key used' );
   like( $div, qr/width.+33%/, 'Correct width for div' );
   like( $div, qr/height.+44em/, 'Correct height for div' );
   unlike( $div, qr/z-index/, 'z-index is not included by default' );
}

# z-index
{
   my $map = HTML::GoogleMaps::V3->new(z_index => -1);
   my ($head, $div) = $map->onload_render;

   like($div, qr/z-index: -1/, 'z-index is included');
   unlike($head, qr/z-index/, 'z-index is in the correct place');
   unlike( $div, qr/width.+11px/, 'width for div not included' );
   unlike( $div, qr/height.+22px/, 'height for div not included' );
}

# info window html
{
    my $map = HTML::GoogleMaps::V3->new( api_key => 'foo' );
    $map->add_marker( point => 'bar', html => qq|<a href="foo" title='bar'>baz</a>| );
    my ($head, $div) = $map->onload_render;
    like( $head, qr/key=foo\b/, 'api_key used' );
    is( $map->info_window( 1 ),1,'info_window' );
    like( $head, qr/\Qvar infowindow1 = new google.maps.InfoWindow\E/, 'openInfoWindowHtml' );
}

# back compat methods that do nothing at present
{
    my $map = HTML::GoogleMaps::V3->new( api_key => 'foo' );
    ok( $map->add_icon,'->add_icon' );
    ok( $map->controls,'->controls' );

    $map->{points} = [ { point => [ -100,-100 ] } ];
    ok( $map->_find_center,'_find_center' );
}

# Github issue 12
SKIP: {
    eval {
    	require Geo::Coder::GooglePlaces;

    	Geo::Coder::GooglePlaces->import();
    };

    if($@) {
    	diag('Geo::Coder::GooglePlaces required for some tests');
    	skip 'Geo::Coder::GooglePlaces not installed';
    } elsif(my $key = $ENV{'GMAP_KEY'}) {
    	diag("Using Geo::Coder::GooglePlaces $Geo::Coder::GooglePlaces::VERSION");
    	my $place = 'Minster Cemetery, Tothill Street, Minster, Thanet, Kent, England';
	my $geocoder = new_ok('Geo::Coder::GooglePlaces::V3' => [ key => $key]);
    	my $map = new_ok('HTML::GoogleMaps::V3' => [ geocoder => $geocoder ]);
    	is($map->center($place), 1, $place);
    	is($map->add_marker(point => $place, html => $place), 1, $place);
    } else {
	skip 'Not running live tests. Set $ENV{GMAP_KEY} to your API key to enable';
    }
}
