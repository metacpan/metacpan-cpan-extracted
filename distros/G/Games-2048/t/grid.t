use 5.012;
use strictures;
use Test::More;
use Games::2048;

my $grid = Games::2048::Grid->new(size => 2);
my $big_grid = Games::2048::Grid->new;

isa_ok $grid, "Games::2048::Grid", "grid";
isa_ok $big_grid, "Games::2048::Grid", "big_grid";

is $grid->size, 2, "set size in constructor";
is $big_grid->size, 4, "default size";

done_testing;

__END__

is scalar @{$grid->cells}, 2, "grid initialised rows";
is scalar @{$grid->cells->[0]}, 2, "grid initialised col 0";
is scalar @{$grid->cells->[1]}, 2, "grid initialised col 1";

is scalar @{$big_grid->cells}, 4, "big_grid initialised rows";
is scalar @{$big_grid->cells->[0]}, 4, "big_grid initialised col";

is scalar $grid->each_cell, 4, "grid each_cell returns all cells";
is scalar $big_grid->each_cell, 16, "big_grid each_cell returns all cells";

$grid->cells->[0][1] = 1;
$grid->cells->[1][0] = 2;

is_deeply
	[ $grid->each_cell ],
	[ [0, 0, undef], [1, 0, 1], [0, 1, 2], [1, 1, undef] ],
	"grid each_cell returns cells in the right order 1";

$grid->clear;
is scalar $grid->each_cell, 4, "grid still has cells after clear";
is scalar @{$big_grid->cells}, 4, "grid still has cells after clear";
is_deeply
	[ $grid->each_cell ],
	[ [0, 0, undef], [1, 0, undef], [0, 1, undef], [1, 1, undef] ],
	"grid has all undef cells after clear";

$grid->cells->[1][0] = 3;
$grid->cells->[1][1] = 4;

is_deeply
	[ $grid->each_cell ],
	[ [0, 0, undef], [1, 0, undef], [0, 1, 3], [1, 1, 4] ],
	"grid each_cell returns cells in the right order 2";

is_deeply [ $grid->available_cells ], [ [0, 0, undef], [1, 0, undef] ], "grid 2 available cells";

$grid->cells->[0][0] = 5;
is_deeply [ $grid->available_cells ], [ [1, 0, undef] ], "grid 1 available cell";

$grid->cells->[0][1] = 6;
is_deeply [ $grid->available_cells ], [], "grid 0 available cells";

$grid->clear;
is_deeply [ $grid->available_cells ], [ $grid->each_cell ], "grid all cells available";

ok $grid->within_bounds(0, 0), "0, 1 is within bounds";
ok $grid->within_bounds(1, 1), "1, 1 is within bounds";
ok $grid->within_bounds(0, 1), "0, 1 is within bounds";
ok $grid->within_bounds(1, 0), "1, 0 is within bounds";
ok !$grid->within_bounds(2, 0), "2 is not within bounds";
ok !$grid->within_bounds(0, -1), "-1 is not within bounds";
ok $big_grid->within_bounds(3, 0), "3 is within bounds of big_grid";

done_testing;
