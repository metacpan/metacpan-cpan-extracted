use strict;
use Test::Base;

use Geo::Google::MyMap::KMLURL;
use LWP::Simple;

plan tests => 23;

my $msid = '100703231789736299945.00000111c65c3586665af';

my $url  = mymap2kmlurl( $msid );

my $cont = get($url);

while ( my $line = <DATA> ) {
    chomp( $line );

    ok ( $cont =~ /$line/m );
}

__END__
http://earth.google.com/kml/2.2
Test of Geo::Google::MyMap::KMLURL
http://maps.google.com/mapfiles/ms/icons/blue-dot.png
POINT
139.753738,35.698395,0.000000
LINESTRING
139.753754,35.698395,0.000000
139.753845,35.698429,0.000000
139.754364,35.697437,0.000000
139.754608,35.697544,0.000000
139.755371,35.696098,0.000000
139.755524,35.696022,0.000000
139.755814,35.696033,0.000000
POLYGON
139.715363,35.708607,0.000000
139.722580,35.670685,0.000000
139.784882,35.657574,0.000000
139.809952,35.719063,0.000000
139.742310,35.727142,0.000000
139.715363,35.708607,0.000000
LinearRing
outerBoundaryIs

