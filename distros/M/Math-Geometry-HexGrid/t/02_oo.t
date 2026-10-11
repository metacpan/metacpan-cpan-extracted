use strict;
use warnings;
use Test::More;
use Math::Geometry::HexGrid;

my $h1 = Math::Geometry::HexGrid->hex(4, 4);
my $h2 = Math::Geometry::HexGrid->hex(4, 4);
my $h3 = Math::Geometry::HexGrid->hex(6, 4);

is($h1->col, 4, 'col accessor');
is($h1->row, 4, 'row accessor');

ok($h1 == $h2, 'equality overload ==');
ok($h1 != $h3, 'inequality overload !=');
is("$h1", "4,4", 'stringification overload ""');

is($h1->distance_to($h3), 2, 'distance_to method');
ok($h1->is_collinear_with($h3), 'is_collinear_with method');

my @nbs = $h1->neighbors;
is(scalar(@nbs), 6, 'neighbors count');
isa_ok($nbs[0], 'Math::Geometry::HexGrid::Hex');

my @ray = $h1->ray_to($h3);
is(scalar(@ray), 2, 'ray_to count');
is("$ray[0]", "5,4", 'ray first step');
is("$ray[1]", "6,4", 'ray destination');

done_testing();
