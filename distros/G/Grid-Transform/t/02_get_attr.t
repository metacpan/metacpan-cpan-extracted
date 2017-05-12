use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new([1..27], rows=>5);
is_deeply(scalar $g->grid, [1..27, '', '', ''], 'scalar grid()');
is_deeply([$g->grid], [1..27, '', '', ''], 'grid()');
is($g->rows, 5, 'rows');
is($g->columns, 6, 'columns');
