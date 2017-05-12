use strict;
use warnings;
use Test::More tests => 4;
use Grid::Transform;

my $g = Grid::Transform->new(['a'..'o'], rows => 3);
is($g->rotate_270, $g, 'returns self');
is_deeply([$g->grid], [qw(e j o d i n c h m b g l a f k)], 'grid');
is($g->rows, 5, 'rows');
is($g->columns, 3, 'columns');
