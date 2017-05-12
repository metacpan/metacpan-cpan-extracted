#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;

use_ok 'Math::HexGrid', 'import module';

# hexagon shape
ok my $hexgrid = Math::HexGrid->new_hexagon(2), 'create a hexagon';
cmp_ok keys %{$hexgrid->{map}}, '==', 19, 'hexgrid has expected number of hexes';
cmp_ok $hexgrid->count_sides, '==', 78, 'hexgrid has expected number of sides';
ok my $hex = $hexgrid->hex(0,0), 'get a hex from the hexgrid';
ok my $grid = $hexgrid->hexgrid, 'get the grid as a hashref';

# triangle shape
ok my $trigrid = Math::HexGrid->new_triangle(2), 'create a triangle';
cmp_ok keys %{$trigrid->{map}}, '==', 6, 'trigrid has expected number of hexes';
cmp_ok $trigrid->count_sides, '==', 27, 'trigrid has expected number of sides';
ok my $hex2 = $trigrid->hex(0,0), 'get a hex from the trigrid';
ok my $grid2 = $trigrid->hexgrid, 'get the grid as a hashref';

done_testing;
