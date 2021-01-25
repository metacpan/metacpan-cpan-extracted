#!perl

use strict;
use warnings;

use Test::More tests => 14;
#use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;

for my $unit ( 'mile', 'nm', 'foot',
               'meter', 'kilometer',    # American English spelling
               'metre', 'kilometre',    # British English spelling
             )
{
    my $e0 = Geo::Ellipsoid->new(distance_units => $unit);
    is($e0 -> get_distance_unit(), $unit,
       "sucessfully set unit to '$unit' via constructor");

    my $e1 = Geo::Ellipsoid->new();
    $e1 -> set_distance_unit($unit);
    is($e1 -> get_distance_unit(), $unit,
       "sucessfully set unit to '$unit' via mutator");
}
