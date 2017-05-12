use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new(['a'..'o'], rows=>3);
is($g->transpose, $g, 'returns self');
is_deeply([$g->grid], [qw(o j e n i d m h c l g b k f a)], 'grid');
is($g->rows, 5, 'rows');
is($g->columns, 3, 'columns');
