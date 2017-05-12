use strict;
use warnings;
use Test::More tests => 2;
use Geo::Gpx;

# See:
#   http://rt.cpan.org/Public/Bug/Display.html?id=29909

my $gpx = Geo::Gpx->new;

my @correct_order = qw(
 ele time magvar geoidheight name cmt desc src link sym type fix sat
 hdop vdop pdop ageofdgpsdata dgpsid
);

$gpx->waypoints(
  [
    {
      # All standard GPX fields
      lat         => 54.786989,
      lon         => -2.344214,
      ele         => 512,
      time        => 1164488503,
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
    }
  ]
);

my $xml = $gpx->xml( '1.1' );

ok $xml =~ m{ <wpt[^>]*> (.*?) </wpt> }xms, "has wpt";
my $wpt = $1;
my @ord = ( $wpt =~ m{ <(\w+).*?</\1> }xmsg );
is_deeply \@ord, \@correct_order, 'order ok';
