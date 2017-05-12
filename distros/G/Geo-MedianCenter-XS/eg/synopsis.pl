#!perl -w
use strict;
use warnings;

use Geo::MedianCenter::XS qw/haversine_distance_dec median_center/;

my $distance = haversine_distance_dec(
  54.728569, 8.7057573, # Dagebuell-Hafen
  54.730320, 8.7289753, # Dagebuell-Kirche
);

my ($center_lat, $center_lon) = median_center({
  points => [
    [ 54.728569, 8.7057573 ], # Dagebuell-Hafen
    [ 54.730320, 8.7289753 ], # Dagebuell-Kirche
    [ 54.639998, 8.6017305 ], # Langeness
    [ 54.492014, 8.8648961 ], # Nordstrand
  ],
});
