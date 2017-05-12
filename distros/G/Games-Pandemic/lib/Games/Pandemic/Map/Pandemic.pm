#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use 5.010;
use strict;
use warnings;

package Games::Pandemic::Map::Pandemic;
{
  $Games::Pandemic::Map::Pandemic::VERSION = '1.120510';
}
# ABSTRACT: standard pandemic map from real game

use Geo::Mercator;
use Moose;
use MooseX::SemiAffordanceAccessor;

use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Utils;

extends 'Games::Pandemic::Map';


# -- default builders

sub _build_max_infections { 3 }

sub _build_name { 'pandemic' }

sub _build_start_diseases { [ map { ($_) x 3 } reverse 1..3 ] }

sub _raw_diseases {
return (
# id, name, main color, max nb of disease
[ 0, T( "Cholera"        ) , ['#3e82cf','#2956df','#152Bef','#0000ff'], 24, ],
[ 1, T( "Yellow fever"   ) , ['#fff999','#fffb66','#fffd33','#ffff00'], 24, ],
[ 2, T( "Bubonic plague" ) , ['#666666','#444444','#222222','#000000'], 24, ],
[ 3, T( "SARS"           ) , ['#ff5252','#ff3636','#ff2121','#ff0000'], 24, ],
);
}

sub _raw_cities {
return (
# name, disease id, xreal, yreal, x, y, [connections]
[ T( "San Francisco"    ), 0, _lat2px(-37.79,-122.46), _lat2px(-38,-122), [ 1,  6, 39, 46        ] ],
[ T( "Chicago"          ), 0, _lat2px(-41.78, -87.77), _lat2px(-44, -95), [ 0,  6,  7,  4,  2    ] ],
[ T( "Montreal"         ), 0, _lat2px(-45.62, -73.78), _lat2px(-46, -74), [ 1,  3,  5            ] ],
[ T( "New York"         ), 0, _lat2px(-40.52, -73.87), _lat2px(-46, -58), [ 2,  5, 14, 17        ] ],
[ T( "Atlanta"          ), 0, _lat2px(-33.72, -84.37), _lat2px(-34, -84), [ 1,  5,  8            ] ],
[ T( "Washington"       ), 0, _lat2px(-38.85, -76.94), _lat2px(-37, -64), [ 2,  3,  4,  8        ] ],
[ T( "Los Angeles"      ), 1, _lat2px(-34.17,-118.34), _lat2px(-24,-117), [ 0,  1,  7, 38        ] ],
[ T( "Mexico City"      ), 1, _lat2px(-19.43, -99.09), _lat2px(-19, -99), [ 1,  6,  8,  9, 10    ] ],
[ T( "Miami"            ), 1, _lat2px(-25.75, -80.19), _lat2px(-22, -69), [ 4,  5,  7,  9        ] ],
[ T( "Bogota"           ), 1, _lat2px( -4.66, -74.05), _lat2px( -4, -74), [ 7,  8, 10, 11, 13    ] ],
[ T( "Lima"             ), 1, _lat2px( 12.09, -77.08), _lat2px( 15, -84), [ 7,  9, 12            ] ],
[ T( "Sao Paulo"        ), 1, _lat2px( 23.52, -46.67), _lat2px( 23, -47), [ 9, 13, 17, 26        ] ],
[ T( "Santiago"         ), 1, _lat2px( 33.61, -70.71), _lat2px( 37, -79), [10                    ] ],
[ T( "Buenos Aires"     ), 1, _lat2px( 34.74, -58.41), _lat2px( 35, -58), [ 9, 11                ] ],
[ T( "London"           ), 0, _lat2px(-51.50,   0.04), _lat2px(-55, -15), [ 3, 15, 17, 18        ] ],
[ T( "Essen"            ), 0, _lat2px(-51.52,   7.02), _lat2px(-59,  11), [14, 16, 18, 19        ] ],
[ T( "Saint-Petersburg" ), 0, _lat2px(-59.95,  30.35), _lat2px(-61,  30), [15, 20, 21            ] ],
[ T( "Madrid"           ), 0, _lat2px(-40.41,  -3.77), _lat2px(-38, -15), [ 3, 11, 14, 18, 22    ] ],
[ T( "Paris"            ), 0, _lat2px(-48.90,   2.32), _lat2px(-48,   2), [14, 15, 17, 19, 22    ] ],
[ T( "Milano"           ), 0, _lat2px(-45.52,   9.19), _lat2px(-50,  20), [15, 18, 21            ] ],
[ T( "Moscow"           ), 2, _lat2px(-55.75,  37.66), _lat2px(-55,  46), [16, 21, 23            ] ],
[ T( "Istanbul"         ), 2, _lat2px(-41.01,  28.95), _lat2px(-41,  29), [16, 19, 20, 22, 24, 25] ],
[ T( "Algiers"          ), 2, _lat2px(-36.72,   3.06), _lat2px(-28,   2), [17, 18, 21, 25        ] ],
[ T( "Tehran"           ), 2, _lat2px(-35.68,  51.60), _lat2px(-43,  59), [20, 24, 30, 31        ] ],
[ T( "Baghdad"          ), 2, _lat2px(-33.29,  44.66), _lat2px(-33,  44), [21, 23, 25, 31, 32    ] ],
[ T( "Cairo"            ), 2, _lat2px(-30.08,  31.34), _lat2px(-25,  25), [21, 22, 24, 27, 32    ] ],
[ T( "Lagos"            ), 1, _lat2px( -6.42,   3.59), _lat2px( -6,   3), [11, 27, 28            ] ],
[ T( "Khartoum"         ), 1, _lat2px(-15.62,  32.43), _lat2px( -6,  32), [25, 26, 28, 29        ] ],
[ T( "Kinshasa"         ), 1, _lat2px(  4.41,  15.45), _lat2px( 11,  15), [26, 27, 29            ] ],
[ T( "Johannesburg"     ), 1, _lat2px( 26.22,  28.03), _lat2px( 26,  28), [27, 28                ] ],
[ T( "Delhi"            ), 2, _lat2px(-28.67,  77.22), _lat2px(-35,  77), [23, 31, 33, 34, 35    ] ],
[ T( "Karachi"          ), 2, _lat2px(-24.88,  67.00), _lat2px(-28,  61), [23, 24, 30, 32, 33    ] ],
[ T( "Riyadh"           ), 2, _lat2px(-24.62,  46.81), _lat2px(-16,  47), [24, 25, 31            ] ],
[ T( "Mumbai"           ), 2, _lat2px(-19.02,  72.79), _lat2px(-10,  67), [30, 31, 35            ] ],
[ T( "Kolkata"          ), 2, _lat2px(-22.58,  88.38), _lat2px(-28,  95), [30, 35, 36, 41        ] ],
[ T( "Chennai"          ), 2, _lat2px(-13.25,  81.63), _lat2px(  0,  82), [30, 33, 34, 36, 37    ] ],
[ T( "Bangkok"          ), 3, _lat2px(-13.66, 100.65), _lat2px(-12,  95), [34, 35, 37, 40, 41    ] ],
[ T( "Jakarta"          ), 3, _lat2px(  6.14, 106.91), _lat2px( 11, 100), [35, 36, 38, 40        ] ],
[ T( "Sydney"           ), 3, _lat2px( 34.04, 151.38), _lat2px( 34, 151), [ 6, 37, 39            ] ],
[ T( "Manila"           ), 3, _lat2px(-14.65, 120.68), _lat2px( -6, 131), [ 0, 38, 40, 41, 42    ] ],
[ T( "Hanoi"            ), 3, _lat2px(-10.76, 106.71), _lat2px( -6, 110), [36, 37, 39, 41        ] ],
[ T( "Hong Kong"        ), 3, _lat2px(-22.27, 114.14), _lat2px(-22, 114), [34, 36, 39, 40, 42, 43] ],
[ T( "Taipei"           ), 3, _lat2px(-24.86, 121.54), _lat2px(-22, 131), [39, 41, 43, 47        ] ],
[ T( "Shanghai"         ), 3, _lat2px(-31.24, 121.49), _lat2px(-34, 112), [41, 42, 44, 45, 46    ] ],
[ T( "Beijing"          ), 3, _lat2px(-40.03, 116.28), _lat2px(-45, 110), [43, 45                ] ],
[ T( "Seoul"            ), 3, _lat2px(-37.59, 127.11), _lat2px(-45, 127), [43, 44, 46            ] ],
[ T( "Tokyo"            ), 3, _lat2px(-35.71, 139.82), _lat2px(-39, 144), [ 0, 43, 45, 47        ] ],
[ T( "Osaka"            ), 3, _lat2px(-34.61, 135.60), _lat2px(-28, 144), [42, 46                ] ],
);
}

sub infection_rates {
    return (2, 2, 2, 3, 3, 4, 4);
}

sub _raw_special_cards {
    qw{ Airlift Forecast GovernmentGrant OneQuietNight ResilientPopulation };
}


sub _raw_start_city {
    return 4; # start at atlanta
}

{
    # we have 3 reference points:
    #      lat,   long = x on map, y on map
    #     0.00,   0.00 = 461, 358
    #   -87.77, -41.78 = 164, 200 (chicago)
    #   -99.09, -19.43 = 124, 290 (mexico)
    # we're using chicago to complement the origin.
    my ($xref, $yref) = mercate(-41.78, -87.77);
    sub _lat2px {
        my ($lat, $long) = @_;
        my ($xm, $ym) = mercate($lat, $long);
        my $x = int( 461 + (164-461) / $xref * $xm );
        my $y = int( 358 + (200-358) / $yref * $ym );
        return ($x, $y);
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

Games::Pandemic::Map::Pandemic - standard pandemic map from real game

=head1 VERSION

version 1.120510

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__
