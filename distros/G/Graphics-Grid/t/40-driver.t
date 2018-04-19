#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::GPar;
use Graphics::Grid::Unit;
use Graphics::Grid::Util qw(points_to_cm);

package _Test::Graphics::Grid::Driver {
    use Graphics::Grid::Class;
    with 'Graphics::Grid::Driver';

    BEGIN {
        for my $func (
            ( map { "draw_$_" } qw(circle points polyline polygon rect segments text) ),
            qw(data write)
          )
        {
            no strict 'refs';
            *{$func} = sub { };
        }
    }
};

my $test_driver =
  _Test::Graphics::Grid::Driver->new( width => 1000, height => 1000 );
ok( $test_driver, "test driver initialized" );

my $unit = Graphics::Grid::Unit->new(
    value => [ 0.5,   1,        2,    3,    2 ],
    unit  => [ "npc", "inches", "cm", 'mm', 'char' ],
);

is(
    [
        map {
            $test_driver->_transform_width_to_cm( $unit, $_,
                $test_driver->default_gpar(),
                100, 60 )
        } ( 0 .. $unit->elems - 1 )
    ],
    [ 50, 2.54, 2, 0.3, points_to_cm( 2 * 11 ) ],
    '_transform_width_to_cm'
);
is(
    [
        map {
            $test_driver->_transform_height_to_cm( $unit, $_,
                $test_driver->default_gpar(),
                60, 100 )
        } ( 0 .. $unit->elems - 1 )
    ],
    [ 50, 2.54, 2, 0.3, points_to_cm( 2 * 11 ) ],
    '_transform_height_to_cm'
);

done_testing;
