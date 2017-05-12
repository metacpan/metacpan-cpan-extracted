use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new(['a'..'o'], rows=>3);
is($g->counter_transpose, $g, 'returns self');
is_deeply([$g->grid], [qw(a f k b g l c h m d i n e j o)], 'grid');
is($g->rows, 5, 'rows');
is($g->columns, 3, 'columns');
