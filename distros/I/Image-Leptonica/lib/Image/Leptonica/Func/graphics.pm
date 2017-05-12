package Image::Leptonica::Func::graphics;
$Image::Leptonica::Func::graphics::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::graphics

=head1 VERSION

version 0.04

=head1 C<graphics.c>

  graphics.c

      Pta generation for arbitrary shapes built with lines
          PTA        *generatePtaLine()
          PTA        *generatePtaWideLine()
          PTA        *generatePtaBox()
          PTA        *generatePtaBoxa()
          PTA        *generatePtaHashBox()
          PTA        *generatePtaHashBoxa()
          PTAA       *generatePtaaBoxa()
          PTAA       *generatePtaaHashBoxa()
          PTA        *generatePtaPolyline()
          PTA        *convertPtaLineTo4cc()
          PTA        *generatePtaFilledCircle()
          PTA        *generatePtaFilledSquare()
          PTA        *generatePtaLineFromPt()
          l_int32     locatePtRadially()

      Pta generation for plotting functions on images
          PTA        *generatePlotPtaFromNuma()

      Pta rendering
          l_int32     pixRenderPta()
          l_int32     pixRenderPtaArb()
          l_int32     pixRenderPtaBlend()

      Rendering of arbitrary shapes built with lines
          l_int32     pixRenderLine()
          l_int32     pixRenderLineArb()
          l_int32     pixRenderLineBlend()

          l_int32     pixRenderBox()
          l_int32     pixRenderBoxArb()
          l_int32     pixRenderBoxBlend()

          l_int32     pixRenderBoxa()
          l_int32     pixRenderBoxaArb()
          l_int32     pixRenderBoxaBlend()

          l_int32     pixRenderHashBox()
          l_int32     pixRenderHashBoxArb()
          l_int32     pixRenderHashBoxBlend()

          l_int32     pixRenderHashBoxa()
          l_int32     pixRenderHashBoxaArb()
          l_int32     pixRenderHashBoxaBlend()

          l_int32     pixRenderPolyline()
          l_int32     pixRenderPolylineArb()
          l_int32     pixRenderPolylineBlend()

          l_int32     pixRenderRandomCmapPtaa()

      Rendering and filling of polygons
          PIX        *pixRenderPolygon()
          PIX        *pixFillPolygon()

      Contour rendering on grayscale images
          PIX        *pixRenderContours()
          PIX        *fpixAutoRenderContours()
          PIX        *fpixRenderContours()

  The line rendering functions are relatively crude, but they
  get the job done for most simple situations.  We use the pta
  as an intermediate data structure.  A pta is generated
  for a line.  One of two rendering functions are used to
  render this onto a Pix.

=head1 FUNCTIONS

=head2 convertPtaLineTo4cc

PTA * convertPtaLineTo4cc ( PTA *ptas )

  convertPtaLineTo4cc()

      Input:  ptas (8-connected line of points)
      Return: ptad (4-connected line), or null on error

  Notes:
      (1) When a polyline is generated with width = 1, the resulting
          line is not 4-connected in general.  This function adds
          points as necessary to convert the line to 4-cconnected.
          It is useful when rendering 1 bpp on a pix.
      (2) Do not use this for lines generated with width > 1.

=head2 fpixAutoRenderContours

PIX * fpixAutoRenderContours ( FPIX *fpix, l_int32 ncontours )

  fpixAutoRenderContours()

      Input:  fpix
              ncontours (> 1, < 500, typ. about 50)
      Return: pixd (8 bpp), or null on error

  Notes:
      (1) The increment is set to get approximately @ncontours.
      (2) The proximity to the target value for contour display
          is set to 0.15.
      (3) Negative values are rendered in red; positive values as black.

=head2 fpixRenderContours

PIX * fpixRenderContours ( FPIX *fpixs, l_float32 incr, l_float32 proxim )

  fpixRenderContours()

      Input:  fpixs
              incr  (increment between contours; must be > 0.0)
              proxim (required proximity to target value; default 0.15)
      Return: pixd (8 bpp), or null on error

  Notes:
      (1) Values are displayed when val/incr is within +-proxim
          to an integer.  The default value is 0.15; smaller values
          result in thinner contour lines.
      (2) Negative values are rendered in red; positive values as black.

=head2 generatePlotPtaFromNuma

