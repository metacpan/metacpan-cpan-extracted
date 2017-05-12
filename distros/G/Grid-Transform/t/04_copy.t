use strict;
use warnings;
use Test::More tests => 5;
use Grid::Transform;

my $g = Grid::Transform->new([1..27], rows=>5);
my $copy = $g->copy;
ok(1, 'copy');
is_deeply([$copy->grid], [$g->grid], 'grid');
isnt($copy->grid, $g->grid, 'copy aref is different');
is($copy->rows, $g->rows, 'rows');
is($copy->columns, $g->columns, 'columns');
