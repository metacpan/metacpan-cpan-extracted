# NAME

Imager::LineTrace - Line tracer

# SYNOPSIS

    use Imager::LineTrace;

    my $img = Imager::LineTrace->new( file => $ARGV[0] ) or die Imager->errstr;
    my $figures_ref = $img->line_trace();

# DESCRIPTION

    # Tracing clockwise from left top.

Expected Input and Result

    # Enter a figure made up of line vertical or horizontal.
    my $img = Imager::LineTrace->new( xsize => 16, ysize => 16 );
    $img->box( filled => 1, color => 'white' );
    $img->setpixel( x => 3, y => 2, color => '#000000' );
    $img->line( x1 => 6, y1 => 5,
                x2 => 9, y2 => 5, color => '#333333' );
    $img->polyline( points => [
            [ 2,  8 ],
            [ 5,  8 ],
            [ 5, 11 ]
        ], color => '#666666' );
    $img->box( xmin => 10, ymin => 10,
               xmax => 14, ymax => 14, color => '#999999' );

    my $figures_ref = $img->line_trace();

    # from Sample/bmp2figure.pl
    my $i = 0;
    foreach my $figure (@{$figures_ref}) {
        print "-------- [", $i++, "] --------", "\n";
        print "type        : ", $figure->{type}, "\n";
        print "trace_value : ", sprintf("0x%06X", $figure->{value}), "\n";
        print "is_close: ", $figure->{is_closed}, "\n";
        foreach my $p (@{$figure->{points}}) {
            printf( "(%2d,%2d)\n", $p->[0], $p->[1] );
        }
    }

    # -------- [0] --------
    # type        : Point
    # trace_value : 0x000000
    # is_closed   : 0
    # ( 3, 2)
    # -------- [1] --------
    # type        : Line
    # trace_value : 0x333333
    # is_closed   : 0
    # ( 6, 5)
    # ( 9, 5)
    # -------- [2] --------
    # type        : Polyline
    # trace_value : 0x666666
    # is_closed   : 0
    # ( 2, 8)
    # ( 5, 8)
    # ( 5,11)
    # -------- [3] --------
    # type        : Polygon
    # trace_value : 0x999999
    # is_closed   : 1
    # (10,10)
    # (14,10)
    # (14,14)
    # (10,14)

Basic Overview

    my $img = Imager::LineTrace->new( file => $path ) or die Imager->errstr;

    # Trace black line on white.
    my $figures_ref = $img->line_trace();

    # If you want to trace counter-clockwise from left bottom.
    $img->filp( dir => 'v' );
    my $figures_ref = $img->line_trace();

    # If you want to select color. ( 0:R, 1:G, 2:B, 3:Alpha )
    my $figures_ref = $img->line_trace( channels => [0] );

    # Or you want to trace with R,G and B.(this is defalt.)
    my $figures_ref = $img->line_trace( channels => [0,1,2] );

    # If you want to trace not black color.
    my $figures_ref = $img->line_trace( ignore => 0 );

    # If you want to trace many figure. (default "limit" is 1024)
    my $figures_ref = $img->line_trace( limit => 10000 );

# LICENSE

Copyright (C) neko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

neko <techno.cat.miau@gmail.com>
