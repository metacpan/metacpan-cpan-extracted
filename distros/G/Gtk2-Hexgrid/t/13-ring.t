#!perl -T

use strict;
use warnings;
use Gtk2::Hexgrid;
use Test::More;
eval "use Test::Deep";
plan skip_all => "Test::Deep required for testing."
    if $@;

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

my $round_hexgrid = newHexgrid(10,30,0,0);
my $square_hexgrid = newHexgrid(10,30,1,1);
my $small_hexgrid = newHexgrid(4,12,0,0);

plan tests => 2;

{
    #from 2,6 range 1
    my @ring = $round_hexgrid->get_ring(2, 6, 1);
    my @expected_co = (
        [2,5],
        [2,4],
        [3,5],
        [2,7],
        [2,8],
        [3,7]
    );
    my @expected = map {$round_hexgrid->get_tile ($_->[0], $_->[1]) } @expected_co;
    cmp_set(\@ring, \@expected, 'round 2,6,rad 1');
}
{
    #from 3,10 range 2
    my @ring = $square_hexgrid->get_ring(3, 10, 2);
    my @expected_co = (
        [4,10],
        [4,12],
        [3,13],
        [3,14],
        [2,13],
        [2,12],
        [2,10],
        [2,8],
        [2,7],
        [3,6],
        [3,7],
        [4,8]
    );
    my @expected = map {$square_hexgrid->get_tile ($_->[0], $_->[1]) } @expected_co;
    cmp_set(\@ring, \@expected, 'square 3,10,rad 2');
}







