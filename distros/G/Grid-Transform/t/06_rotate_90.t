use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new(['a'..'o'], rows => 3);
is($g->rotate_90, $g, 'returns self');
is_deeply([$g->grid], [qw(k f a l g b m h c n i d o j e)], 'grid');
is($g->rows, 5, 'rows');
is($g->columns, 3, 'columns');
