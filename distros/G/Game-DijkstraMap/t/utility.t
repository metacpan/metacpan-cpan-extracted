#!perl
#
# utility routines are here as dimap.t was getting a bit long

use 5.24.0;
use warnings;

use Test::Most;    # plan is down at bottom
my $deeply = \&eq_or_diff;

use Game::DijkstraMap;

my $enough = 640;
my $dimap  = [ [ 2, 1, 0 ], [ 3, 2, 1 ], [ 4, 3, 2 ] ];

my $dm = Game::DijkstraMap->new( max_cost => $enough );

dies_ok( sub { $dm->to_tsv } );

$dm->dimap($dimap);

is( $dm->to_tsv, "2\t1\t0$/3\t2\t1$/4\t3\t2$/" );
is( Game::DijkstraMap->to_tsv( [ [qw(a b)], [qw(c d)] ] ), "a\tb$/c\td$/" );

my $rebuilt = $dm->rebuild;
is( $rebuilt->max_cost, $enough );
$deeply->( $rebuilt->dimap, undef );

my $clone = $dm->clone;
is( $clone->max_cost, $enough );
$deeply->( $clone->dimap, $dimap );

plan tests => 7
