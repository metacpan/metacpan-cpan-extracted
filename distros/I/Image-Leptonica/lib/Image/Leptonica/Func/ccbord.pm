package Image::Leptonica::Func::ccbord;
$Image::Leptonica::Func::ccbord::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::ccbord

=head1 VERSION

version 0.04

=head1 C<ccbord.c>

  ccbord.c

     CCBORDA and CCBORD creation and destruction
         CCBORDA     *ccbaCreate()
         void        *ccbaDestroy()
         CCBORD      *ccbCreate()
         void        *ccbDestroy()

     CCBORDA addition
         l_int32      ccbaAddCcb()
         static l_int32  ccbaExtendArray()

     CCBORDA accessors
         l_int32      ccbaGetCount()
         l_int32      ccbaGetCcb()

     Top-level border-finding routines
         CCBORDA     *pixGetAllCCBorders()
         CCBORD      *pixGetCCBorders()
         PTAA        *pixGetOuterBordersPtaa()
         PTA         *pixGetOuterBorderPta()

     Lower-level border location routines
         l_int32      pixGetOuterBorder()
         l_int32      pixGetHoleBorder()
         l_int32      findNextBorderPixel()
         void         locateOutsideSeedPixel()

     Border conversions
         l_int32      ccbaGenerateGlobalLocs()
         l_int32      ccbaGenerateStepChains()
         l_int32      ccbaStepChainsToPixCoords()
         l_int32      ccbaGenerateSPGlobalLocs()

     Conversion to single path
         l_int32      ccbaGenerateSinglePath()
         PTA         *getCutPathForHole()

     Border and full image rendering
         PIX         *ccbaDisplayBorder()
         PIX         *ccbaDisplaySPBorder()
         PIX         *ccbaDisplayImage1()
         PIX         *ccbaDisplayImage2()

     Serialize for I/O
         l_int32      ccbaWrite()
         l_int32      ccbaWriteStream()
         l_int32      ccbaRead()
         l_int32      ccbaReadStream()

     SVG output
         l_int32      ccbaWriteSVG()
         char        *ccbaWriteSVGString()


     Border finding is tricky because components can have
     holes, which also need to be traced out.  The outer
     border can be connected with all the hole borders,
     so that there is a single border for each component.
     [Alternatively, the connecting paths can be eliminated if
     you're willing to have a set of borders for each
     component (an exterior border and some number of
     interior ones), with "line to" operations tracing
     out each border and "move to" operations going from
     one border to the next.]

     Here's the plan.  We get the pix for each connected
     component, and trace its exterior border.  We then
     find the holes (if any) in the pix, and separately
     trace out their borders, all using the same
     border-following rule that has ON pixels on the right
     side of the path.

     [For svg, we may want to turn each set of borders for a c.c.
     into a closed path.  This can be done by tunnelling
     through the component from the outer border to each of the
     holes, going in and coming out along the same path so
     the connection will be invisible in any rendering
     (display or print) from the outline.  The result is a
     closed path, where the outside border is traversed
     cw and each hole is traversed ccw.  The svg renderer
     is assumed to handle these closed borders properly.]

     Each border is a closed path that is traversed in such
     a way that the stuff inside the c.c. is on the right
     side of the traveller.  The border of a singly-connected
     component is thus traversed cw, and the border of the
     holes inside a c.c. are traversed ccw.  Suppose we have
     a list of all the borders of each c.c., both the cw and ccw
     traversals.  How do we reconstruct the image?

   Reconstruction:

     Method 1.  Topological method using connected components.
     We have closed borders composed of cw border pixels for the
     exterior of c.c. and ccw border pixels for the interior (holes)
     in the c.c.
         (a) Initialize the destination to be OFF.  Then,
             in any order:
         (b) Fill the components within and including the cw borders,
             and sequentially XOR them onto the destination.
         (c) Fill the components within but not including the ccw
             borders and sequentially XOR them onto the destination.
     The components that are XOR'd together can be generated as follows:
         (a) For each closed cw path, use pixFillClosedBorders():
               (1) Turn on the path pixels in a subimage that
                   minimally supports the border.
               (2) Do a 4-connected fill from a seed of 1 pixel width
                   on the border, using the inverted image in (1) as
                   a filling mask.
               (3) Invert the fill result: this gives the component
                   including the exterior cw path, with all holes
                   filled.
         (b) For each closed ccw path (hole):
               (1) Turn on the path pixels in a subimage that minimally
                   supports the path.
               (2) Find a seed pixel on the inside of this path.
               (3) Do a 4-connected fill from this seed pixel, using
                   the inverted image of the path in (1) as a filling
                   mask.

     ------------------------------------------------------

     Method 2.  A variant of Method 1.  Topological.
     In Method 1, we treat the exterior border differently from
     the interior (hole) borders.  Here, all borders in a c.c.
     are treated equally:
         (1) Start with a pix with a 1 pixel OFF boundary
             enclosing all the border pixels of the c.c.
             This is the filling mask.
         (2) Make a seed image of the same size as follows:  for
             each border, put one seed pixel OUTSIDE the border
             (where OUTSIDE is determined by the inside/outside
             convention for borders).
         (3) Seedfill into the seed image, filling in the regions
             determined by the filling mask.  The fills are clipped
             by the border pixels.
         (4) Inverting this, we get the c.c. properly filled,
             with the holes empty!
         (5) Rasterop using XOR the filled c.c. (but not the 1
             pixel boundary) into the full dest image.

     Method 2 is about 1.2x faster than Method 1 on text images,
     and about 2x faster on complex images (e.g., with halftones).

     ------------------------------------------------------

     Method 3.  The traditional way to fill components delineated
     by boundaries is through scan line conversion.  It's a bit
     tricky, and I have not yet tried to implement it.

     ------------------------------------------------------

     Method 4.  [Nota Bene: this method probably doesn't work, and
     won't be implemented.  If I get a more traditional scan line
     conversion algorithm working, I'll erase these notes.]
     Render all border pixels on a destination image,
     which will be the final result after scan conversion.  Assign
     a value 1 to pixels on cw paths, 2 to pixels on ccw paths,
     and 3 to pixels that are on both paths.  Each of the paths
     is an 8-connected component.  Now scan across each raster
     line.  The attempt is to make rules for each scan line
     that are independent of neighboring scanlines.  Here are
     a set of rules for writing ON pixels on a destination raster image:

         (a) The rasterizer will be in one of two states: ON and OFF.
         (b) Start each line in the OFF state.  In the OFF state,
             skip pixels until you hit a path of any type.  Turn
             the path pixel ON.
         (c) If the state is ON, each pixel you encounter will
             be turned on, until and including hitting a path pixel.
         (d) When you hit a path pixel, if the path does NOT cut
             through the line, so that there is not an 8-cc path
             pixel (of any type) both above and below, the state
             is unchanged (it stays either ON or OFF).
         (e) If the path does cut through, but with a possible change
             of pixel type, then we decide whether or
             not to toggle the state based on the values of the
             path pixel and the path pixels above and below:
               (1) if a 1 path cuts through, toggle;
               (1) if a 2 path cuts through, toggle;
               (3) if a 3 path cuts through, do not toggle;
               (4) if on one side a 3 touches both a 1 and a 2, use the 2
               (5) if a 3 has any 1 neighbors, toggle; else if it has
                   no 1 neighbors, do not toggle;
               (6) if a 2 has any neighbors that are 1 or 3,
                   do not toggle
               (7) if a 1 has neighbors 1 and x (x = 2 or 3),
                   toggle


     To visualize how these rules work, consider the following
     component with border pixels labeled according to the scheme
     above.  We also show the values of the interior pixels
     (w=OFF, b=ON), but these of course must be inferred properly
     from the rules above:

                     3
                  3  w  3             1  1  1
                  1  2  1          1  b  2  b  1
                  1  b  1             3  w  2  1
                  3  b  1          1  b  2  b  1
               3  w  3                1  1  1
               3  w  3
            1  b  2  b  1
            1  2  w  2  1
         1  b  2  w  2  b  1
            1  2  w  2  1
               1  2  b  1
               1  b  1
                  1


     Even if this works, which is unlikely, it will certainly be
     slow because decisions have to be made on a pixel-by-pixel
     basis when encountering borders.

=head1 FUNCTIONS

=head2 ccbCreate

CCBORD * ccbCreate ( PIX *pixs )

  ccbCreate()

     Input:  pixs  (<optional>)
     Return: ccb or null on error

=head2 ccbDestroy

void ccbDestroy ( CCBORD **pccb )

  ccbDestroy()

     Input:  &ccb (<to be nulled>)
     Return: void

=head2 ccbaAddCcb

l_int32 ccbaAddCcb ( CCBORDA *ccba, CCBORD *ccb )

  ccbaAddCcb()

      Input:  ccba
              ccb (to be added by insertion)
      Return: 0 if OK; 1 on error

=head2 ccbaCreate

CCBORDA * ccbaCreate ( PIX *pixs, l_int32 n )

   ccbaCreate()

       Input:  pixs  (binary image; can be null)
               n  (initial number of ptrs)
       Return: ccba, or null on error

=head2 ccbaDestroy

void ccbaDestroy ( CCBORDA **pccba )

  ccbaDestroy()

     Input:  &ccba  (<to be nulled>)
     Return: void

=head2 ccbaDisplayBorder

PIX * ccbaDisplayBorder ( CCBORDA *ccba )

  ccbaDisplayBorder()

      Input:  ccba
      Return: pix of border pixels, or null on error

  Notes:
      (1) Uses global ptaa, which gives each border pixel in
          global coordinates, and must be computed in advance
          by calling ccbaGenerateGlobalLocs().

=head2 ccbaDisplayImage1

PIX * ccbaDisplayImage1 ( CCBORDA *ccba )

  ccbaDisplayImage1()

      Input:  ccborda
      Return: pix of image, or null on error

  Notes:
      (1) Uses local ptaa, which gives each border pixel in
          local coordinates, so the actual pixel positions must
          be computed using all offsets.
      (2) For the holes, use coordinates relative to the c.c.
      (3) This is slower than Method 2.
      (4) This uses topological properties (Method 1) to do scan
          conversion to raster

  This algorithm deserves some commentary.

  I first tried the following:
    - outer borders: 4-fill from outside, stopping at the
         border, using pixFillClosedBorders()
    - inner borders: 4-fill from outside, stopping again
         at the border, XOR with the border, and invert
         to get the hole.  This did not work, because if
         you have a hole border that looks like:

                x x x x x x
                x          x
                x   x x x   x
                  x x o x   x
                      x     x
                      x     x
                        x x x

         if you 4-fill from the outside, the pixel 'o' will
         not be filled!  XORing with the border leaves it OFF.
         Inverting then gives a single bad ON pixel that is not
         actually part of the hole.

  So what you must do instead is 4-fill the holes from inside.
  You can do this from a seedfill, using a pix with the hole
  border as the filling mask.  But you need to start with a
  pixel inside the hole.  How is this determined?  The best
  way is from the contour.  We have a right-hand shoulder
  rule for inside (i.e., the filled region).   Take the
  first 2 pixels of the hole border, and compute dx and dy
  (second coord minus first coord:  dx = sx - fx, dy = sy - fy).
  There are 8 possibilities, depending on the values of dx and
  dy (which can each be -1, 0, and +1, but not both 0).
  These 8 cases can be broken into 4; see the simple algorithm below.
  Once you have an interior seed pixel, you fill from the seed,
  clipping with the hole border pix by filling into its invert.

  You then successively XOR these interior filled components, in any order.

=head2 ccbaDisplayImage2

PIX * ccbaDisplayImage2 ( CCBORDA *ccba )

  ccbaDisplayImage2()

      Input: ccborda
      Return: pix of image, or null on error

  Notes:
      (1) Uses local chain ptaa, which gives each border pixel in
          local coordinates, so the actual pixel positions must
          be computed using all offsets.
      (2) Treats exterior and hole borders on equivalent
          footing, and does all calculations on a pix
          that spans the c.c. with a 1 pixel added boundary.
      (3) This uses topological properties (Method 2) to do scan
          conversion to raster
      (4) The algorithm is described at the top of this file (Method 2).
          It is preferred to Method 1 because it is between 1.2x and 2x
          faster than Method 1.

=head2 ccbaDisplaySPBorder

PIX * ccbaDisplaySPBorder ( CCBORDA *ccba )

  ccbaDisplaySPBorder()

      Input:  ccba
      Return: pix of border pixels, or null on error

  Notes:
      (1) Uses spglobal pta, which gives each border pixel in
          global coordinates, one path per c.c., and must
          be computed in advance by calling ccbaGenerateSPGlobalLocs().

=head2 ccbaGenerateGlobalLocs

l_int32 ccbaGenerateGlobalLocs ( CCBORDA *ccba )

  ccbaGenerateGlobalLocs()

      Input:  ccba (with local chain ptaa of borders computed)
      Return: 0 if OK, 1 on error

  Action: this uses the pixel locs in the local ptaa, which are all
          relative to each c.c., to find the global pixel locations,
          and stores them in the global ptaa.

=head2 ccbaGenerateSPGlobalLocs

l_int32 ccbaGenerateSPGlobalLocs ( CCBORDA *ccba, l_int32 ptsflag )

  ccbaGenerateSPGlobalLocs()

      Input:  ccba
              ptsflag  (CCB_SAVE_ALL_PTS or CCB_SAVE_TURNING_PTS)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This calculates the splocal rep if not yet made.
      (2) It uses the local pixel values in splocal, the single
          path pta, which are all relative to each c.c., to find
          the corresponding global pixel locations, and stores
          them in the spglobal pta.
      (3) This lists only the turning points: it both makes a
          valid svg file and is typically about half the size
          when all border points are listed.

=head2 ccbaGenerateSinglePath

l_int32 ccbaGenerateSinglePath ( CCBORDA *ccba )

  ccbaGenerateSinglePath()

      Input:  ccba
      Return: 0 if OK, 1 on error

  Notes:
      (1) Generates a single border in local pixel coordinates.
          For each c.c., if there is just an outer border, copy it.
          If there are also hole borders, for each hole border,
          determine the smallest horizontal or vertical
          distance from the border to the outside of the c.c.,
          and find a path through the c.c. for this cut.
          We do this in a way that guarantees a pixel from the
          hole border is the starting point of the path, and
          we must verify that the path intersects the outer
          border (if it intersects it, then it ends on it).
          One can imagine pathological cases, but they may not
          occur in images of text characters and un-textured
          line graphics.
      (2) Once it is verified that the path through the c.c.
          intersects both the hole and outer borders, we
          generate the full single path for all borders in the
          c.c.  Starting at the start point on the outer
          border, when we hit a line on a cut, we take
          the cut, do the hold border, and return on the cut
          to the outer border.  We compose a pta of the
          outer border pts that are on cut paths, and for
          every point on the outer border (as we go around),
          we check against this pta.  When we find a matching
          point in the pta, we do its cut path and hole border.
          The single path is saved in the ccb.

=head2 ccbaGenerateStepChains

l_int32 ccbaGenerateStepChains ( CCBORDA *ccba )

  ccbaGenerateStepChains()

      Input:  ccba (with local chain ptaa of borders computed)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This uses the pixel locs in the local ptaa,
          which are all relative to each c.c., to find
          the step directions for successive pixels in
          the chain, and stores them in the step numaa.
      (2) To get the step direction, use
              1   2   3
              0   P   4
              7   6   5
          where P is the previous pixel at (px, py).  The step direction
          is the number (from 0 through 7) for each relative location
          of the current pixel at (cx, cy).  It is easily found by
          indexing into a 2-d 3x3 array (dirtab).

=head2 ccbaGetCcb

CCBORD * ccbaGetCcb ( CCBORDA *ccba, l_int32 index )

  ccbaGetCcb()

     Input:  ccba
     Return: ccb, or null on error

=head2 ccbaGetCount

l_int32 ccbaGetCount ( CCBORDA *ccba )

  ccbaGetCount()

     Input:  ccba
     Return: count, with 0 on error

=head2 ccbaRead

CCBORDA * ccbaRead ( const char *filename )

  ccbaRead()

      Input:  filename
      Return: ccba, or null on error

=head2 ccbaReadStream

CCBORDA * ccbaReadStream ( FILE *fp )

  ccbaReadStream()

      Input:   stream
      Return:  ccba, or null on error

  Format:  ccba: %7d cc\n (num. c.c.) (ascii)   (17B)
           pix width (4B)
           pix height (4B)
           [for i = 1, ncc]
               ulx  (4B)
               uly  (4B)
               w    (4B)       -- not req'd for reconstruction
               h    (4B)       -- not req'd for reconstruction
               number of borders (4B)
               [for j = 1, nb]
                   startx  (4B)
                   starty  (4B)
                   [for k = 1, nb]
                        2 steps (1B)
                   end in z8 or 88  (1B)

=head2 ccbaStepChainsToPixCoords

l_int32 ccbaStepChainsToPixCoords ( CCBORDA *ccba, l_int32 coordtype )

  ccbaStepChainsToPixCoords()

      Input:  ccba (with step chains numaa of borders)
              coordtype  (CCB_GLOBAL_COORDS or CCB_LOCAL_COORDS)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This uses the step chain data in each ccb to determine
          the pixel locations, either global or local,
          and stores them in the appropriate ptaa,
          either global or local.  For the latter, the
          pixel locations are relative to the c.c.

=head2 ccbaWrite

l_int32 ccbaWrite ( const char *filename, CCBORDA *ccba )

  ccbaWrite()

      Input:  filename
              ccba
      Return: 0 if OK, 1 on error

=head2 ccbaWriteSVG

l_int32 ccbaWriteSVG ( const char *filename, CCBORDA *ccba )

  ccbaWriteSVG()

      Input:  filename
              ccba
      Return: 0 if OK, 1 on error

=head2 ccbaWriteSVGString

char * ccbaWriteSVGString ( const char *filename, CCBORDA *ccba )

  ccbaWriteSVGString()

      Input:  filename
              ccba
      Return: string in svg-formatted, that can be written to file,
              or null on error.

=head2 ccbaWriteStream

l_int32 ccbaWriteStream ( FILE *fp, CCBORDA *ccba )

  ccbaWriteStream()

      Input:  stream
              ccba
      Return: 0 if OK; 1 on error

  Format:  ccba: %7d cc\n (num. c.c.) (ascii)   (18B)
           pix width (4B)
           pix height (4B)
           [for i = 1, ncc]
               ulx  (4B)
               uly  (4B)
               w    (4B)       -- not req'd for reconstruction
               h    (4B)       -- not req'd for reconstruction
               number of borders (4B)
               [for j = 1, nb]
                   startx  (4B)
                   starty  (4B)
                   [for k = 1, nb]
                        2 steps (1B)
                   end in z8 or 88  (1B)

=head2 findNextBorderPixel

l_int32 findNextBorderPixel ( l_int32 w, l_int32 h, l_uint32 *data, l_int32 wpl, l_int32 px, l_int32 py, l_int32 *pqpos, l_int32 *pnpx, l_int32 *pnpy )

  findNextBorderPixel()

      Input:  w, h, data, wpl
              (px, py),     (current P)
              &qpos (input current Q; <return> new Q)
              (&npx, &npy)    (<return> new P)
      Return: 0 if next pixel found; 1 otherwise

  Notes:
      (1) qpos increases clockwise from 0 to 7, with 0 at
          location with Q to left of P:   Q P
      (2) this is a low-level function that does not check input
          parameters.  All calling functions should check them.

=head2 getCutPathForHole

PTA * getCutPathForHole ( PIX *pix, PTA *pta, BOX *boxinner, l_int32 *pdir, l_int32 *plen )

  getCutPathForHole()

      Input:  pix  (of c.c.)
              pta  (of outer border)
              boxinner (b.b. of hole path)
              &dir  (direction (0-3), returned; only needed for debug)
              &len  (length of path, returned)
      Return: pta of pts on cut path from the hole border
              to the outer border, including end points on
              both borders; or null on error

  Notes:
      (1) If we don't find a path, we return a pta with no pts
          in it and len = 0.
      (2) The goal is to get a reasonably short path between the
          inner and outer borders, that goes entirely within the fg of
          the pix.  This function is cheap-and-dirty, may fail for some
          holes in complex topologies such as those you might find in a
          moderately dark scanned halftone.  If it fails to find a
          path to any particular hole, it gives a warning, and because
          that hole path is not included, the hole will not be rendered.

=head2 locateOutsideSeedPixel

void locateOutsideSeedPixel ( l_int32 fpx, l_int32 fpy, l_int32 spx, l_int32 spy, l_int32 *pxs, l_int32 *pys )

  locateOutsideSeedPixel()

      Input: fpx, fpy    (location of first pixel)
             spx, spy    (location of second pixel)
             &xs, &xy    (seed pixel to be returned)

  Notes:
      (1) the first and second pixels must be 8-adjacent,
          so |dx| <= 1 and |dy| <= 1 and both dx and dy
          cannot be 0.  There are 8 possible cases.
      (2) the seed pixel is OUTSIDE the foreground of the c.c.
      (3) these rules are for the situation where the INSIDE
          of the c.c. is on the right as you follow the border:
          cw for an exterior border and ccw for a hole border.

=head2 pixGetAllCCBorders

CCBORDA * pixGetAllCCBorders ( PIX *pixs )

  pixGetAllCCBorders()

      Input:  pixs (1 bpp)
      Return: ccborda, or null on error

=head2 pixGetCCBorders

CCBORD * pixGetCCBorders ( PIX *pixs, BOX *box )

  pixGetCCBorders()

      Input:  pixs (1 bpp, one 8-connected component)
              box  (xul, yul, width, height) in global coords
      Return: ccbord, or null on error

  Notes:
      (1) We are finding the exterior and interior borders
          of an 8-connected component.   This should be used
          on a pix that has exactly one 8-connected component.
      (2) Typically, pixs is a c.c. in some larger pix.  The
          input box gives its location in global coordinates.
          This box is saved, as well as the boxes for the
          borders of any holes within the c.c., but the latter
          are given in relative coords within the c.c.
      (3) The calculations for the exterior border are done
          on a pix with a 1-pixel
          added border, but the saved pixel coordinates
          are the correct (relative) ones for the input pix
          (without a 1-pixel border)
      (4) For the definition of the three tables -- xpostab[], ypostab[]
          and qpostab[] -- see above where they are defined.

=head2 pixGetHoleBorder

l_int32 pixGetHoleBorder ( CCBORD *ccb, PIX *pixs, BOX *box, l_int32 xs, l_int32 ys )

  pixGetHoleBorder()

      Input:  ccb  (the exterior border is already made)
              pixs (for the connected component at hand)
              box  (for the specific hole border, in relative
                    coordinates to the c.c.)
              xs, ys   (first pixel on hole border, relative to c.c.)
      Return: 0 if OK, 1 on error

  Notes:
      (1) we trace out hole border on pixs without addition
          of single pixel added border to pixs
      (2) therefore all coordinates are relative within the c.c. (pixs)
      (3) same position tables and stopping condition as for
          exterior borders

=head2 pixGetOuterBorder

l_int32 pixGetOuterBorder ( CCBORD *ccb, PIX *pixs, BOX *box )

  pixGetOuterBorder()

      Input:  ccb  (unfilled)
              pixs (for the component at hand)
              box  (for the component, in global coords)
      Return: 0 if OK, 1 on error

  Notes:
      (1) the border is saved in relative coordinates within
          the c.c. (pixs).  Because the calculation is done
          in pixb with added 1 pixel border, we must subtract
          1 from each pixel value before storing it.
      (2) the stopping condition is that after the first pixel is
          returned to, the next pixel is the second pixel.  Having
          these 2 pixels recur in sequence proves the path is closed,
          and we do not store the second pixel again.

=head2 pixGetOuterBorderPta

PTA * pixGetOuterBorderPta ( PIX *pixs, BOX *box )

  pixGetOuterBorderPta()

      Input:  pixs (1 bpp, one 8-connected component)
              box  (<optional> of pixs, in global coordinates)
      Return: pta (of outer border, in global coords), or null on error

  Notes:
      (1) We are finding the exterior border of a single 8-connected
          component.
      (2) If box is NULL, the outline returned is in the local coords
          of the input pix.  Otherwise, box is assumed to give the
          location of the pix in global coordinates, and the returned
          pta will be in those global coordinates.

=head2 pixGetOuterBordersPtaa

PTAA * pixGetOuterBordersPtaa ( PIX *pixs )

  pixGetOuterBordersPtaa()

      Input:  pixs (1 bpp)
      Return: ptaa (of outer borders, in global coords), or null on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