PTA * generatePlotPtaFromNuma ( NUMA *na, l_int32 orient, l_int32 width, l_int32 refpos, l_int32 max, l_int32 drawref )

  generatePlotPtaFromNuma()

      Input:  numa
              orient (L_HORIZONTAL_LINE, L_VERTICAL_LINE)
              width (width of "line" that is drawn; between 1 and 7)
              refpos (reference position: y for horizontal and x for vertical)
              max (maximum excursion in pixels from baseline)
              drawref (1 to draw the reference line and the normal to it)
      Return: ptad, or null on error

  Notes:
      (1) This generates points from a numa representing y(x) or x(y)
          with respect to a pix.  For y(x), we draw a horizontal line
          at the reference position and a vertical line at the edge; then
          we draw the values of the numa, scaled so that the maximum
          excursion from the reference position is @max pixels.
      (2) The width is chosen in the interval [1 ... 7].
      (3) @refpos should be chosen so the plot is entirely within the pix
          that it will be painted onto.
      (4) This would typically be used to plot, in place, a function
          computed along pixels rows or columns.

=head2 generatePtaBox

PTA * generatePtaBox ( BOX *box, l_int32 width )

  generatePtaBox()

      Input:  box
              width (of line)
      Return: ptad, or null on error

  Notes:
      (1) Because the box is constructed so that we don't have any
          overlapping lines, there is no need to remove duplicates.

=head2 generatePtaBoxa

PTA * generatePtaBoxa ( BOXA *boxa, l_int32 width, l_int32 removedups )

  generatePtaBoxa()

      Input:  boxa
              width
              removedups  (1 to remove, 0 to leave)
      Return: ptad, or null on error

  Notes:
      (1) If the boxa has overlapping boxes, and if blending will
          be used to give a transparent effect, transparency
          artifacts at line intersections can be removed using
          removedups = 1.

=head2 generatePtaFilledCircle

PTA * generatePtaFilledCircle ( l_int32 radius )

  generatePtaFilledCircle()

      Input:  radius
      Return: pta, or null on error

  Notes:
      (1) The circle is has diameter = 2 * radius + 1.
      (2) It is located with the center of the circle at the
          point (radius, radius).
      (3) Consequently, it typically must be translated if
          it is to represent a set of pixels in an image.

=head2 generatePtaFilledSquare

PTA * generatePtaFilledSquare ( l_int32 side )

  generatePtaFilledSquare()

      Input:  side
      Return: pta, or null on error

  Notes:
      (1) The center of the square can be chosen to be at
          (side / 2, side / 2).  It must be translated by this amount
          when used for replication.

=head2 generatePtaHashBox

PTA * generatePtaHashBox ( BOX *box, l_int32 spacing, l_int32 width, l_int32 orient, l_int32 outline )

  generatePtaHashBox()

      Input:  box
              spacing (spacing between lines; must be > 1)
              width  (of line)
              orient  (orientation of lines: L_HORIZONTAL_LINE, ...)
              outline  (0 to skip drawing box outline)
      Return: ptad, or null on error

  Notes:
      (1) The orientation takes on one of 4 orientations (horiz, vertical,
          slope +1, slope -1).
      (2) The full outline is also drawn if @outline = 1.

=head2 generatePtaHashBoxa

PTA * generatePtaHashBoxa ( BOXA *boxa, l_int32 spacing, l_int32 width, l_int32 orient, l_int32 outline, l_int32 removedups )

  generatePtaHashBoxa()

      Input:  boxa
              spacing (spacing between lines; must be > 1)
              width  (of line)
              orient  (orientation of lines: L_HORIZONTAL_LINE, ...)
              outline  (0 to skip drawing box outline)
              removedups  (1 to remove, 0 to leave)
      Return: ptad, or null on error

  Notes:
      (1) The orientation takes on one of 4 orientations (horiz, vertical,
          slope +1, slope -1).
      (2) The full outline is also drawn if @outline = 1.
      (3) If the boxa has overlapping boxes, and if blending will
          be used to give a transparent effect, transparency
          artifacts at line intersections can be removed using
          removedups = 1.

=head2 generatePtaLine

PTA * generatePtaLine ( l_int32 x1, l_int32 y1, l_int32 x2, l_int32 y2 )

  generatePtaLine()

      Input:  x1, y1  (end point 1)
              x2, y2  (end point 2)
      Return: pta, or null on error

  Notes:
      (1) Uses Bresenham line drawing, which results in an 8-connected line.

=head2 generatePtaLineFromPt

