use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new(['a'..'o'], rows => 3);
is($g->rotate_180, $g, 'returns self');
is_deeply([$g->grid], [reverse 'a'..'o'], 'grid');
is($g->rows, 3, 'rows');
is($g->columns, 5, 'columns');
