#!perl

use strict;
use warnings;

use Test2::V0;

use File::Temp qw(tempfile);
use Graphics::Grid::Functions qw(:all);
use Graphics::Grid::Driver::Cairo;

pass("Graphics::Grid::Functions loads");

{
    my $driver = grid_driver( width => 800, height => 600 );
    is( [ $driver->width, $driver->height ], [ 800, 600 ], 'grid_driver()' );
}

{
    my $driver = Graphics::Grid::Driver::Cairo->new();
    my $driver_out = grid_driver( driver => $driver );
    is( [ $driver->width, $driver->height ], [ 1000, 1000 ], 'grid_driver()' );
}

{
    grid_driver( width => 900, height => 300, format => 'svg' );
    grid_rect();    # draw white background

    for my $setting (
        { color => 'red',   x => 1 / 6 },
        { color => 'green', x => 0.5 },
        { color => 'blue',  x => 5 / 6 }
      )
    {
        push_viewport(
            viewport(
                x      => $setting->{x},
                y      => 0.5,
                width  => 0.2,
                height => 0.6
            )
        );
        grid_rect( gp => { fill => $setting->{color}, lty => 'blank' } );
        grid_text( label => $setting->{color}, y => -0.1 );

        pop_viewport();
    }

    my ( $fh, $svg_filename ) = tempfile( SUFFIX => '.svg' );
    grid_write($svg_filename);

    ok( ( -r $svg_filename ), 'a small demo looks good' );
}

done_testing;