PTA * generatePtaLineFromPt ( l_int32 x, l_int32 y, l_float64 length, l_float64 radang )

  generatePtaLineFromPt()

      Input:  x, y  (point of origination)
              length (of line, including starting point)
              radang (angle in radians, CW from horizontal)
      Return: pta, or null on error

  Notes:
      (1) The @length of the line is 1 greater than the distance
          used in locatePtRadially().  Example: a distance of 1
          gives rise to a length of 2.

=head2 generatePtaPolyline

PTA * generatePtaPolyline ( PTA *ptas, l_int32 width, l_int32 closeflag, l_int32 removedups )

  generatePtaPolyline()

      Input:  pta (vertices of polyline)
              width
              closeflag (1 to close the contour; 0 otherwise)
              removedups  (1 to remove, 0 to leave)
      Return: ptad, or null on error

=head2 generatePtaWideLine

PTA * generatePtaWideLine ( l_int32 x1, l_int32 y1, l_int32 x2, l_int32 y2, l_int32 width )

  generatePtaWideLine()

      Input:  x1, y1  (end point 1)
              x2, y2  (end point 2)
              width
      Return: ptaj, or null on error

=head2 generatePtaaBoxa

PTAA * generatePtaaBoxa ( BOXA *boxa )

  generatePtaaBoxa()

      Input:  boxa
      Return: ptaa, or null on error

  Notes:
      (1) This generates a pta of the four corners for each box in
          the boxa.
      (2) Each of these pta can be rendered onto a pix with random colors,
          by using pixRenderRandomCmapPtaa() with closeflag = 1.

=head2 generatePtaaHashBoxa

PTAA * generatePtaaHashBoxa ( BOXA *boxa, l_int32 spacing, l_int32 width, l_int32 orient, l_int32 outline )

  generatePtaaHashBoxa()

      Input:  boxa
              spacing (spacing between hash lines; must be > 1)
              width  (hash line width)
              orient  (orientation of lines: L_HORIZONTAL_LINE, ...)
              outline  (0 to skip drawing box outline)
      Return: ptaa, or null on error

  Notes:
      (1) The orientation takes on one of 4 orientations (horiz, vertical,
          slope +1, slope -1).
      (2) The full outline is also drawn if @outline = 1.
      (3) Each of these pta can be rendered onto a pix with random colors,
          by using pixRenderRandomCmapPtaa() with closeflag = 1.

=head2 locatePtRadially

l_int32 locatePtRadially ( l_int32 xr, l_int32 yr, l_float64 dist, l_float64 radang, l_float64 *px, l_float64 *py )

  locatePtRadially()

      Input:  xr, yr  (reference point)
              radang (angle in radians, CW from horizontal)
              dist (distance of point from reference point along line
                    given by the specified angle)
              &x, &y (<return> location of point)
      Return: 0 if OK, 1 on error

=head2 pixFillPolygon

PIX * pixFillPolygon ( PIX *pixs, PTA *pta, l_int32 xmin, l_int32 ymin )

  pixFillPolygon()

      Input:  pixs (1 bpp, with 4-connected polygon outline)
              pta (vertices of the polygon)
              xmin, ymin (min values of vertices of polygon)
      Return: pixd (with outline filled), or null on error

  Notes:
      (1) This fills the interior of the polygon, returning a
          new pix.  It works for both convex and non-convex polygons.
      (2) To generate a filled polygon from a pta:
            PIX *pixt = pixRenderPolygon(pta, 1, &xmin, &ymin);
            PIX *pixd = pixFillPolygon(pixt, pta, xmin, ymin);
            pixDestroy(&pixt);

=head2 pixRenderBox

l_int32 pixRenderBox ( PIX *pix, BOX *box, l_int32 width, l_int32 op )

  pixRenderBox()

      Input:  pix
              box
              width  (thickness of box lines)
              op  (one of L_SET_PIXELS, L_CLEAR_PIXELS, L_FLIP_PIXELS)
      Return: 0 if OK, 1 on error

=head2 pixRenderBoxArb

l_int32 pixRenderBoxArb ( PIX *pix, BOX *box, l_int32 width, l_uint8 rval, l_uint8 gval, l_uint8 bval )

  pixRenderBoxArb()

      Input:  pix (any depth, cmapped ok)
              box
              width  (thickness of box lines)
              rval, gval, bval
      Return: 0 if OK, 1 on error

=head2 pixRenderBoxBlend

