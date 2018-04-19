#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Unit;

ok(
    Graphics::Grid::Unit->DOES('Graphics::Grid::UnitLike'),
    'Graphics::Grid::Unit DOES Graphics::Grid::UnitLike'
);

my @cases_constructor = (
    {
        params => [42],
        value  => [42],
        unit   => ['npc'],
    },
    {
        params => [ [42] ],
        value  => [42],
        unit   => ['npc'],
    },
    {
        params => [ 42, 'npc' ],
        value  => [42],
        unit   => ['npc'],
    },
    {
        params => [ [42], ['npc'] ],
        value  => [42],
        unit   => ['npc'],
    },
    {
        params => [ value => 42 ],
        value  => [42],
        unit   => ['npc'],
    },
    {
        params => [ value => [42] ],
        value  => [42],
        unit   => ['npc'],
    },
    {
        params => [ value => 42, unit => 'npc' ],
        value  => [42],
        unit   => ['npc'],
    },
    {
        params => [ value => [42], unit => ['npc'] ],
        value  => [42],
        unit   => ['npc'],
    },

    {
        params => [ value => [qw(0.2 0.3)], unit => "in" ],
        value  => [qw(0.2 0.3)],
        unit   => [qw(inches)],
    },
    {
        params => [0.5],
        value  => [qw(0.5)],
        unit   => [qw(npc)],
    },
    {
        params => [ [qw(0.2 0.3)] ],
        value  => [qw(0.2 0.3)],
        unit   => [qw(npc)],
    },
    {
        params => [ value => [qw( 0.2 0.3 )], unit => [qw(npc in)] ],
        value  => [qw(0.2 0.3)],
        unit   => [qw(npc inches)],
    },
    {
        params => [ 1, 'char' ],
        value  => [qw(1)],
        unit   => [qw(char)],
    },
    {
        params => [ 1, 'native' ],
        value  => [qw(1)],
        unit   => [qw(native)],
    },
);

for my $case (@cases_constructor) {
    my $unit = Graphics::Grid::Unit->new( @{ $case->{params} } );
    ok( $unit, 'constructor' );
    is( $unit->value, $case->{value}, "value" );
    is( $unit->unit,  $case->{unit},  "unit" );
}

ok( Graphics::Grid::Unit->is_absolute_unit('cm'),   'is_absolute_unit' );
ok( !Graphics::Grid::Unit->is_absolute_unit('npc'), 'is_absolute_unit' );

done_testing;
