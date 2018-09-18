#!perl

use 5.24.0;
use warnings;

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Game::DijkstraMap;

dies_ok( sub { Game::DijkstraMap->new( map => [ [] ], str2map => 'x' ) },
    'invalid constructor form' );

my $dm = Game::DijkstraMap->new;

dies_ok( sub { $dm->dimap_with } );
dies_ok( sub { $dm->map("treasure") }, 'R.L.S. called' );
dies_ok( sub { $dm->next( 0, 0 ) } );
dies_ok( sub { $dm->next_best( 0, 0 ) } );
dies_ok( sub { $dm->next_sq( 0, 0 ) } );
dies_ok( sub { $dm->path_best( 0, 0 ) } );
dies_ok( sub { $dm->recalc } );
dies_ok( sub { $dm->to_tsv } );
dies_ok( sub { $dm->unconnected } );
dies_ok( sub { $dm->update( [ 0, 0, 42 ] ) } );
dies_ok( sub { $dm->values } );

is( $dm->max_cost, ~0, 'cost attribute defaults' );
is( $dm->min_cost, 0 );
is( $dm->bad_cost, -1 );
ok( ref $dm->costfn eq 'CODE' );
is( $dm->next_m, 'next' );

is( $dm->iters, 0, 'iters default' );

$dm->map( [ [qw(. . .)], [qw(. . .)], [qw(. . x)] ] );
$deeply->( $dm->dimap, [ [qw(4 3 2)], [qw(3 2 1)], [qw(2 1 0)] ] );
is( $dm->iters, 5 );

my $level = $dm->str2map(<<'EOM');
,#####,
##...##
#..#.x#
##...##
,#####,
EOM
$deeply->(
    $level,
    [   [ ",", "#", "#", "#", "#", "#", "," ],
        [ "#", "#", ".", ".", ".", "#", "#" ],
        [ "#", ".", ".", "#", ".", "x", "#" ],
        [ "#", "#", ".", ".", ".", "#", "#" ],
        [ ",", "#", "#", "#", "#", "#", "," ],
    ],
    'level map as aoa via str2map'
);

$deeply->(
    $dm->map($level)->dimap,
    [   [ ~0, -1, -1, -1, -1, -1, ~0 ],
        [ -1, -1, 4,  3,  2,  -1, -1 ],
        [ -1, 6,  5,  -1, 1,  0,  -1 ],
        [ -1, -1, 4,  3,  2,  -1, -1 ],
        [ ~0, -1, -1, -1, -1, -1, ~0 ],
    ],
    'level map in dimap'
);

$deeply->( $dm->unconnected, [ [ 0, 0 ], [ 0, 6 ], [ 4, 0 ], [ 4, 6 ] ] );
$deeply->( $dm->values( [ 0, 0 ], [ 1, 1 ], [ 2, 2 ] ), [ ~0, -1, 5 ] );

# 6 can go to 5 or either of the diagonal 4s. this test may fail if
# sort() or how next() iterates over the coordinates change; a more
# expensive sub-sort on the row may be necessary in such a case
$deeply->(
    [ sort { $a->[1] <=> $b->[1] } $dm->next( 2, 1 )->@* ],
    [ [ [ 1, 2 ], 4 ], [ [ 3, 2 ], 4 ], [ [ 2, 2 ], 5 ], ]
);
# only one option
$deeply->( $dm->next( 2, 4 ), [ [ [ 2, 5 ], 0 ] ], );
# nowhere to go
$deeply->( $dm->next( 0, 0 ), [], 'no path is possible' );
$deeply->( $dm->next_best( 0, 0 ), undef, 'still no path is possible' );

# Dijkstra! What is best in life?
$deeply->( $dm->next_best( 1, 4 ), [ 2, 5 ] );
is( $dm->next_best( 0, 0 ), undef );
$deeply->( $dm->path_best( 1, 2 ), [ [ 1, 3 ], [ 2, 4 ], [ 2, 5 ] ] );

$dm->next_m('next_sq');
is( $dm->next_m, 'next_sq' );
$deeply->( $dm->next_best( 1, 4 ), [ 2, 4 ] );
$deeply->( $dm->path_best( 1, 2 ), [ [ 1, 3 ], [ 1, 4 ], [ 2, 4 ], [ 2, 5 ] ] );
$dm->next_m('next');

$dm->update( [ 2, 1, 0 ] );

$deeply->(
    $dm->dimap,
    [   [ ~0, -1, -1, -1, -1, -1, ~0 ],
        [ -1, -1, 4,  3,  2,  -1, -1 ],
        [ -1, 0,  5,  -1, 1,  0,  -1 ],
        [ -1, -1, 4,  3,  2,  -1, -1 ],
        [ ~0, -1, -1, -1, -1, -1, ~0 ],
    ]
);

$deeply->(
    [ sort { $a->[1] <=> $b->[1] } $dm->next( 1, 2 )->@* ],
    [ [ [ 2, 1 ], 0 ], [ [ 1, 3 ], 3 ], ],
);

$dm->recalc;

$deeply->(
    $dm->dimap,
    [   [ ~0, -1, -1, -1, -1, -1, ~0 ],
        [ -1, -1, 2,  3,  2,  -1, -1 ],
        [ -1, 0,  1,  -1, 1,  0,  -1 ],
        [ -1, -1, 2,  3,  2,  -1, -1 ],
        [ ~0, -1, -1, -1, -1, -1, ~0 ],
    ]
);

$deeply->(
    [ sort { $a->[1] <=> $b->[1] } $dm->next( 1, 2 )->@* ],
    [ [ [ 2, 1 ], 0 ], [ [ 2, 2 ], 1 ], ],
);

# diagonals are not dealt with by normalize_costs. also condensed
# constructor form
lives_ok {
    $dm = Game::DijkstraMap->new( str2map => <<'EOM' );
.#
#x
EOM
    $dm->recalc;
};
$deeply->( $dm->unconnected, [ [ 0, 0 ] ] );

# dimap_with, next_with
#
# ..x + .#. + ... where b=11 and a=7 plus weighting
# ...   .b.   a..
# ...   ...   ...
{
    $dm = Game::DijkstraMap->new( str2map => <<'EOM' );
..x
...
...
EOM
    my $map1 = Game::DijkstraMap->new;
    $map1->dimap( [ [qw(10 -1 0)], [qw(0 11 0)], [qw(0 0 0)] ] );
    my $map2 = Game::DijkstraMap->new;
    $map2->dimap( [ [qw(0 0 0)], [qw(7 0 0)], [qw(0 0 0)] ] );

    $deeply->(
        $dm->dimap_with(
            { objs => [ $map1, $map2 ], weights => [ 3, 2 ], my_weight => 5 }
        ),
        [ [ 40, -1, 0 ], [ 29, 43, 5 ], [ 20, 15, 10 ] ]
    );

    $deeply->(
        $dm->next_with(
            0, 0, { objs => [ $map1, $map2 ], weights => [ 3, 2 ], my_weight => 5 }
        ),
        [ 1, 0 ]
    );
}

is( $dm->to_tsv, "2\t1\t0$/3\t2\t1$/4\t3\t2$/" );
is( Game::DijkstraMap->to_tsv( [ [qw(a b)], [qw(c d)] ] ), "a\tb$/c\td$/" );

plan tests => 44
