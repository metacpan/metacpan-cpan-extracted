use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new(['a'..'o'], rows => 3);
is($g->flip_horizontal, $g, 'returns self');
is_deeply([$g->grid], [qw(e d c b a j i h g f o n m l k)], 'grid');
is($g->rows, 3, 'rows');
is($g->columns, 5, 'columns');
