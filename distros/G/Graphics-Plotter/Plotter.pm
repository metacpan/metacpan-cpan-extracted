package Graphics::Plotter;

require Exporter;
require DynaLoader;
require AutoLoader;
use strict;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS $AUTOLOAD @op_codes @marker_symbols);
$VERSION = '1.0.2';

@ISA = qw(Exporter DynaLoader);

@op_codes = qw(
	O_ALABEL	O_ARC		O_ARCREL	O_BEZIER2
	O_BEZIER2REL	O_BEZIER3	O_BEZIER3REL	O_BGCOLOR
	O_BOX		O_BOXREL	O_CAPMOD	O_CIRCLE
	O_CIRCLEREL	O_CLOSEPL	O_COMMENT	O_CONT
	O_CONTREL	O_ELLARC	O_ELLARCREL	O_ELLIPSE
	O_ELLIPSEREL	O_ENDPATH	O_ERASE		O_FARC
	O_FARCREL	O_FBEZIER2	O_FBEZIER2REL	O_FBEZIER3
	O_FBEZIER3REL	O_FBOX		O_FBOXREL	O_FCIRCLE
	O_FCIRCLEREL	O_FCONCAT	O_FCONT		O_FCONTREL
	O_FELLARC	O_FELLARCREL	O_FELLIPSE	O_FELLIPSEREL
	O_FFONTSIZE	O_FILLTYPE	O_FILLCOLOR	O_FILLMOD
	O_FLINE		O_FLINEDASH	O_FLINEREL	O_FLINEWIDTH
	O_FMARKER	O_FMARKERREL	O_FMITERLIMIT	O_FMOVE
	O_FMOVEREL	O_FONTNAME	O_FONTSIZE	O_FPOINT
	O_FPOINTREL	O_FSPACE	O_FSPACE2	O_FTEXTANGLE
	O_JOINMOD	O_LABEL		O_LINE		O_LINEDASH
	O_LINEMOD	O_LINEREL	O_LINEWIDTH	O_MARKER
	O_MARKERREL	O_MOVE		O_MOVEREL	O_POINT
	O_POINTREL	O_RESTORESTATE	O_SAVESTATE	O_SPACE
	O_SPACE2	O_TEXTANGLE
);

@marker_symbols = qw(
	M_NONE M_DOT M_PLUS M_ASTERISK M_CIRCLE M_CROSS 
	M_SQUARE M_TRIANGLE M_DIAMOND M_STAR M_INVERTED_TRIANGLE 
	M_STARBURST M_FANCY_PLUS M_FANCY_CROSS M_FANCY_SQUARE 
	M_FANCY_DIAMOND M_FILLED_CIRCLE M_FILLED_SQUARE M_FILLED_TRIANGLE 
	M_FILLED_DIAMOND M_FILLED_INVERTED_TRIANGLE M_FILLED_FANCY_SQUARE
	M_FILLED_FANCY_DIAMOND M_HALF_FILLED_CIRCLE M_HALF_FILLED_SQUARE
	M_HALF_FILLED_TRIANGLE M_HALF_FILLED_DIAMOND
	M_HALF_FILLED_INVERTED_TRIANGLE M_HALF_FILLED_FANCY_SQUARE
	M_HALF_FILLED_FANCY_DIAMOND M_OCTAGON M_FILLED_OCTAGON 
);

@EXPORT_OK = (
	qw(parampl warning_handler error_handler),
	@op_codes,
	@marker_symbols
);

%EXPORT_TAGS = (
    # ONE-BYTE OPERATION CODES FOR GNU METAFILE FORMAT.
    'op_codes' => \@op_codes,
    # Symbol types for the marker() function, extending over the range 0..31.
    # (1 through 5 are the same as in the GKS [Graphical Kernel System].)
    'marker_symbols' => \@marker_symbols,
    'all' => [ @op_codes, @marker_symbols, qw(parampl warning_handler error_handler) ]
);

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    print STDERR "Checking $constname\n";
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    die "Called constant($constname) = $!\n";
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    my($pack,$file,$line) = caller;
	    die "Your vendor has not defined Plotter macro $pack\:\:$constname, used at $file line $line.\n";
	}
    }
    print STDERR "$constname checked as $val\n";
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}


bootstrap Graphics::Plotter $VERSION;

