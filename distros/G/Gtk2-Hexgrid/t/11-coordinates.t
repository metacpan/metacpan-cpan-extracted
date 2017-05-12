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
    newHexgrid(9,21,0,0),
    newHexgrid(9,25,1,0),
    newHexgrid(9,20,0,1),
    newHexgrid(10,18,1,1),
    newHexgrid(60,50,0,0)
);

plan tests => (1+(4*4)) * scalar @hexgrids;

#test get_tile_from_XY
for (0..$#hexgrids){
    my $hexgrid = $hexgrids[$_];
    isa_ok($hexgrid, "Gtk2::Hexgrid", "hexgrid $_ creation");
    for my $row (8..9){
        for my $col (3..4){
            my $tile = $hexgrid->get_tile($col, $row);
            my ($x, $y) = $tile->get_center;
            is($tile , $hexgrid->get_tile_from_XY($x, $y) , "center test, row $row, col $col, hexgrid $_");
            is($tile , $hexgrid->get_tile_from_XY($x+($linesize*.99), $y) , "right corner test, row $row, col $col, hexgrid $_");
            is($tile , $hexgrid->get_tile_from_XY($x+($linesize*.49), $y+$linesize*sqrt(3)*.49) , "lower right corner test, row $row, col $col, hexgrid $_");
            is($tile , $hexgrid->get_tile_from_XY($x-($linesize*.64), $y-$linesize*sqrt(3)*.34) , "nw edge test, row $row, col $col, hexgrid $_");
        }
    }
}
