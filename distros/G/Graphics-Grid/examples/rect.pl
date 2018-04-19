#!perl

use 5.014;
use warnings;

use Graphics::Grid::Functions qw(:all);

# have a 1cm border completely in the viewport
grid_rect(
    height => unit(1) - unit( 1, "cm" ),
    width  => unit(1) - unit( 1, "cm" ),
    gp => Graphics::Grid::GPar->new( col => 'blue', lwd => 1 / 2.54 * 96 ),
);
grid_write("rect.png");