@Graphics::Plotter::Meta::ISA		= ('Graphics::Plotter');
@Graphics::Plotter::Tek::ISA		= ('Graphics::Plotter');
@Graphics::Plotter::HPGL::ISA		= ('Graphics::Plotter');
@Graphics::Plotter::PCL::ISA		= ('Graphics::Plotter::HPGL');
@Graphics::Plotter::Fig::ISA		= ('Graphics::Plotter');
@Graphics::Plotter::PS::ISA		= ('Graphics::Plotter');
@Graphics::Plotter::AI::ISA		= ('Graphics::Plotter');
@Graphics::Plotter::PNM::ISA		= ('Graphics::Plotter');
@Graphics::Plotter::GIF::ISA		= ('Graphics::Plotter');
@Graphics::Plotter::XDrawable::ISA	= ('Graphics::Plotter');
@Graphics::Plotter::X::ISA		= ('Graphics::Plotter::XDrawable');

1;
__END__

=head1 NAME

Graphics::Plotter - Perl extension for C++ plotter library from GNU plotutils

=head1 SYNOPSIS

  use Graphics::Plotter::<Type>;
  use Graphics::Plotter::<Type> qw(parampl);
  use Graphics::Plotter::<Type> qw(:marker_symbols :op_codes);
  use Graphics::Plotter::<Type> qw(:all);

=head1 EXAMPLE

  $handle = Graphics::Plotter::X->new(STDIN,STDOUT,STDERR);

  if ($handle->openpl() < 0) {
	die "Could not create plotter: $!\n";
  }

  $handle->fspace(0,0,1000,1000);
  $handle->flinewidth(0.25);
  $handle->pencolorname("red");
  $handle->erase();
  $handle->fmove(600,300);
  $handle->line(0,20,40 80);
  if ($handle->closepl() < 0) { die "closepl: $!\n";}

=head1 DESCRIPTION

Graphics::Plotter module is the Perl implementation of
the GNU plotutils' libplotter library - 
C++ function library for device-independent two-dimensional vector graphics.
There is also libplot library, based on C code, but with C++ library
you do not need to switch between plotters.

The plotutils distribution is written by
        Robert Maier <rsm@math.arizona.edu>
