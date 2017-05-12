use strict;
use warnings;
use Test::More;
use Grid::Transform;

my $g = Grid::Transform->new([1..27], rows=>5, columns=>6);

ok($g->rows(6), 'setting new rows');
is($g->rows, 6, 'checking new rows');
is_deeply(scalar $g->grid, [1..27, ('')x9], 'resulting scalar grid from new rows');
is_deeply([$g->grid], [1..27, ('')x9], 'resulting grid from new rows');

ok($g->columns(4), 'setting new columns');
is($g->columns, 4, 'checking new columns');
is_deeply([$g->grid], [1..24], 'resulting grid from new columns');

done_testing;
