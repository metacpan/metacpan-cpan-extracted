#!perl -T

use strict;
use warnings;
use Test::More;
use Gtk2::Hexgrid;

my $linesize = 100;
my $border = 10;
my ($r,$g,$b) = (1,1,1);

sub newHexgrid{
    my ($w, $h, $evenRowsFirst, $evenRowsLast) = @_;
    my  $hexgrid = Gtk2::Hexgrid->new(
                        $w,
                        $h, 
                        $linesize,
                        $border, 
                        $evenRowsFirst,
                        $evenRowsLast,
                        $r,$g,$b);
    return $hexgrid;
}

my @hexgrids = (
    newHexgrid(4,11,0,0), #49
    newHexgrid(4,45,1,0), #180
    newHexgrid(5,10,0,1), #50
    newHexgrid(38,8,1,1), #300
    newHexgrid(60,50,0,0) #3025
);
my @numTiles = (49, 180, 50, 300, 3025);

plan tests => (7 * scalar @hexgrids) + (13);

#test directions
for (0..$#hexgrids){
    my $hexgrid = $hexgrids[$_];
    isa_ok($hexgrid, "Gtk2::Hexgrid", "hexgrid $_ creation");
    my @tiles = $hexgrid->get_all_tiles;
    is(scalar @tiles , $numTiles[$_], "hexgrid $_ correct number of tiles");
    my $tile = $hexgrid->get_tile(1,5);
    is($tile , $tile->ne->se->sw->nw, "$_ right side loop");
    my $tile2 = $hexgrid->get_tile(1,1);
    is($tile2 , $tile2->s->n, "$_ loop1");
    is($tile2 , $tile2->se->nw, "$_ loop2");
    is($tile2 , $tile2->sw->ne, "$_ loop3");
    is($tile2 , $tile2->sw->s->ne->n, "$_ sw loopround");    
}

#test edges to the grid
for (0,2,4){ #odd rows first
    my $tile = $hexgrids[$_]->get_tile(0,1);
    is($tile->sw, undef, "hexgrid $_ 01sw");
    $tile = $hexgrids[$_]->get_tile(0,0);
    is($tile->ne, undef, "hexgrid $_ 00ne");
}
for (1,3){ #even first
    my $tile = $hexgrids[$_]->get_tile(0,1);
    is($tile->n, undef, "hexgrid $_ 01n");
    $tile = $hexgrids[$_]->get_tile(0,6);
    is($tile->sw, undef, "hexgrid $_ 06sw");
}

my $tile = $hexgrids[2]->get_tile(3,8);
is($tile->s, undef, "hexgrid 2 38s");
$tile = $hexgrids[2]->get_tile(4,6);
is($tile->se, undef, "hexgrid 2 46se");

$tile = $hexgrids[0]->get_tile(4,5);
is($tile->ne, undef, "hexgrid 1 45ne");

__END__