(http://www.gnu.org/software/plotutils/plotutils.html).
Descriptions of functions are based on Chapter 8 of plotutils info documentation.

The latest version of Graphics::Plotter perl module is available at CPAN.

The perl program can produce output in one of the following formats:

	X - new window on an X Window System display
	Xdrawable - existed X window or pixmap
	PNM - This is "portable anymap" format (PBM, PGM and PPM)
	GIF - Pseudo GIF (GIF format without LZW compression)
	AI - Adobe Illustrator (parameter ai)
	PS - idraw-editable Postscript (ps)
	Fig - xfig-editable format (fig)
	PCL - HP Printer Control Language format (pcl)
	HPGL - HP Graphics Language (hpgl)
	Tek - understood by Tektronix 4014 terminals (tek)
	Metafile - device-independent GNU graphics format (meta)

To open a plotter you have to create a plotter object, e.g.:

=head1 FUNCTION SUMMARY

This summary is BASED on plotutils info documentation. See plotutils
WWW page for more complete, more current, and more accurate
description. This summary is for the orientation only, and should
be enough is you do not ancounter any problem, and not using specific
driver functions.

=head2 Construction/Destruction of Plotters

=over 4

=item new ()

=item new (outfile)

=item new (infile,outfile,errfile)

creates a Plotter. You can select output, input
and error filehandles for that Plotter. It returns the handle
which is necessary for manipulating the Plotter. E.g.

	$object = Graphics::Plotter::X->new();
	# or even
	$disp_type = 'Meta'; # or 'X', 'AI', 'PS', etc.
	$plotter = "Graphics::Plotter" . $disp_type;
	$object = $plotter->new(STDIN, STDOUT, STDERR);

The default output is STDOUT.
All the commands should be passed to the previously created
plotter object, e.g. $object->function().

First command should be openpl(), which opens a plotter.
Program should close that plotter with the command closepl().
If plotter is opened then you can manipulate plotter, e.g. drawing
lines, cirles, changing colors etc.

=item openpl ()

opens a plotter, i.e., begins a page of graphics. This resets the Plotter's
drawing attributes to their default values. A negative return value
indicates the Plotter could not be opened.

=item closepl ()

closepl closes a Plotter, i.e., ends a page of graphics. A negative return
value indicates the Plotter could not be closed.

=item flushpl ()

flushes all plotting commands to the display device.

=item havecap (s)

havecap tests whether or not a Plotter, which need not be open, has a
specified capability. The return value is 0, 1, or 2, signifying no/yes/maybe.
For unrecognized capabilities the return value is zero.

=item parampl (parameter,value)

Sets the value of the device driver parameter to value. E.g.

parampl("BG_COLOR", "blue");

sets the background color.

=item erase ()

begins the next frame of a multiframe page, by clearing all previously
plotted objects from the graphics display, and filling it with the
background color (if any). 

=item bgcolor (red, green, blue)

bgcolor sets the background color for the Plotter's graphics display, using
a 48-bit RGB color model. The arguments red, green and blue specify the red,
green and blue intensities of the background color. Each is an integer in
the range 0x0000...0xffff, i.e., 0...65535.

=item bgcolorname (name)

bgcolorname sets the background color for the graphics display to be name.
unrecognized colors are interpreted as "white". bgcolorname and bgcolor has an
effect only on X Plotters and X Drawable Plotters.

=item space (x0,y0,x1,y1)
=item fspace (x0, y0, x1, y1)

take two pairs of arguments, specifying the positions of the lower left
corner and upper right corner of the graphics display, in user coordinates.
One of these operations must be performed at the beginning of each page
of graphics, i.e., immediately after openpl is invoked.

=item space2 (x0,y0,x1,y1)
=item fspace2 (x0, y0, x1, y1, x2, y2)

space2 and fspace2 are extended versions of space and fspace, and may be
used instead. Their arguments are the three defining vertices of an `Affine
window' (a drawing parallelogram), in user coordinates. The specified
vertices are the lower left, the lower right, and the upper left. This
window will be mapped affinely onto the graphics display.

=item warning_handler (SUBPTR)

warning_handler sets the default handler for warning messages (e.g. 
if there are some strange characters in label() function argument).
SUBPTR means a pointer to subroutine. The warning message is available
in @_ array variable. By default warning messages are displayed to the errfile
filehandle specified in new() function, as "libplot: message". Example of use:

warning_handler( sub { print "WARNING: $[$[]\n" } );

=item error_handler (SUBPTR)

error_handler sets the default handler for error messages. SUBPTR means a
pointer to subroutine. The error message is available in @_ array variable.
By default error messages are displayed to the errfile filehandle
specified in new() function, as "libplot: error: message".
Example of use:

error_handler( \&print_error );

=back

=head2 Drawing functions

The following are the "drawing functions". When invoked on a Plotter, these
functions cause it to draw objects (paths, circles, ellipses, points, markers,
and text strings) on the associated graphics display. A path is a sequence of
line segments and arcs (either circular or elliptic). Paths may be drawn
incrementally, one line segment or arc at a time.

=over 4

=item alabel (x_justify, y_justify, s)

Draws a justified text string (s). x_justify could be "l", "c" or "r" (left,
center and right justification. y_justify could be "b", "x", "c" or "t"
(bottom, baseline, center and top of the string will be placed even with the
current graphics cursor position.

=item arc (xc,yc,x0,y0,x1,y1)

=item farc (xc, yc, x0, y0, x1, y1)

=item farcrel (dxc, dyc, dx0, dy0, dx1, dy1)

arc and farc take six arguments specifying the beginning (x0, y0), end (x1,
y1), and center (xc, yc) of a circular arc. arcrel and farcrel use
cursor-relative coordinates.

=item bezier2 (x0, y0, x1, y1, x2, y2);

=item fbezier2 (double x0, double y0, double x1, double y1, double x2, double y2);

=item bezier2rel (x0, y0, x1, y1, x2, y2);

=item fbezier2rel (double x0, double y0, double x1, double y1, double x2, double y2);

bezier2 and fbezier2 take six arguments specifying the beginning p0=(x0, y0) and end p2=(x2, y2) of a quadratic Bezier curve, and its intermediate control point
p1=(x1, y1). The graphics cursor is moved to p2. bezier2rel and fbezier2rel are similar to bezier2 and fbezier2, but use
cursor-relative coordinates. The quadratic Bezier curve is tangent at p0 to the line segment joining p0 to p1, and is tangent at p2 to the line segment joining
p1 to p2. So it fits snugly into a triangle with vertices p0, p1, and p2.

=item bezier3 (x0, y0, x1, y1, x2, y2, x3, y3);

=item fbezier3 (x0, y0, x1, y1, x2, y2, x3, y3);

=item bezier3rel (x0, y0, x1, y1, x2, y2, x3, y3);

=item fbezier3rel (x0, y0, x1, y1, x2, y2, x3, y3);

bezier3 and fbezier3 take eight arguments specifying the beginning p0=(x0, y0) and end p3=(x3, y3) of a cubic Bezier curve, and its intermediate control points
p1=(x1, y1) and p2=(x2, y2). The graphics cursor is moved to p3. bezier3rel and fbezier3rel are similar to bezier3 and
fbezier3, but use cursor-relative coordinates. The cubic Bezier curve is tangent at p0 to the line segment joining p0 to p1, and is tangent at p3 to the line
segment joining p2 to p3. So it fits snugly into a quadrangle with vertices p0, p1, p2, and p3.


=item box (x0,y0,x1,y1)

=item boxrel (dx0, dy0, dx1, dy1)

=item fbox (x0, y0, x1, y1)

=item fboxrel (dx0, dy0, dx1, dy1)

box and fbox take four arguments specifying the lower left corner (x1, y1) and
upper right corner (x2, y2) of a `box', or rectangle. boxrel and fboxrel use
cursor-relative coordinates.

=item circle (x,y,r)

=item circlerel (dx, dy, r)

=item fcircle (x, y, r)

=item fcirclerel (dx, dy, r)

circle and fcircle take three arguments specifying the center (xc, yc) and
radius (r) of a circle. circlerel and fcirclerel use cursor-relative
coordinates for xc and yc.

=item cont (x,y)

=item contrel (x, y)

=item fcont (x, y)

=item fcontrel (x, y)

cont and fcont take two arguments specifying the coordinates (x, y) of a
point. If a path is under construction, the line segment from the current
graphics cursor position to the point (x, y) is added to it. Otherwise the
line segment begins a new path. In all cases the graphics cursor is
moved to (x, y). contrel and fcontrel use cursor-relative coordinates.

=item ellarc (xc, yc, x0, y0, x1, y1)

=item ellarcrel (dxc, dyc, dx0, dy0, dx1, dy1)

=item fellarc (xc, yc, x0, y0, x1, y1)

=item fellarcrel (dxc, dyc, dx0, dy0, dx1, dy1)

ellarc and fellarc take six arguments specifying the three points pc=(xc,yc),
p0=(x0,y0), and p1=(x1,y1) that define a so-called quarter ellipse. This is an
elliptic arc from p0 to p1 with center pc. The quarter-ellipse is an affinely
transformed version of a quarter circle.

=item ellipse (x, y, rx, ry, angle)

=item ellipserel (dx, dy, rx, ry, angle)

=item fellipse (x, y, rx, ry, angle)

=item fellipserel (dx, dy, rx, ry, angle)

ellipse and fellipse take five arguments specifying the center (xc, yc) of an
ellipse, the lengths of its semiaxes (rx and ry), and the inclination
of the first semiaxis in the counterclockwise direction from the
@math{x axis} in the user coordinate system. ellipserel and fellipserel use
cursor-relative coordinates.

=item endpath ()

endpath terminates the path under construction, if any. Paths, which are
formed by repeated calls to cont or fcont, arc or farc, ellarc or fellarc, and
line or fline, are also terminated if any other object is drawn or any
path-related drawing attribute is set. So endpath is almost
redundant. However, if a Plotter plots objects in real time, calling endpath
will ensure that a constructed path is drawn on the graphics display
without delay.

=item label (s)

label takes a single text argument s and draws a string at the current
graphics cursor position with left justification. Graphics cursor is moved to
the right end of the string. This function is equivalent to alabel(`l',`x',s).

=item labelwidth (s)

=item flabelwidth (s)

return the width of a string in the current font, in the user coordinate
system. The string is not plotted.

=item line (x0,y0,x1,y1)

=item linerel (dx0, dy0, dx1, dy1)

=item fline (x0, y0, x1, y1)

=item flinerel (dx0, dy0, dx1, dy1)

line and fline take four arguments specifying the start point (x1, y1) and end
point (x2, y2) of a line segment. linerel and flinerel use cursor-relative
coordinates.

=item marker (x, y, type, size)

=item markerrel (dx, dy, type, size)

=item fmarker (x, y, type, size)

=item fmarkerrel (dx, dy, type, size)

marker and fmarker take four arguments specifying the location (x,y) of a
marker symbol, its type, and its size in user coordinates. markerrel and
fmarkerrel use cursor-relative coordinates for the position (x,y). 
Marker symbol types 0 through 31 are taken from a standard set, and marker
symbol types 32 and above are interpreted as the index of a character in the
current text font. See plotutils documentation for more information.

=item move (x,y)

=item moverel (x, y)

=item fmove (x, y)

=item fmoverel (x, y)

move and fmove take two arguments specifying the coordinates (x, y) of a point
to which the graphics cursor should be moved without drawing any line.
moverel and fmoverel use cursor-relative coordinates. 

=item point (x,y)

=item pointrel (dx, dy)

=item fpoint (x, y)

=item fpointrel (dx, dy)

point and fpoint take two arguments specifying the coordinates (x, y) of a
point. The graphics cursor is moved to (x, y). pointrel and fpointrel use
cursor-relative coordinates.

=back

=head2 Attribute-setting functions

The following are the "attribute functions". When invoked on a Plotter, these
functions set its drawing attributes, or save them or restore them.
Path-related attributes include pen color, fill color, line width, line style,
cap style, and join style. Text-related attributes include pen color, font
name, font size, and text angle.

=over 4

=item capmod (s)

capmod sets the cap mode (i.e., cap style) for all paths subsequently drawn on
the graphics display. Recognized styles are "butt" (the default), "round", and
"projecting".

=item color (red, green, blue)

calling color is equivalent to calling both pencolor and fillcolor, to set
both the the pen color and fill color of all objects subsequently drawn on the
graphics display. Note that the physical fill color depends also on the fill
fraction, which is specified by calling filltype.

=item colorname (name)

calling colorname is equivalent to calling both pencolorname and
fillcolorname, to set both the the pen color and fill color of all objects
subsequently drawn on the graphics display.

=item filltype (level)

filltype sets the fill fraction for all subsequently drawn objects. A value of
0 for level indicates that objects should be unfilled, or transparent. This is
the default. A value in the range 0x0001...0xffff, i.e., 1...65535, indicates
that objects should be filled. A value of 1 signifies 100% filling (the fill
color will simply be the color specified by calling fillcolor or
fillcolorname). If level=0xffff, the fill color will be white. Values between
0x0001 and 0xffff are interpreted as specifying a desaturation, or gray level.
For example, 0x8000 specifies 50% filling.

=item fillcolor (red, green, blue)

fillcolor sets the fill color of all objects subsequently drawn on the
graphics display, using a 48-bit RGB color model.

=item fillcolorname (name)

fillcolorname sets the fill color of all objects subsequently drawn on the
graphics display to be name.

=item fillmod (s)

fillmod sets the fill mode, i.e., fill rule, for all objects
subsequently drawn on the graphics display.  The fill rule affects only
filled, self-intersecting paths: it determines which points are
`inside'.  Two rules are supported: "even-odd" (the default for all
Plotters), and "nonzero-winding". "alternate" is an alias
for "even-odd" and "winding" is an alias for "nonzero-winding".

=item fmiterlimit (limit)

fmiterlimit sets the miter limit for all paths subsequently drawn on
the graphics display.  The miter limit controls the treatment of
corners, if the join mode is set to "miter" (the default).  At a
join point of a path, the `miter length' is defined to be the distance
between the inner corner and the outer corner.  The miter limit is the
maximum value that will be tolerated for the miter length divided by the
line thickness.  If this value is exceeded, the miter will be cut
off: the "bevel" join mode will be used instead.

Examples of typical values for limit are 10.43 (the default, which
cuts off miters if the join angle is less than 11 degrees), 2.0 (the
same, for 60 degrees), and 1.414 (the same, for 90 degrees).  In
general, the miter limit is the cosecant of one-half the minimum angle
for mitered joins.  The minimum meaningful value for limit is
1.0, which converts all mitered joins to beveled joins, irrespective of
join angle.  Specifying a value less than 1.0 resets the limit to the
default.

=item fontname (s)

=item ffontname (s)

fontname and ffontname take a single case-insensitive string argument,
font_name, specifying the name of the font to be used for all text strings
subsequently drawn on the graphics display. (The font for plotting strings is
fully specified by calling fontname, fontsize, and textangle.) The size of the
font in user coordinates is returned.

=item fontsize (size)

=item ffontsize (size)

fontsize and ffontsize take a single argument, interpreted as the size, in the
user coordinate system, of the font to be used for all text strings
subsequently drawn on the graphics display. The size of the font in user
coordinates is returned. A negative value for size sets the size to a default
value, which depends on the type of Plotter.

=item joinmod (s)

joinmod sets the join mode (i.e., join style) for all paths subsequently drawn
on the graphics display. Recognized styles are "miter" (the default), "round",
and "bevel".

=item linedash (\@dashes, offset)

=item flinedash (\@dashes, offset)

linedash and flinedash set the line style for all paths,
circles, and ellipses subsequently drawn on the graphics display.  They
provide much finer control of dash patterns than the linemod
function (see below) provides. dashes should be an array of
length n.  Its elements, which should be positive, are
interpreted as distances in the user coordinate system.  Along any path,
circle, or ellipse, the elements
dashes[0]...dashes[n-1] alternately specify the
length of a dash and the length of a gap between dashes.  When the end
of the array is reached, the reading of the array wraps around to the
beginning.  If the array is empty, i.e., n equals zero, there is
no dashing: the drawn line is solid.

The offset argument specifies the `phase' of the dash pattern
relative to the start of the path.  It is interpreted as the distance
into the dash pattern at which the dashing should begin.  For example,
if offset equals zero then the path will begin with a dash, of
length dashes[0] in user space.  If offset equals
dashes[0] then the path will begin with a gap of length
dashes[1], and so forth. offset is allowed to be
negative. Example:

flinedash([30, 4, 10, 3],0)

=item linemod (s)

linemod sets the linemode (i.e., line style) for all paths, circles, and
ellipses subsequently drawn on the graphics display. The supported linemodes
are "disconnected", "solid", "dotted", "dotdashed", "shortdashed", and
"longdashed". The final five correspond more or less to the following bit
patterns:

 "solid"             --------------------------------
 "dotted"            - - - - - - - - - - - - - - - -
 "dotdashed"         -----------  -  -----------  -
 "shortdashed"       --------        --------
 "longdashed"        ------------    ------------

Circles and ellipses that are drawn when the linemode is "disconnected" will
be invisible. Disconnected paths, circles, and ellipses are not filled.

=item linewidth (size)

=item flinewidth (size)

linewidth and flinewidth set the width, in the user coordinate system, of all
paths, circles, and ellipses subsequently drawn on the graphics display. A
negative value means that a default width should be used. The default and zero
width depends on the type of Plotter.

=item pencolor (red, green, blue)

pencolor sets the pen color of all objects subsequently drawn on the graphics
display, using a 48-bit RGB color model.

=item pencolorname (name)

pencolorname sets the pen color of all objects subsequently drawn on the
graphics display to be name.

=item restorestate ()

restorestate pops the current graphics context off the stack of drawing
states. The graphics context consists largely of libplot's drawing attributes,
which are set by the attribute functions documented in this section. A path
under construction is regarded as part of the graphics context. For this
reason, calling restorestate automatically calls endpath to terminate the path
under construction. All graphics contexts on the stack are popped off when
closepl is called, as if restorestate had been called repeatedly.

=item savestate ()

savestate pushes the current graphics context onto the stack of drawing
states. When a graphics context is returned to, the path under construction
may be continued.

=item textangle (angle)

=item ftextangle (angle)

textangle and ftextangle take one argument, which specifies the angle in
degrees counterclockwise from the @math{x} (horizontal) axis in the user
coordinate system, for text strings subsequently drawn on the graphics
display. The default angle is zero. The size of the font for plotting strings,
in user coordinates, is returned.

=back

=head2 Mapping functions

The following are the "mapping functions". When invoked on a Plotter, these
functions affect the affine transformation it employs for mapping from the
user coordinate system to the device coordinate system. They may be viewed as
performing transformations of the user coordinate system. Their names resemble
those of the corresponding functions in the Postscript language.

=over 4

=item fconcat (m0, m1, m2, m3, tx, ty)

Apply a Postscript-style transformation matrix, i.e., affine map, to the user
coordinate system. That is, apply the linear transformation defined by the
two-by-two matrix [m0 m1 m2 m3] to the user coordinate system, and also
translate by tx units in the @math{x direction} and ty units in the
@w{@math{y} direction}, relative to the former user coordinate system. The
three functions (frotate, fscale, ftranslate) are special cases of fconcat.

=item frotate (theta)

Rotate the user coordinate system axes about their origin by theta degrees,
with respect to their former orientation. The position of the user coordinate
origin and the size of the @math{x} @w{and @math{y}} units remain unchanged.

=item fscale (sx, sy)

Make the @math{x} and @math{y} units in the user coordinate system be the size
of sx and sy units in the former user coordinate system. The position of the
user coordinate origin and the orientation of the coordinate axes are
unchanged.

=item ftranslate (tx, ty)

Move the origin of the user coordinate system by tx units in the @math{x
direction} and ty units in the @w{@math{y} direction}, relative to the former
user coordinate system. The size of the @math{x} and @w{@math{y} units} and
the orientation of the coordinate axes are unchanged.

=back

=head2 Device driver parameters

With the parampl function you can set the following device dependent driver 
parameters:

=over 4

=item DISPLAY

(Default NULL.) The X Window System display on which the graphics display will
be popped up, as an X window. This is relevant only to X Plotters.

=item BITMAPSIZE

(Default "570x570".) The size of the graphics display in terms of pixels. This
is relevant only to X Plotters. If this parameter is not set, its value will
automatically be taken from the X resource Xplot.geometry.

=item PAGESIZE

(Default "letter".) The size of the page on which the graphics display will be
positioned. This is relevant only to Illustrator, Postscript, Fig, PCL, and
HP-GL Plotters. "letter" means an 8.5in by 11in page. Any ISO page size in the
range "a0"..."a4" or ANSI page size in the range "a"..."e" may be specified
("letter" is an alias for "a" and "tabloid" is an alias for "b"). "legal",
"ledger", and "b5" are recognized page sizes also.

=item AI_VERSION

(Default "5".) Relevant only to Illustrator Plotters. Recognized values are
"5" and "3". "5" means that the output should be in the format used by version
5 of Adobe Illustrator, which is recognized by all later versions.

=item BG_COLOR

(Default "white".) The initial background color of the graphics display, when
drawing each page of graphics. This is relevant to X Plotters and X Drawable
Plotters, although for the latter, the background color shows up only if erase
is invoked. The background color may be changed at any later time by invoking
the bgcolor (or bgcolorname) and erase operations.

=item HPGL_ASSIGN_COLORS

(Default "no".) Relevant only to HP-GL Plotters, and only if the value of
HPGL_VERSION is "2". "no" means to draw with a fixed set of pens, specified by
setting the HPGL_PENS parameter. "yes" means that pen colors will not
restricted to the palette specified in HPGL_PENS: colors will be assigned to
"logical pens" in the range #1...#31, as needed. Other than color LaserJet
printers and DesignJet plotters, not many HP-GL/2 devices allow the assignment
of colors to logical pens. So this parameter should be used with caution.

=item HPGL_OPAQUE_MODE

(Default "yes".) Relevant only to HP-GL Plotters, and only if the value of
HPGL_VERSION is "2". "yes" means that the HP-GL/2 output device should be
switched into opaque mode, rather than transparent mode. This allows objects
to be filled with opaque white and other opaque colors. It also allows the
drawing of visible white lines, which by convention are drawn with pen #0.

=item HPGL_PENS

(Default "1=black:2=red:3=green:4=yellow:5=blue:6=magenta:7=cyan" if the value
of HPGL_VERSION is "1.5" or "2" and "1=black" if the value of HPGL_VERSION is
"1". Relevant only to HP-GL Plotters. The set of available pens; the format
should be self-explanatory. The color for any pen in the range #1...#31 may be
specified. Pen #1 must always be present, though it need not be black. Any
other pen in the range #1...#31 may be omitted.

=item HPGL_ROTATE

(Default "0".) Relevant only to HP-GL Plotters. The angle, in degrees, by
which the graphics display should be rotated on the page relative to the
default orientation. Recognized values are "0", "90", "180", and "270"; "no"
and "yes" are equivalent to "0" and "90" respectively. This parameter is
provided to facilitate switching between portrait and landscape orientations.
"180" and "270" are supported only if HPGL_VERSION is "2".

=item HPGL_VERSION

(Default "2".) Relevant only to HP-GL Plotters. "1" means that the output
should be generic HP-GL, "1.5" means that the output should be suitable for
the HP7550A graphics plotter and the HP758x, HP7595A and HP7596A drafting
plotters (HP-GL with some HP-GL/2 extensions), and "2" means that the output
should be modern HP-GL/2. If the version is "1" or "1.5" then the only
available fonts will be vector fonts, and all paths will be drawn with a
default width. Additionally, if the version is "1" then the filling of
arbitrary paths will not be supported (circles and rectangles aligned with the
coordinate axes may be filled).

=item HPGL_XOFFSET, HPGL_YOFFSET

(Defaults "0.0cm" and "0.0cm".) Relevant only to HP-GL Plotters. Adjustments,
in the @math{x and @math{y}} directions, of the position of the graphics
display on the page. They may be specified in centimeters, millimeters, or
inches. For example, an offset could be specified as "2cm" or "1.2in".

=item MAX_LINE_LENGTH

(Default "500".) The maximum number of points that a path may contain, before
it is flushed to the display device. If this flushing occurs, the path will be
split into two or more sub-paths, though the splitting should not be
noticeable. Splitting will not be performed if the path is filled. This
parameter is relevant to X, X Drawable, Illustrator, Postscript, Fig, PCL, and
HP-GL Plotters. The reason for splitting long paths is that some display
devices (e.g., old Postscript printers and HP-GL plotters) have limited buffer
sizes. It is not relevant to Tektronix or Metafile Plotters, since they draw
paths in real time and have no buffer limitations.

=item META_PORTABLE

(Default "no".) Relevant only to Metafile Plotters. "yes" means that the
output should be in a portable (human-readable) version of the metafile
format, rather than the default (binary) version.

=item PCL_ASSIGN_COLORS

(Default "no".) Relevant only to PCL Plotters. "no" means to draw with a fixed
set of pens. "yes" means that pen colors will not restricted to this palette:
colors will be assigned to "logical pens", as needed. Other than color
LaserJet printers, not many PCL 5 devices allow the assignment of colors to
logical pens. So this parameter should be used with caution.

=item PCL_ROTATE

(Default "0".) Relevant only to PCL Plotters. See explonation for HPGL_ROTATE.

=item PCL_XOFFSET, PCL_YOFFSET

(Defaults "0.0cm" and "0.0cm".) Relevant only to PCL Plotters. See explonation
for HPGL_XOFFSET.

=item TERM

(Default NULL.) Relevant only to Tektronix Plotters.

=item USE_DOUBLE_BUFFERING

(Default "no".) Relevant only to X Plotters and X Drawable Plotters. If the
value is "yes", each frame of graphics, within a openpl...closepl pair, is
written to an off-screen buffer rather than to the Plotter's display. When
erase is invoked to end a frame, or when closepl is invoked, the contents of
the off-screen buffer are copied to the Plotter's display, pixel by pixel.
This double buffering scheme is useful in creating the illusion of smooth
animation. The "fast" is an alias for "yes". If there are standard DBE and MBX
extensions to the X11 protocol to communicate with the display is available
then these extensions are used. It may yield much faster animation.

=item VANISH_ON_DELETE

(Default "no".) Relevant only to X Plotters. If the value is "yes", when a
Plotter is deleted, the window or windows that it has popped up will vanish.
Otherwise, each such window will remain on the screen until it is
removed by the user (by typing `q' in it, or by clicking with a mouse).

=item XDRAWABLE_COLORMAP

(Default NULL.) Relevant only to X Drawable Plotters. If the value is
non-NULL, it should be a Colormap *, a pointer to a colormap from which colors
should be allocated. NULL indicates that the colormap to be used should be the
default colormap of the default screen of the X display.

=item XDRAWABLE_DISPLAY

(Default NULL.) Relevant only to X Drawable Plotters. The value should be a
Display *, a pointer to the X display with which the drawable(s) to be drawn
in are associated.

=item XDRAWABLE_DRAWABLE1

=item XDRAWABLE_DRAWABLE2

(Default NULL.) Relevant only to X Drawable Plotters. If set, the value of
each of these parameters should be a Drawable *, a pointer to a drawable to be
drawn in. A `drawable' is either a window or a pixmap. At the time an X
Drawable Plotter is created, at least one of the two parameters must be set. X
Drawable Plotters support simultaneous drawing in two drawables because it is
often useful to be able to draw graphics simultaneously in both an X window
and its background pixmap. If two drawables are specified, they must have the
same dimensions and depth, and be associated with the same screen of the X
display.

=back

For more information on device driver parameters, fonts, strings and symbols,
markers, color names, markers, metafile format see plotutils documentation.

=head1 Exported constants and functions

You can export the following functions: parampl, warning_handler and
error_handler. parampl is a static function of the Plotter superclass.
warning_handler and error_handler sets the pointer to the error message
handler functions.

You can import into the main namespace the op codes (for metafile format) with
the command: use Graphics::Plotter qw(:marker_symbols), and the marker symbols,
with the command: use Graphics::Plotter qw(:op_codes), or both of them with the
command: use Graphics::Plotter qw(:all).
See plotutils documentation for the explanation how to use op codes and
marker symbols.

=head1 AUTHOR

Piotr Klaban <post@klaban.torun.pl>

=head1 SEE ALSO

perl(1), plotutils documentation

=cut