l_int32 pixRenderBoxBlend ( PIX *pix, BOX *box, l_int32 width, l_uint8 rval, l_uint8 gval, l_uint8 bval, l_float32 fract )

  pixRenderBoxBlend()

      Input:  pix
              box
              width  (thickness of box lines)
              rval, gval, bval
              fract (in [0.0 - 1.0]; complete transparency (no effect)
                     if 0.0; no transparency if 1.0)
      Return: 0 if OK, 1 on error

=head2 pixRenderBoxa

l_int32 pixRenderBoxa ( PIX *pix, BOXA *boxa, l_int32 width, l_int32 op )

  pixRenderBoxa()

      Input:  pix
              boxa
              width  (thickness of line)
              op  (one of L_SET_PIXELS, L_CLEAR_PIXELS, L_FLIP_PIXELS)
      Return: 0 if OK, 1 on error

=head2 pixRenderBoxaArb

l_int32 pixRenderBoxaArb ( PIX *pix, BOXA *boxa, l_int32 width, l_uint8 rval, l_uint8 gval, l_uint8 bval )

  pixRenderBoxaArb()

      Input:  pix
              boxa
              width  (thickness of line)
              rval, gval, bval
      Return: 0 if OK, 1 on error

=head2 pixRenderBoxaBlend

l_int32 pixRenderBoxaBlend ( PIX *pix, BOXA *boxa, l_int32 width, l_uint8 rval, l_uint8 gval, l_uint8 bval, l_float32 fract, l_int32 removedups )

  pixRenderBoxaBlend()

      Input:  pix
              boxa
              width  (thickness of line)
              rval, gval, bval
              fract (in [0.0 - 1.0]; complete transparency (no effect)
                     if 0.0; no transparency if 1.0)
              removedups  (1 to remove; 0 otherwise)
      Return: 0 if OK, 1 on error

=head2 pixRenderContours

PIX * pixRenderContours ( PIX *pixs, l_int32 startval, l_int32 incr, l_int32 outdepth )

  pixRenderContours()

      Input:  pixs (8 or 16 bpp; no colormap)
              startval (value of lowest contour; must be in [0 ... maxval])
              incr  (increment to next contour; must be > 0)
              outdepth (either 1 or depth of pixs)
      Return: pixd, or null on error

  Notes:
      (1) The output can be either 1 bpp, showing just the contour
          lines, or a copy of the input pixs with the contour lines
          superposed.

=head2 pixRenderHashBox

l_int32 pixRenderHashBox ( PIX *pix, BOX *box, l_int32 spacing, l_int32 width, l_int32 orient, l_int32 outline, l_int32 op )

  pixRenderHashBox()

      Input:  pix
              box
              spacing (spacing between lines; must be > 1)
              width  (thickness of box and hash lines)
              orient  (orientation of lines: L_HORIZONTAL_LINE, ...)
              outline  (0 to skip drawing box outline)
              op  (one of L_SET_PIXELS, L_CLEAR_PIXELS, L_FLIP_PIXELS)
      Return: 0 if OK, 1 on error

=head2 pixRenderHashBoxArb

l_int32 pixRenderHashBoxArb ( PIX *pix, BOX *box, l_int32 spacing, l_int32 width, l_int32 orient, l_int32 outline, l_int32 rval, l_int32 gval, l_int32 bval )

  pixRenderHashBoxArb()

      Input:  pix
              box
              spacing (spacing between lines; must be > 1)
              width  (thickness of box and hash lines)
              orient  (orientation of lines: L_HORIZONTAL_LINE, ...)
              outline  (0 to skip drawing box outline)
              rval, gval, bval
      Return: 0 if OK, 1 on error

=head2 pixRenderHashBoxBlend

l_int32 pixRenderHashBoxBlend ( PIX *pix, BOX *box, l_int32 spacing, l_int32 width, l_int32 orient, l_int32 outline, l_int32 rval, l_int32 gval, l_int32 bval, l_float32 fract )

  pixRenderHashBoxBlend()

      Input:  pix
              box
              spacing (spacing between lines; must be > 1)
              width  (thickness of box and hash lines)
              orient  (orientation of lines: L_HORIZONTAL_LINE, ...)
              outline  (0 to skip drawing box outline)
              rval, gval, bval
              fract (in [0.0 - 1.0]; complete transparency (no effect)
                     if 0.0; no transparency if 1.0)
      Return: 0 if OK, 1 on error

=head2 pixRenderHashBoxa

