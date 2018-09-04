#!perl

use strict;
use warnings;

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Game::DijkstraMap;
my $dm = Game::DijkstraMap->new;

dies_ok( sub { $dm->map("treasure") }, 'R.L.S. called' );
dies_ok( sub { $dm->next( 0, 0 ) } );
dies_ok( sub { $dm->next_best( 0, 0 ) } );
dies_ok( sub { $dm->next_sq( 0, 0 ) } );
dies_ok( sub { $dm->path_best( 0, 0 ) } );
dies_ok( sub { $dm->recalc }, 'recalc not allowed before map is set' );
dies_ok( sub { $dm->update( [ 0, 0, 42 ] ) },
    'update not allowed before map is set' );

is( $dm->max_cost, ~0 );
is( $dm->min_cost, 0 );
is( $dm->bad_cost, -1 );
ok( ref $dm->costfn eq 'CODE' );

is( $dm->iters, 0 );

$dm->map( [ [qw(. . .)], [qw(. . .)], [qw(. . x)] ] );
$deeply->( $dm->dimap, [ [qw(4 3 2)], [qw(3 2 1)], [qw(2 1 0)] ] );
is( $dm->iters, 5 );

# TODO probably instead use is_deeply and then call this as the default
# eq_or_diff output can be hard to read for grids, or figure out
# something better from Test::Differences to use...
#diag display $dm->dimap;
sub display {
    my ($dm) = @_;
    my $s = $/;
    for my $r ( 0 .. $#$dm ) {
        for my $c ( 0 .. $#{ $dm->[0] } ) {
            $s .= $dm->[$r][$c] . "\t";
        }
        $s .= $/;
    }
    $s .= $/;
    return $s;
}

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
    ]
);

$deeply->(
    $dm->map($level)->dimap,
    [   [ ~0, -1, -1, -1, -1, -1, ~0 ],
        [ -1, -1, 4,  3,  2,  -1, -1 ],
        [ -1, 6,  5,  -1, 1,  0,  -1 ],
        [ -1, -1, 4,  3,  2,  -1, -1 ],
        [ ~0, -1, -1, -1, -1, -1, ~0 ],
    ]
);

# 6 can go to 5 or either of the diagonal 4s. this test may fail if
# sort() or how next() iterates over the coordinates change; a more
# expensive sub-sort on the row may be necessary in such a case
$deeply->(
    [ sort { $a->[1] <=> $b->[1] } $dm->next( 2, 1 ) ],
    [ [ [ 1, 2 ], 4 ], [ [ 3, 2 ], 4 ], [ [ 2, 2 ], 5 ], ]
);
# only one option
$deeply->( [ $dm->next( 2, 4 ) ], [ [ [ 2, 5 ], 0 ] ], );
# nowhere to go
$deeply->( [ $dm->next( 0, 0 ) ], [], );

# Dijkstra! What is best in life?
$deeply->( $dm->next_best( 1, 4 ), [ 2, 5 ] );
is( $dm->next_best( 0, 0 ), undef );
$deeply->( $dm->next_best( 1, 4, 'next_sq' ), [ 2, 4 ] );

$deeply->( $dm->path_best( 1, 2 ), [ [ 1, 3 ], [ 2, 4 ], [ 2, 5 ] ] );
$deeply->(
    $dm->path_best( 1, 2, 'next_sq' ),
    [ [ 1, 3 ], [ 1, 4 ], [ 2, 4 ], [ 2, 5 ] ]
);

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
    [ sort { $a->[1] <=> $b->[1] } $dm->next( 1, 2 ) ],
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
    [ sort { $a->[1] <=> $b->[1] } $dm->next( 1, 2 ) ],
    [ [ [ 2, 1 ], 0 ], [ [ 2, 2 ], 1 ], ],
);

plan tests => 28
