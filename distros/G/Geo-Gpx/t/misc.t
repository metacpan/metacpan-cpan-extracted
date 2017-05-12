use strict;
use warnings;
use Test::More tests => 9;

use Geo::Gpx;

my $time = time();
my @wpt  = (
  {
    # All standard GPX fields
    lat         => 54.786989,
    lon         => -2.344214,
    ele         => 512,
    time        => $time,
    magvar      => 0,
    geoidheight => 0,
    name        => 'My house & home',
    cmt         => 'Where I live',
    desc        => '<<Chez moi>>',
    src         => 'Testing',
    link        => {
      href => 'http://hexten.net/',
      text => 'Hexten',
      type => 'Blah'
    },
    sym           => 'pin',
    type          => 'unknown',
    fix           => 'dgps',
    sat           => 3,
    hdop          => 10,
    vdop          => 10,
    pdop          => 10,
    ageofdgpsdata => 45,
    dgpsid        => 247
  },
  {
    # Fewer fields
    lat  => -38.870059,
    lon  => -151.210030,
    name => 'Sydney, AU'
  }
);

{
  my $gpx = new Geo::Gpx;
  $gpx->add_waypoint( @wpt );
  is_deeply $gpx->waypoints, \@wpt, "add_waypoint adds waypoints";
}

{
  my $gpx = new Geo::Gpx;
  eval { $gpx->add_waypoint( [] ) };
  like $@, qr/waypoint argument must be a hash reference/,
   "type check OK";
}

{
  for my $wpt ( {}, { lat => 1 }, { lon => 1 } ) {
    my $gpx = new Geo::Gpx;
    eval { $gpx->add_waypoint( $wpt ) };
    like $@, qr/mandatory in waypoint/, "mandatory lat, lon OK";
  }
}

{
  my $gpx = Geo::Gpx->new;
  $gpx->add_waypoint( @wpt );
  my $bounds = {
    'maxlat' => 54.786989,
    'maxlon' => -2.344214,
    'minlat' => -38.870059,
    'minlon' => -151.21003,
  };
  is_deeply $gpx->bounds, $bounds,
   "gpx->bounds doesn't require an iterator";
}

{
  my $gpx = Geo::Gpx->new;
  # Violate encapsulation, avoid clock skew.
  $gpx->{time} = $time;

  $gpx->add_waypoint( @wpt );
  my $expect = {
    waypoints => \@wpt,
    bounds    => {
      'maxlat' => 54.786989,
      'maxlon' => -2.344214,
      'minlat' => -38.870059,
      'minlon' => -151.21003,
    },
    time => $time,
  };
  is_deeply $gpx->TO_JSON, $expect, "TO_JSON";
  $gpx->name( 'spurkis' );
  $expect->{name} = 'spurkis';
  is_deeply $gpx->TO_JSON, $expect, "TO_JSON now has a name";

  SKIP: {
    eval "use JSON";
    skip 'JSON not installed', 1 if $@;

    my $coder = JSON->new;
    my @need  = qw( encode decode allow_blessed convert_blessed );
    for my $method ( @need ) {
      skip "JSON doesn't support $method", 1
       unless $coder->can( $method );
    }
    $coder->allow_blessed->convert_blessed;
    my $json  = $coder->decode( $coder->encode( $gpx ) );
    my $json2 = $coder->decode( $coder->encode( $expect ) );
    is_deeply $json, $json2, "works with JSON module";
  }
}
