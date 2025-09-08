[![Actions Status](https://github.com/gamk67/Graphics-Penplotter-GcodeXY/actions/workflows/test.yml/badge.svg)](https://github.com/gamk67/Graphics-Penplotter-GcodeXY/actions)
# NAME

GcodeXY - Produce gcode files for pen plotters from Perl

# SYNOPSIS

    use Graphics::Penplotters::GcodeXY;
    # create a new GcodeXY object
    $g = new Graphics::Penplotters::GcodeXY( papersize => "A4", units => "in");
    # draw some lines and other shapes
    $g->line(1,1, 1,4);
    $g->box(1.5,1, 2,3.5);
    $g->polygon(1,1, 1,2, 2,2, 2,1, 1,1);
    # write the output to a file
    $g->output("file.gcode");

# DESCRIPTION

`GcodeXY` provides a method for generating gcode for pen plotters (hence the XY)
from Perl. It has graphics primitives that allow arcs, lines, polygons, and rectangles to
be drawn as line segments. Units used can be specified ("mm" or "in" or "pt").
The default unit is an inch, which is used internally. Other units are scaled accordingly.
The only gcode commands generated are G00 and G01. Fonts are supported, SVG input is possible,
and Postscript output can be generated as well.

# DEPENDENCIES

This module requires `Math::Bezier`, and `Math::Trig`. For SVG import you will
need `Image::SVG::Transform` and `XML::Parser` and `Image::SVG::Path` and `POSIX` and
`List::Util` and `Font::FreeType`.

# CONSTRUCTOR

- `new(options)`

    Create a new GcodeXY object. The different options that can be set are:

    - check

        Print the bounding box of the gcode design; report on what page sizes it would fit;
        present an estimate of the distance to pen has to move on and off the paper; report
        on the number of pen cycles.

    - curvepts

        Set the number of sampling points for curves, default 50. This can be overridden for each
        individual curve. The number is reduced for small curves.

    - hatchsep

        Specifies the spacing of the hatching lines.

    - header

        Specifies a header to be inserted at the start of the output file. The default is
        `G20\nG90\nG17\nF 50\nG92 X 0 Y 0 Z 0\nG00 Z 0\n` which specifies, respectively,
        use inches (change to G21 for mm), absolute distance mode, use the XY plane only,
        a feedrate of 50 inches per minute (change this if you use other units, or if you are impatient),
        and use the current head position as the origin. The last command is the penup command,
        which **must** terminate the header.

    - id

        This is an identifying string, useful when you have several objects in your program.
        Some diagnostics will print the id.

    - margin

        This number indicates a percentage of whitespace that is to be maintained around the page,
        when using the `split` method. This is useful, for example, to stop the pen from overshooting
        the edge, cause damage to the paper, or allow glueing together of several sheets. This number will be
        doubled, all coordinates will be reduced by this percentage, and the whole page will be centered,
        creating the margin on all sides.

    - opt\_debug

        Enable debugging output from the optimizer. Useful only to the developer of this module.

    - optimize

        This flag controls the internal peephole optimizer. The default is 1 (ON). Setting it to 0
        switches it off, which may be necessary in some cases, but this may of course result in very
        inefficient execution.

    - outfile

        The name of the file to which the generated gcode is to be written.

    - papersize

        The size of paper to use, if `xsize` or `ysize` are not defined. This allows
        a document to easily be created using a standard paper size without having to
        remember the size of paper. Valid choices are the usual ones such as
        `A3`, `A4`, `A5`, and `Letter`, but the full range is available. Used to warn about
        out-of-bound movement. The `xsize` and `ysize` will be set accordingly.

    - penupcmd

        Lifts the pen off the paper. The default is `G00 Z 0\n`.

    - pendowncmd

        Lowers the pen onto the paper. The default is `G00 Z 0.2\n`. The distance
        of 0.2 inches (i.e. 5 mm) is highly dependent on the plotter and its setup,
        so this may well have to be adjusted. 

    - trailer

        Specifies a trailer to be inserted at the end of the output file. The default is
        `G00 Z 0\nG00 X 0 Y 0\n` which lifts the pen and returns it to the origin.

    - units

        Units that are to be used in the file. Currently supported are `mm`, `in`, `pc`, `cm`, `px`
        and `pt`.

    - warn

        Generate a warning if an instruction would take the pen outside the boundary specified
        with the `papersize` or the `xsize` or `ysize` variables. It is a fatal error if either
        one has not been specified.

    - xsize

        Specifies the width of the drawing area in units. Used to warn about out-of-bound
        movement.

    - ysize

        Specifies the height of the drawing area in units. Used to warn about out-of-bound
        movement.

    Example:

            $ref = new Graphics::Penplotters::GcodeXY( xsize  => 4,
                            ysize      => 3,
                            units      => "in",
                            warn       => 1,
                            check      => 1,
                            pendowncmd => "G00 Z 0.1\n");

# OBJECT METHODS

Unless otherwise specified, object methods return 1 for success or 0 in some
error condition (e.g. insufficient arguments).

- addcomment(string)

    Add a comment to the output. The string will be enclosed in round brackets and a newline
    will be added. The current path is not flushed first. This command is useful mainly for
    debugging. Note that comments will likely cause the optimizer to be less effective.

- addfontpath(string, \[string, ...\])

    Add location(s) to search for fonts to the set of builtin paths. This should be an absolute
    pathname. The default search path specifies the local directory, the user's private .fonts
    directory, and the global font directory in /usr/share/fonts. You will probably have to use
    this function if you want to use LaTeX fonts.

- addtopage(string)

    Inserts the `string`, which should be a gcode command or a comment. In case of a comment,
    the string should be enclosed in round brackets. Use with care, needless to say. The string
    is inserted directly into the output stream, after the current path has been flushed, so
    you are also responsible for making sure that each line is terminated by a newline.
    Please note that you may have to adjust the `currentpoint` after using this command.

- arc(x, y, r, a, b \[, number\])

    Draws an arc (i.e. part of a circle). This requires an x coordinate, a y coordinate,
    a radius, a starting angle and a finish angle. The pen will be moved to the start point.
    The optional number overrides the default number of sampling points, and is used in this call only.

- arcto(x1, y1, x2, y2, r)

    Starting from the current position, draw a line to (`x1`,`y1`) and then to (`x2`,`y2`),
    but generate a "shortcut" with an arc of radius `r`, making a rounded corner. This command is
    equivalent to the Postscript instruction of the same name.

- arrowhead(length, width \[, type\])

    Draw an arrowhead, i.e. two or three small lines, normally at the end of a line segment. The
    direction and position of the arrowhead is derived from the last line segment on the current
    path. If the path is empty, the current point is used for the position, and the direction will
    be horizontal and towards increasing x-coordinate. The type can be 'open' (which causes two
    backwards directed lines to be drawn), or 'closed' (where also a line across is drawn).

- box(x1,y1 \[, x2,y2\])

    Draw a rectangle from lower left co-ordinates (`x1`,`y1`) to upper right co-ordinates (`y2`,`y2`).
    If just two parameters are passed, the current position is assumed to be the lower left hand corner.
    The pen will be lifted first, a fast move will be executed to (`x1`,`y1`), and the pen will be
    lowered. The sides of the rectangle will then be drawn.

    Example:

        $g->box(10,10, 20,30);

    Note: the `polygon` method is far more flexible, but this method is more convenient.

- boxR(x,y)

    Draw a rectangle from the current position to the relative upper right co-ordinates (`x`,`y`).

    Example:

        $g->boxR(2,3);

- boxround(r, x1,y1, x2,y2)

    Draw a rectangle from lower left co-ordinates (`x1`,`y1`) to upper right co-ordinates (`y2`,`y2`),
    using rounded corners as determined by the radius perameter `r`. The pen will be lifted first,
    a fast move will be executed to the midpoint of the bottom edge, and the pen will be lowered.
    The sides and arcs of the rectangle will then be drawn in a clockwise direction.

    Example (pt units):

        $g->boxround(20, 100,100, 200,300);

- circle(x, y, r \[, number\])

    Draws a circular arc. This requires an x coordinate, a y coordinate,and a radius.
    The pen will be moved to the start point. The required number of sampling points is estimated
    based on the value of the radius. The optional `number` overrides this number of sampling points,
    and is used in this call only. The current point is left at (`x`+`r`,`y`).

- ($x, $y) = currentpoint()

    Returns the current location of the pen in user coordinates. It is also possible to pass two
    parameters to this method, in which case the current point is set to that position.

- curve(points)

    Calculates a Bezier curve using the array of `points`. The pen will be moved to the start point.
    The number of sampling points is determined by `curvepoints` which can be set during creation
    of the GcodeXY object. For quadratic and cubic curves, the optimal number of sampling points
    will be calculated automatically.

- curveto(points)

    Calculates a Bezier curve using the array of `points`, starting from the current position.
    The number of sampling points is determined by `curvepoints` which can be set during creation
    of the GcodeXY object. For quadratic and cubic curves, the optimal number of sampling points
    will be calculated automatically.

- ellipse(x, y, a , b \[, number\])

    Draws an ellipse. This requires an x coordinate, a y coordinate, a horizontal width and
    a vertical width. The pen will be moved to the start point. The required number of sampling points
    is estimated based on the value of the radius. The optional `number` overrides this number of
    sampling points, and is used in this call only.

- getsegpath()

    Get a copy of the current segment path. This returns an array of hashes containing the start and end
    points of the segments.
    Example:
        @points = getsegpath();

- grestore()

    Restore the previous graphics state, which should have been saved with `gsave`.

- gsave()

    Save the current graphics state (e.g. paths, current transformation matrix) onto the graphics stack.

- importsvg(filename)

    Imports an SVG file. Your mileage may vary with this one - not the entire SVG spec (900 pages!)
    is implemented. If you get warnings about this, the result may well be be incorrect, especially
    with `use` and `defs` tags. Just one layer is implemented. The good news is that the 'vpype'
    software produces simple SVG output that is 100% compatible, so if you do get problems try
    vpype with the '--linesort' option or similar.

    All the graphics shapes are implemented, as well as paths and transforms. Note that some SVGs
    contain clever tricks that may result in incorrect displays. SVG designs use a different
    coordinate system (top down) from the one used in this module. It is therefore essential to
    save and restore the graphics state around this function, and also to scale and rotate 
    the svg to an appropriate size and orientation. Here is a typical example:

            $g->gsave();                  # save the current graphics state
            $g->initmatrix();             # start a new, pristine graphics state
            $g->translate($my_x, $my_y);  # move to page location where the svg must appear
            $g->rotate($my_degrees);      # rotate the coordinate system as required
            $g->scale($my_scale);         # scale the svg as required, negative creates mirror image
            $g->importsvg('myfile.svg');  # finally import the svg
            $g->grestore();               # restore the previous graphics state

    Note that exporting SVG from GcodeXY generates a full page SVG, so no translation or rotation 
    will be needed. 

- initmatrix()

    Reset the Current Transformation Matrix (CTM) to the unit matrix, thereby cancelling all previous
    `translate`, `rotate`, `scale` and `skew` operations.

- line(x1,y1, x2,y2)

    Draws a line from the co-ordinates (`x1`,`y1`) to (`x2`,`y2`). The pen will be lifted first,
    a fast move will be executed to (x1,y1), and the pen will be lowered. Then a slow move
    to (x2,y2) is performed.

    Example:

        $g->line(10,10, 10,20);

- lineR(x,y)

    Draws a line from the current position (cx,cy) to (cx+`x`,cy+`y`), i.e. relative coordinates.
    The pen is assumed to be lowered.

    Example:

        $g->lineR(2,1);

- moveto(x,y)

    Inserts gcode to move the pen to the specified location. The pen will be lifted first, and
    lowered at the destination.

- movetoR(x,y)

    Inserts gcode to move the pen to the specified location using relative displacements.
    You should not normally need this command, unless you insert your own code. The pen will be
    lifted first, and lowered at the destination.

- newsegpath()

    Initialize the segment path, used for hatching. This is done automatically for fonts and for 
    all the built-in shapes. Use this function if you define your own series of shapes.

- output(\[filename\])

    Writes the current gcode out to the file named `filename`, or, if not specified, to the
    filename specified using `outfile` when the gcode object was created. This will destroy
    any existing file of the same name. Use this method whenever output to file is required.
    The current gcode document in memory is not cleared, and can still be extended. If the
    `check` flag is set, some statistics are printed, including the bounding box.

- exporteps(filename)

    Writes the current gcode out to the file named `filename` in the form of encapsulated
    Postscript. This will destroy any existing file of the same name. The current gcode document
    in memory is not cleared, and can still be extended. If the `check` flag is set, the bounding
    box is printed.

- exportsvg(filename)

    Writes the current gcode out to the file named `filename` in the form of a full page SVG file.
    This will destroy any existing file of the same name. The current gcode document in memory is
    not cleared, and can still be extended. If the `check` flag is set, the bounding box is printed.
    The boundingbox is returned (bottom left x and y, and top right x and y).

- pageborder(margin)

    Create a border round the page, with a `margin` specified in current units.

- pendown()

    Inserts the pendown command, causing the pen to be lowered onto the paper.

- penup()

    Inserts the penup command, causing the pen to be lifted from the paper.

- polygon(x1,y1, x2,y2, ..., xn,yn)

    The `polygon` method is multi-function, allowing many shapes to be created and
    manipulated. The pen will be lifted first, a fast move will be executed to (`x1`,`y1`),
    and the pen will be lowered. Lines will then be drawn from (`x1`,`y1`) to (`x2`,`y2`) and
    then from (`x2`,`y2`) to (`x3`,`y3`) up to (`xn-1`,`yn-1`) to (`xn`,`yn`).

    Example:

        # draw a square with lower left point at (10,10)
        $g->polygon(10,10, 10,20, 20,20, 20,10, 10,10);

- polygonR(x1,y1, x2,y2, ..., xn,yn)

    This method is multi-function, allowing many shapes to be created and manipulated relative
    to the current position (cx,cy). The pen is assumed to be lowered. Lines will then be drawn
    to (cx+`x1`,cy+`y1`), then to (cx+`x2`,cy+`y2`), and so on.

    Example:

        # draw a square with lower left point at (10,10)
        $g->polygonR(1,1, 1,2, 2,2, 2,1, 1,1);

- polygonround(r, x1,y1, x2,y2, ..., xn,yn)

    Draws a polygon starting from the current position, using absolute coordinates, with rounded
    corners between the line segments whose radius is dtermined by `r`. Lines with rounded corners
    will then be drawn from (`x1`,`y1`) to (`x2`,`y2`), and so on.

    Example:

        # draw a square with lower left point at (10,10)
        $g->polygonround(20, 100,200, 200,200, 200,100, 100,100);

- rotate(degrees \[, refx, refy\])

    Rotate the coordinate system by `degrees`. If the optional reference point (`refx`,`refy`) is
    not specified, the origin is assumed.

- scale(sx \[, sy \[, refx, refy\]\])

    Scale the coordinate system by `sx` in the x direction and `sy` in the y direction.
    If `sy` is not specified it is assumed to be the same as `sx`. If the optional reference
    point (`refx`,`refy`) is not specified, the origin is assumed. Negative parameters will
    cause the direction of movement to be reversed.

- $face = setfont(name, size)

    Tries to locate the font called `name`, and returns a `face` object if successful. This object
    is then used for subsequent rendering using `stroketext`. Note that the `size` parameter has
    to be in points, which is the unit used by the Freetype library (and is, indeed, the standard
    everywhere). It is not advisable to use any other unit when rendering text.

- setfontsize(size)

    Set the default fontsize to be used for rendering to `size`. See the caveat under `setfont`:
    if you must use other units than 'pt', it is your responsibility to scale the size appropriately.

- sethatchsep(width)

    When hatching, the space between hatch lines is set to `width`.

- skewX(degrees)

    Schedule a skew (also called shear) in the X direction. This operation works relative to the
    origin, so a suitable `translate` operation may be required first, otherwise the results might
    be unexpected.

- skewY(degrees)

    Schedule a skew (also called shear) in the Y direction. This operation works relative to the
    origin, so a suitable `translate` operation may be required first, otherwise the results might
    be unexpected.

- split(size, filestem)

    Split the current sheet into smaller sized sheets, and write the results into separate files.
    `size` is, for example, "A4". The `filestem` prefix will be extended with the sheet numbers,
    for example, foo\_0\_0.gcode, foo\_0\_1.gcode, etc.

- stroke()

    Render the current path, i.e. translate the path into gcode.

- strokefill()

    Render the current path, i.e. translate the path into gcode, and fill it with a hatch pattern.

- stroketext(face, string)

    Render a `string` using the `face` object returned by `setfont`. To render a character code,
    use "chr(charcode)" instead of "string". A `stroke` operation is applied after each character.

- stroketextfill(face, string)

    Render a `string` using the `face` object returned by `setfont`. To render a character code,
    use "chr(charcode)" instead of "string". A `stroke` operation is applied after each character.
    Each character is filled with a hatch pattern. 

- $w = textwidth(face, string)

    Calculate the width of a `string` using the `face` object returned by `setfont`. The returned
    value is in page coordinates, i.e. the value is not subject to current transformations.

- translateC()

    Move the origin of the coordinate system to the current location, as returned by `currentpoint`.

- translate(x,y)

    Move the origin of the coordinate system to (`x`,`y`). Both parameters are locations specified
    in the current coordinate system, and are thus subjected to rotation and scaling.

- $v = vpype\_linesort()

    Sends the current design to vpype in order to sort the line segments in such a way that pen travel
    is minimized. Needless to say, vpype needs to be installed and on your path. A new graphics 
    object is returned containing the optimized path. This command will be very useful when hatching
    of fonts and other shapes has been performed. In the process, two temporary files will be created
    and destroyed.

# BUGS AND LIMITATIONS

As noted above, the SVG specification (900 pages) is only partially implemented, and just one layer
can be used. I suspect that diagnostics about pen travel distance may not always be correct.
Clipping is not supported. Layering is not supported officially, but can be simulated.

# AUTHOR

Albert Koelmans (albert.koelmans@googlemail.com).

# LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms
as Perl itself.