l_int32 pixRenderHashBoxa ( PIX *pix, BOXA *boxa, l_int32 spacing, l_int32 width, l_int32 orient, l_int32 outline, l_int32 op )

  pixRenderHashBoxa()

      Input:  pix
              boxa
              spacing (spacing between lines; must be > 1)
              width  (thickness of box and hash lines)
              orient  (orientation of lines: L_HORIZONTAL_LINE, ...)
              outline  (0 to skip drawing box outline)
              op  (one of L_SET_PIXELS, L_CLEAR_PIXELS, L_FLIP_PIXELS)
      Return: 0 if OK, 1 on error

=head2 pixRenderHashBoxaArb

l_int32 pixRenderHashBoxaArb ( PIX *pix, BOXA *boxa, l_int32 spacing, l_int32 width, l_int32 orient, l_int32 outline, l_int32 rval, l_int32 gval, l_int32 bval )

  pixRenderHashBoxaArb()

      Input:  pix
              boxa
              spacing (spacing between lines; must be > 1)
              width  (thickness of box and hash lines)
              orient  (orientation of lines: L_HORIZONTAL_LINE, ...)
              outline  (0 to skip drawing box outline)
              rval, gval, bval
      Return: 0 if OK, 1 on error

=head2 pixRenderHashBoxaBlend

l_int32 pixRenderHashBoxaBlend ( PIX *pix, BOXA *boxa, l_int32 spacing, l_int32 width, l_int32 orient, l_int32 outline, l_int32 rval, l_int32 gval, l_int32 bval, l_float32 fract )

  pixRenderHashBoxaBlend()

      Input:  pix
              boxa
              spacing (spacing between lines; must be > 1)
              width  (thickness of box and hash lines)
              orient  (orientation of lines: L_HORIZONTAL_LINE, ...)
              outline  (0 to skip drawing box outline)
              rval, gval, bval
              fract (in [0.0 - 1.0]; complete transparency (no effect)
                     if 0.0; no transparency if 1.0)
      Return: 0 if OK, 1 on error

=head2 pixRenderLine

l_int32 pixRenderLine ( PIX *pix, l_int32 x1, l_int32 y1, l_int32 x2, l_int32 y2, l_int32 width, l_int32 op )

  pixRenderLine()

      Input:  pix
              x1, y1
              x2, y2
              width  (thickness of line)
              op  (one of L_SET_PIXELS, L_CLEAR_PIXELS, L_FLIP_PIXELS)
      Return: 0 if OK, 1 on error

=head2 pixRenderLineArb

l_int32 pixRenderLineArb ( PIX *pix, l_int32 x1, l_int32 y1, l_int32 x2, l_int32 y2, l_int32 width, l_uint8 rval, l_uint8 gval, l_uint8 bval )

  pixRenderLineArb()

      Input:  pix
              x1, y1
              x2, y2
              width  (thickness of line)
              rval, gval, bval
      Return: 0 if OK, 1 on error

=head2 pixRenderLineBlend

l_int32 pixRenderLineBlend ( PIX *pix, l_int32 x1, l_int32 y1, l_int32 x2, l_int32 y2, l_int32 width, l_uint8 rval, l_uint8 gval, l_uint8 bval, l_float32 fract )

  pixRenderLineBlend()

      Input:  pix
              x1, y1
              x2, y2
              width  (thickness of line)
              rval, gval, bval
              fract
      Return: 0 if OK, 1 on error

=head2 pixRenderPolygon

PIX * pixRenderPolygon ( PTA *ptas, l_int32 width, l_int32 *pxmin, l_int32 *pymin )

  pixRenderPolygon()

      Input:  ptas (of vertices, none repeated)
              width (of polygon outline)
              &xmin (<optional return> min x value of input pts)
              &ymin (<optional return> min y value of input pts)
      Return: pix (1 bpp, with outline generated), or null on error

  Notes:
      (1) The pix is the minimum size required to contain the origin
          and the polygon.  For example, the max x value of the input
          points is w - 1, where w is the pix width.
      (2) The rendered line is 4-connected, so that an interior or
          exterior 8-c.c. flood fill operation works properly.

=head2 pixRenderPolyline

l_int32 pixRenderPolyline ( PIX *pix, PTA *ptas, l_int32 width, l_int32 op, l_int32 closeflag )

  pixRenderPolyline()

      Input:  pix
              ptas
              width  (thickness of line)
              op  (one of L_SET_PIXELS, L_CLEAR_PIXELS, L_FLIP_PIXELS)
              closeflag (1 to close the contour; 0 otherwise)
      Return: 0 if OK, 1 on error

  Note: this renders a closed contour.

=head2 pixRenderPolylineArb

