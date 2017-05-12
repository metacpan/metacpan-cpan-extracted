use strict;
use warnings;
use Test::More tests => 5;
use Grid::Transform;

my $g = eval { Grid::Transform->new };
ok(! defined $g, 'new()');

my @array = ('a' .. 'z');

$g = eval { Grid::Transform->new(\@array) };
ok(! defined $g, 'new(\@array)');

$g = Grid::Transform->new(\@array, rows=>5);
isa_ok($g, 'Grid::Transform', 'new(\@array, rows=>5');

$g = Grid::Transform->new([@array], rows=>5);
isa_ok($g, 'Grid::Transform', 'new([@array], rows=>5');

my @methods = qw(
    new copy rows columns cols grid rotate_180 rotate180 rotate_90 rotate90
    rotate_270 rotate270 flip_horizontal mirror_horizontal flip_vertical
    mirror_vertical transpose counter_transpose countertranspose
    fold_right fold_left alternate_row_direction alt_row_dir spiral
);
can_ok('Grid::Transform', @methods);
