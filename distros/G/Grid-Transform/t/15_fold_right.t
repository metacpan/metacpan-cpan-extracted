use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new(['a'..'o'], rows => 3);
is($g->fold_right, $g, 'returns self');
is_deeply([$g->grid], [qw(c b d a e h g i f j m l n k o)], 'grid');
is($g->rows, 3, 'rows');
is($g->columns, 5, 'columns');
