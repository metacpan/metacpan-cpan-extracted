# NAME

Grid - create geometric grids

# SYNOPSYS

    use Grid;

    my $grid = Grid->new($grid_width, $grid_height, $item_width, $item_height, $gutter, $border, $arrangement);

# DESCRIPTION

Grid creates an array of x-y positions for items of a given height and width arranged in a grid. This is used to create grid layouts on a page, or repeate items on a number of pages of the same size.

# REQUIRES

[POSIX](https://metacpan.org/pod/POSIX) 

[List::AllUtils](https://metacpan.org/pod/List%3A%3AAllUtils) 

[Moose::Util::TypeConstraints](https://metacpan.org/pod/Moose%3A%3AUtil%3A%3ATypeConstraints) 

[Moose](https://metacpan.org/pod/Moose) 

# METHODS

## bbox

    $grid->bbox();

Returns the total bounding box of the grid 

## numbers

    $grid->numbers();

Returns the sequence item numbers, with the top left item as item 1.

    +---------+---------+---------+---------+
    |         |         |         |         |
    |    1    |    2    |    3    |    4    |
    |         |         |         |         |
    +---------+---------+---------+---------+
    |         |         |         |         |
    |    5    |    6    |    7    |    8    |
    |         |         |         |         |
    +---------+---------+---------+---------+
    |         |         |         |         |
    |    9    |   10    |   11    |   12    |
    |         |         |         |         |
    +---------+---------+---------+---------+

## sequence

    $grid->sequence();

Returns the sequence of x-y grid item coordinates, with the top left item as item `[0, 0]`, the next one (assuming a horizontal arrangement) being `[1, 0]` etc. 

    +---------+---------+---------+---------+
    |         |         |         |         |
    | [0, 0]  | [0, 1]  | [0, 2]  | [0, 3]  |
    |         |         |         |         |
    +---------+---------+---------+---------+
    |         |         |         |         |
    | [1, 0]  | [1, 1]  | [1, 2]  | [1, 3]  |
    |         |         |         |         |
    +---------+---------+---------+---------+
    |         |         |         |         |
    | [2, 0]  | [2, 1]  | [2, 2]  | [2, 3]  |
    |         |         |         |         |
    +---------+---------+---------+---------+

## positions

    $grid->positions();

Returns the sequence of x-y grid coordinates, taking optional offsets. If two offsets are provided, the x-y position is offset accordingly, and if four are provided, it returns a boumding box.

## total\_height

    $grid->total_height();

The total height of the grid

## total\_width

    $grid->total_width();

The total width of the grid

# To do

- Allow for different vertical and horizontal gutters 
- Allow for different top, bottom, left right borders
- Allow for bottom or top start of grid
