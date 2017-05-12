use strict;
use warnings;
use Test::More;

eval "use Geo::Distance 0.16; 1" or do {
    plan skip_all => 'Geo::Distance >= 0.16 is not installed.';
};

BEGIN { $ENV{GEO_DISTANCE_PP} = 1 }
my $geo = Geo::Distance->new;
isnt defined $Geo::Distance::XS::VERSION, 1, 'GEO_DISTANCE_PP';

done_testing;
