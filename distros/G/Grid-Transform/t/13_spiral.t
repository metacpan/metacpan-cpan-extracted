use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new(['a'..'o'], rows=>3);
is($g->spiral, $g, 'returns self');
is_deeply([$g->grid], [qw(a b c d e j o n m l k f g h i)], 'grid');
is($g->rows, 3, 'rows');
is($g->columns, 5, 'columns');