l_int32 pixRenderPolylineArb ( PIX *pix, PTA *ptas, l_int32 width, l_uint8 rval, l_uint8 gval, l_uint8 bval, l_int32 closeflag )

  pixRenderPolylineArb()

      Input:  pix
              ptas
              width  (thickness of line)
              rval, gval, bval
              closeflag (1 to close the contour; 0 otherwise)
      Return: 0 if OK, 1 on error

  Note: this renders a closed contour.

=head2 pixRenderPolylineBlend

l_int32 pixRenderPolylineBlend ( PIX *pix, PTA *ptas, l_int32 width, l_uint8 rval, l_uint8 gval, l_uint8 bval, l_float32 fract, l_int32 closeflag, l_int32 removedups )

  pixRenderPolylineBlend()

      Input:  pix
              ptas
              width  (thickness of line)
              rval, gval, bval
              fract (in [0.0 - 1.0]; complete transparency (no effect)
                     if 0.0; no transparency if 1.0)
              closeflag (1 to close the contour; 0 otherwise)
              removedups  (1 to remove; 0 otherwise)
      Return: 0 if OK, 1 on error

=head2 pixRenderPta

l_int32 pixRenderPta ( PIX *pix, PTA *pta, l_int32 op )

  pixRenderPta()

      Input:  pix
              pta (arbitrary set of points)
              op   (one of L_SET_PIXELS, L_CLEAR_PIXELS, L_FLIP_PIXELS)
      Return: 0 if OK, 1 on error

  Notes:
      (1) L_SET_PIXELS puts all image bits in each pixel to 1
          (black for 1 bpp; white for depth > 1)
      (2) L_CLEAR_PIXELS puts all image bits in each pixel to 0
          (white for 1 bpp; black for depth > 1)
      (3) L_FLIP_PIXELS reverses all image bits in each pixel
      (4) This function clips the rendering to the pix.  It performs
          clipping for functions such as pixRenderLine(),
          pixRenderBox() and pixRenderBoxa(), that call pixRenderPta().

=head2 pixRenderPtaArb

l_int32 pixRenderPtaArb ( PIX *pix, PTA *pta, l_uint8 rval, l_uint8 gval, l_uint8 bval )

  pixRenderPtaArb()

      Input:  pix (any depth, cmapped ok)
              pta (arbitrary set of points)
              rval, gval, bval
      Return: 0 if OK, 1 on error

  Notes:
      (1) If pix is colormapped, render this color (or the nearest
          color if the cmap is full) on each pixel.
      (2) If pix is not colormapped, do the best job you can using
          the input colors:
          - d = 1: set the pixels
          - d = 2, 4, 8: average the input rgb value
          - d = 32: use the input rgb value
      (3) This function clips the rendering to the pix.

=head2 pixRenderPtaBlend

l_int32 pixRenderPtaBlend ( PIX *pix, PTA *pta, l_uint8 rval, l_uint8 gval, l_uint8 bval, l_float32 fract )

  pixRenderPtaBlend()

      Input:  pix (32 bpp rgb)
              pta  (arbitrary set of points)
              rval, gval, bval
      Return: 0 if OK, 1 on error

  Notes:
      (1) This function clips the rendering to the pix.

=head2 pixRenderRandomCmapPtaa

PIX * pixRenderRandomCmapPtaa ( PIX *pix, PTAA *ptaa, l_int32 polyflag, l_int32 width, l_int32 closeflag )

  pixRenderRandomCmapPtaa()

      Input:  pix (1, 2, 4, 8, 16, 32 bpp)
              ptaa
              polyflag (1 to interpret each Pta as a polyline; 0 to simply
                        render the Pta as a set of pixels)
              width  (thickness of line; use only for polyline)
              closeflag (1 to close the contour; 0 otherwise;
                         use only for polyline mode)
      Return: pixd (cmapped, 8 bpp) or null on error

  Notes:
      (1) This is a debugging routine, that displays a set of
          pixels, selected by the set of Ptas in a Ptaa,
          in a random color in a pix.
      (2) If @polyflag == 1, each Pta is considered to be a polyline,
          and is rendered using @width and @closeflag.  Each polyline
          is rendered in a random color.
      (3) If @polyflag == 0, all points in each Pta are rendered in a
          random color.  The @width and @closeflag parameters are ignored.
      (4) The output pix is 8 bpp and colormapped.  Up to 254
          different, randomly selected colors, can be used.
      (5) The rendered pixels replace the input pixels.  They will
          be clipped silently to the input pix.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
