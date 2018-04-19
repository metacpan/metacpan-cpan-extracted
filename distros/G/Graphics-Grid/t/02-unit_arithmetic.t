#!perl

use strict;
use warnings;

use Test2::V0;

use Graphics::Grid::Unit;
use Graphics::Grid::UnitArithmetic;

ok(
    Graphics::Grid::UnitArithmetic->DOES('Graphics::Grid::UnitLike'),
    'Graphics::Grid::UnitArithmetic DOES Graphics::Grid::UnitLike'
);

my @cases_constructor = (

    {
        params => [
            node => 42,
        ],
        elems     => 1,
        stringify => '42',
    },
    {
        params => [
            node => [42],
        ],
        elems     => 1,
        stringify => '42',
    },

    {
        params => [
            node     => '-',
            children => [
                Graphics::Grid::Unit->new( [ 1, 2, 3 ], "cm" ),
                Graphics::Grid::Unit->new(0.5),
            ],
        ],
        elems     => 3,
        stringify => '1cm-0.5npc, 2cm-0.5npc, 3cm-0.5npc',
    },
    {
        params => [
            node     => '*',
            children => [
                [2],
                Graphics::Grid::UnitArithmetic->new(
                    node     => '+',
                    children => [
                        Graphics::Grid::Unit->new( [ 1, 2, 3 ], "cm" ),
                        Graphics::Grid::Unit->new(0.5),
                    ],
                ),
            ],
        ],
        elems     => 3,
        stringify => '2*(1cm+0.5npc), 2*(2cm+0.5npc), 2*(3cm+0.5npc)',
    },
    {
        params => [
            node     => '*',
            children => [
                Graphics::Grid::UnitArithmetic->new(
                    node     => '+',
                    children => [
                        Graphics::Grid::Unit->new( [ 1, 2, 3 ], "cm" ),
                        Graphics::Grid::Unit->new(0.5),
                    ],
                ),
                [2],
            ],
        ],
        elems     => 3,
        stringify => '(1cm+0.5npc)*2, (2cm+0.5npc)*2, (3cm+0.5npc)*2',
    },
);

for my $case (@cases_constructor) {
    my $ua =
      Graphics::Grid::UnitArithmetic->new( @{ $case->{params} } );
    ok( $ua, 'constructor' );
    if ( exists $case->{elems} ) {
        is( $ua->elems, $case->{elems}, 'elems()' );
    }

    if ( exists $case->{stringify} ) {
        is( $ua->stringify, $case->{stringify}, 'stringify()' );
    }
    else {
        diag( $ua->stringify );
    }

}

{
    my $ua1 =
      Graphics::Grid::UnitArithmetic->new(
        node => Graphics::Grid::Unit->new( [ 1, 2, 3 ], "cm" ) );
    is( ( $ua1 * 2 )->stringify, '1cm*2, 2cm*2, 3cm*2', 'overload +/-/*' );

    my $ua2 =
      ( Graphics::Grid::Unit->new( [ 1, 2, 3 ], "cm" ) +
          Graphics::Grid::Unit->new(0.5) ) * 2;

    is(
        $ua2->stringify,
        '(1cm+0.5npc)*2, (2cm+0.5npc)*2, (3cm+0.5npc)*2',
        'overload +/-/*'
    );
}

done_testing;

