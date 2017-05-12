use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new(['a'..'o'], rows => 3);
is($g->flip_vertical, $g, 'returns self');
is_deeply([$g->grid], [qw(k l m n o f g h i j a b c d e)], 'grid');
is($g->rows, 3, 'rows');
is($g->columns, 5, 'columns');
