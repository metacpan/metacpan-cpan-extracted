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
    newHexgrid(5,7,0,0),
    newHexgrid(4,6,1,0),
    newHexgrid(3,5,0,1),
    newHexgrid(2,4,1,1),
    newHexgrid(5,3,1,1)
);

my @counts = (
    38,
    24,
    15,
    6,
    14
);

plan tests => (2) * scalar @hexgrids;

#test num_tiles
for (0..$#hexgrids){
    my $hexgrid = $hexgrids[$_];
    isa_ok($hexgrid, "Gtk2::Hexgrid", "hexgrid $_ creation");
    my $c = $hexgrid->num_tiles;
    is ($c, $counts[$_], "grid $_ count");




}




