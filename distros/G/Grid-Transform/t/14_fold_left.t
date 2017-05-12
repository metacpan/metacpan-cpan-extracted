use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new(['a'..'o'], rows=>3);
is($g->fold_left, $g, 'returns self');
is_deeply([$g->grid], [qw(e a d b c j f i g h o k n l m)], 'grid');
is($g->rows, 3, 'rows');
is($g->columns, 5, 'columns');
