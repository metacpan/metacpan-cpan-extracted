use 5.012;
use warnings;
use Test::More;
use Test::Fatal;
use Test::Warnings;

use Geo::Geos::Dimension qw/TYPE_DONTCARE TYPE_True TYPE_False TYPE_P TYPE_L TYPE_A/;

subtest "toDimensionSymbol" => sub {
    is Geo::Geos::Dimension::toDimensionSymbol(TYPE_DONTCARE), '*';
    is Geo::Geos::Dimension::toDimensionSymbol(TYPE_True), 'T';
    is Geo::Geos::Dimension::toDimensionSymbol(TYPE_False), 'F';
    is Geo::Geos::Dimension::toDimensionSymbol(TYPE_P), '0';
    is Geo::Geos::Dimension::toDimensionSymbol(TYPE_L), '1';
    is Geo::Geos::Dimension::toDimensionSymbol(TYPE_A), '2';
    like exception { Geo::Geos::Dimension::toDimensionSymbol(99999) }, qr/IllegalArgumentException/;
};

subtest "toDimensionValue" => sub {
    is Geo::Geos::Dimension::toDimensionValue('*'), TYPE_DONTCARE;
    is Geo::Geos::Dimension::toDimensionValue('T'), TYPE_True;
    is Geo::Geos::Dimension::toDimensionValue('F'), TYPE_False;
    is Geo::Geos::Dimension::toDimensionValue('0'), TYPE_P;
    is Geo::Geos::Dimension::toDimensionValue('1'), TYPE_L;
    is Geo::Geos::Dimension::toDimensionValue('2'), TYPE_A;
    like exception { Geo::Geos::Dimension::toDimensionValue('abc') }, qr/string of one char is expected/;
    like exception { Geo::Geos::Dimension::toDimensionValue('_') }, qr/IllegalArgumentException/;
};


done_testing;
