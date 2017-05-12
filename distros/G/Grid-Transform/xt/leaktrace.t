use strict;
use warnings;
use Grid::Transform;
use Test::More;

eval "use Test::LeakTrace; 1" or do {
    plan skip_all => 'Test::LeakTrace is not installed.';
};
plan tests => 1;

my $try = sub {
    my $g = Grid::Transform->new(['a'..'o'], rows=>5);
    $g->rotate_270->flip_vertical;
    my @grid = $g->grid;
    my $grid = $g->grid;
    $g->grid(['aa'..'mm']);

    my $rows    = $g->rows;
    my $columns = $g->columns;
    $g->rows(5);
    $g->columns(5);

    $g->rotate_90;
    $g->rotate_180;
    $g->rotate_270;
    $g->flip_horizontal->flip_vertical;
    $g->transpose->fold_left;
    $g->counter_transpose;
    $g->alternate_row_direction->spiral;
};

$try->();

is( leaked_count($try), 0, 'leaks' );

# leaktrace($try, '-verbose');
