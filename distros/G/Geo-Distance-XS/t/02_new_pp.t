use strict;
use warnings;
use Test::More;

eval "use Geo::Distance 0.16; 1" or do {
    plan skip_all => 'Geo::Distance >= 0.16 is not installed.';
};

# Tests that Geo::Distance automatically loads the XS version.
my $geo = Geo::Distance->new;
is defined $Geo::Distance::XS::VERSION, 1, 'PP version loads XS';

done_testing;
