#!perl

use strict;
use warnings;

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Game::DijkstraMap;
my $map = Game::DijkstraMap->new;

dies_ok(
    sub { $map->update( [ 0, 0, 42 ] ) },
    'update not allowed before map is set'
);
dies_ok( sub { $map->map("treasure") }, 'R.L.S. called' );

is( $map->max_cost, ~0 );
is( $map->min_cost, 0 );
is( $map->bad_cost, -1 );
ok( ref $map->costfn eq 'CODE' );

is( $map->iters, 0 );

$map->map( [ [qw(. . .)], [qw(. . .)], [qw(. . x)] ] );
$deeply->( $map->dimap, [ [qw(4 3 2)], [qw(3 2 1)], [qw(2 1 0)] ] );
is( $map->iters, 5 );

sub mapify {
    my ($s) = @_;
    my @map;
    for my $l ( split $/, $s ) {
        push @map, [ split //, $l ];
    }
    return \@map;
}

sub display {
    my ($map) = @_;
    my $s = "\n";
    for my $r ( 0 .. $#$map ) {
        for my $c ( 0 .. $#{ $map->[0] } ) {
            $s .= $map->[$r][$c] . "\t";
        }
        $s .= "\n";
    }
    $s .= "\n";
    return $s;
}

my $level = mapify <<"EOM";
,#####,
##...##
#..#.x#
##...##
,#####,
EOM

$deeply->(
    $map->map($level)->dimap,
    [   [ ~0, -1, -1, -1, -1, -1, ~0 ],
        [ -1, -1, 4,  3,  2,  -1, -1 ],
        [ -1, 6,  5,  -1, 1,  0,  -1 ],
        [ -1, -1, 4,  3,  2,  -1, -1 ],
        [ ~0, -1, -1, -1, -1, -1, ~0 ],
    ]
);

$map->update( [ 2, 1, 0 ] );
#use Data::Dumper; diag display $map->dimap;
$deeply->(
    $map->dimap,
    [   [ ~0, -1, -1, -1, -1, -1, ~0 ],
        [ -1, -1, 2,  3,  2,  -1, -1 ],
        [ -1, 0,  1,  -1, 1,  0,  -1 ],
        [ -1, -1, 2,  3,  2,  -1, -1 ],
        [ ~0, -1, -1, -1, -1, -1, ~0 ],
    ]
);

$deeply->( $map->map( [ [qw(. . x)] ] )->dimap, [ [ 2, 1, 0 ] ] );
$map->update( [ 0, 1, $map->bad_cost ] );
# TODO should not-wall not-goal cells adjacent to updated cells be reset
# to ->max_cost? maybe not, as the previous weights would still allow a
# monster to track near to the original goal if the player has cast a
# wall spell or something. however the change could be permanent in
# which case probably should recalculate adjacent squares. 
$deeply->( $map->dimap, [ [ 2, $map->bad_cost, 0 ] ] );
$map->update( [ 0, 1, 42 ] );
$deeply->( $map->dimap, [ [ 2, 1, 0 ] ] );

plan tests => 14;
