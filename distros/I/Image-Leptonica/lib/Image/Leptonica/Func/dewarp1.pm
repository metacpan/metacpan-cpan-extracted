package Image::Leptonica::Func::dewarp1;
$Image::Leptonica::Func::dewarp1::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::dewarp1

=head1 VERSION

version 0.04

=head1 C<dewarp1.c>

  dewarp1.c

    Basic operations and serialization

      Create/destroy dewarp
          L_DEWARP          *dewarpCreate()
          L_DEWARP          *dewarpCreateRef()
          void               dewarpDestroy()

      Create/destroy dewarpa
          L_DEWARPA         *dewarpaCreate()
          L_DEWARPA         *dewarpaCreateFromPixacomp()
          void               dewarpaDestroy()
          l_int32            dewarpaDestroyDewarp()

      Dewarpa insertion/extraction
          l_int32            dewarpaInsertDewarp()
          static l_int32     dewarpaExtendArraysToSize()
          L_DEWARP          *dewarpaGetDewarp()

      Setting parameters to control rendering from the model
          l_int32            dewarpaSetCurvatures()
          l_int32            dewarpaUseBothArrays()
          l_int32            dewarpaSetMaxDistance()

      Dewarp serialized I/O
          L_DEWARP          *dewarpRead()
          L_DEWARP          *dewarpReadStream()
          l_int32            dewarpWrite()
          l_int32            dewarpWriteStream()

      Dewarpa serialized I/O
          L_DEWARPA         *dewarpaRead()
          L_DEWARPA         *dewarpaReadStream()
          l_int32            dewarpaWrite()
          l_int32            dewarpaWriteStream()


  Examples of usage
  =================

  See dewarpaCreateFromPixacomp() for an example of the basic
  operations, starting from a set of 1 bpp images.

  Basic functioning to dewarp a specific single page:
     // Make the Dewarpa for the pages
     L_Dewarpa *dewa = dewarpaCreate(1, 30, 1, 15, 50);
     dewarpaSetCurvatures(dewa, -1, 5, -1, -1, -1);
     dewarpaUseBothArrays(dewa, 1);  // try to use both disparity
                                     // arrays for this example

     // Do the page: start with a binarized image
     Pix *pixb = "binarize"(pixs);
     // Initialize a Dewarp for this page (say, page 214)
     L_Dewarp *dew = dewarpCreate(pixb, 214);
     // Insert in Dewarpa and obtain parameters for building the model
     dewarpaInsertDewarp(dewa, dew);
     // Do the work
     dewarpBuildPageModel(dew, NULL);  // no debugging
     // Optionally set rendering parameters
     // Apply model to the input pixs
     Pix *pixd;
     dewarpaApplyDisparity(dewa, 214, pixs, 255, 0, 0, &pixd, NULL);
     pixDestroy(&pixb);

  Basic functioning to dewarp many pages:
     // Make the Dewarpa for the set of pages; use fullres 1 bpp
     L_Dewarpa *dewa = dewarpaCreate(10, 30, 1, 15, 50);
     // Optionally set rendering parameters
     dewarpaSetCurvatures(dewa, -1, 10, -1, -1, -1);
     dewarpaUseBothArrays(dewa, 0);  // just use the vertical disparity
                                     // array for this example

     // Do first page: start with a binarized image
     Pix *pixb = "binarize"(pixs);
     // Initialize a Dewarp for this page (say, page 1)
     L_Dewarp *dew = dewarpCreate(pixb, 1);
     // Insert in Dewarpa and obtain parameters for building the model
     dewarpaInsertDewarp(dewa, dew);
     // Do the work
     dewarpBuildPageModel(dew, NULL);  // no debugging
     dewarpMinimze(dew);  // remove most heap storage
     pixDestroy(&pixb);

     // Do the other pages the same way
     ...

     // Apply models to each page; if the page model is invalid,
     // try to use a valid neighboring model.  Note that the call
     // to dewarpaInsertRefModels() is optional, because it is called
     // by dewarpaApplyDisparity() on the first page it acts on.
     dewarpaInsertRefModels(dewa, 0, 1); // use debug flag to get more
                         // detailed information about the page models
     [For each page, where pixs is the fullres image to be dewarped] {
         L_Dewarp *dew = dewarpaGetDewarp(dewa, pageno);
         if (dew) {  // disparity model exists
             Pix *pixd;
             dewarpaApplyDisparity(dewa, pageno, pixs, 255,
                                   0, 0, &pixd, NULL);
             dewarpMinimize(dew);  // clean out the pix and fpix arrays
             // Squirrel pixd away somewhere ...)
         }
     }

  Basic functioning to dewarp a small set of pages, potentially
  using models from nearby pages:
     // (1) Generate a set of binarized images in the vicinity of the
     // pages to be dewarped.  We will attempt to compute models
     // for pages from 'firstpage' to 'lastpage'.
     // Store the binarized images in a compressed array of
     // size 'n', where 'n' is the number of images to be stored,
     // and where the offset is the first page.
     PixaComp *pixac = pixacompCreateInitialized(n, firstpage, NULL,
                                                 IFF_TIFF_G4);
     for (i = firstpage; i <= lastpage; i++) {
         Pix *pixb = "binarize"(pixs);
         pixacompReplacePix(pixac, i, pixb, IFF_TIFF_G4);
         pixDestroy(&pixb);
     }

     // (2) Make the Dewarpa for the pages.
     L_Dewarpa *dewa =
           dewarpaCreateFromPixacomp(pixac, 30, 15, 20);
     dewarpaUseBothArrays(dewa, 1);  // try to use both disparity arrays
                                     // in this example

     // (3) Finally, apply the models.  For page 'firstpage' with image pixs:
     L_Dewarp *dew = dewarpaGetDewarp(dewa, firstpage);
     if (dew) {  // disparity model exists
         Pix *pixd;
         dewarpaApplyDisparity(dewa, firstpage, pixs, 255, 0, 0, &pixd, NULL);
         dewarpMinimize(dew);
     }

  Because in general some pages will not have enough text to build a
  model, we fill in for those pages with a reference to the page
  model to use.  Both the target page and the reference page must
  have the same parity.  We can also choose to use either a partial model
  (with only vertical disparity) or the full model of a nearby page.

  Minimizing the data in a model by stripping out images,
  numas, and full resolution disparity arrays:
     dewarpMinimize(dew);
  This can be done at any time to save memory.  Serialization does
  not use the data that is stripped.

  You can apply any model (in a dew), stripped or not, to another image:
     // For all pages with invalid models, assign the nearest valid
     // page model with same parity.
     dewarpaInsertRefModels(dewa, 0, 0);
     // You can then apply to 'newpix' the page model that was assigned
     // to 'pageno', giving the result in pixd:
     Pix *pixd;
     dewarpaApplyDisparity(dewa, pageno, newpix, 255, 0, 0, &pixd, NULL);

  You can apply the disparity arrays to a deliberately undercropped
  image.  Suppose that you undercrop by (left, right, top, bot), so
  that the disparity arrays are aligned with their origin at (left, top).
  Dewarp the undercropped image with:
     Pix *pixd;
     dewarpaApplyDisparity(dewa, pageno, undercropped_pix, 255,
                           left, top, &pixd, NULL);


  Description of the approach to analyzing page image distortion
  ==============================================================

  When a book page is scanned, there are several possible causes
  for the text lines to appear to be curved:
   (1) A barrel (fish-eye) effect because the camera is at
       a finite distance from the page.  Take the normal from
       the camera to the page (the 'optic axis').  Lines on
       the page "below" this point will appear to curve upward
       (negative curvature); lines "above" this will curve downward.
   (2) Radial distortion from the camera lens.  Probably not
       a big factor.
   (3) Local curvature of the page in to (or out of) the image
       plane (which is perpendicular to the optic axis).
       This has no effect if the page is flat.

  In the following, the optic axis is in the z direction and is
  perpendicular to the xy plane;, the book is assumed to be aligned
  so that y is approximately along the binding.
  The goal is to compute the "disparity" field, D(x,y), which
  is actually a vector composed of the horizontal and vertical
  disparity fields H(x,y) and V(x,y).  Each of these is a local
  function that gives the amount each point in the image is
  required to move in order to rectify the horizontal and vertical
  lines.  It would also be nice to "flatten" the page to compensate
  for effect (3), foreshortening due to bending of the page into
  the z direction, but that is more difficult.

  Effects (1) and (2) can be directly compensated by calibrating
  the scene, using a flat page with horizontal and vertical lines.
  Then H(x,y) and V(x,y) can be found as two (non-parametric) arrays
  of values.  Suppose this has been done.  Then the remaining
  distortion is due to (3).

  We consider the simple situation where the page bending is independent
  of y, and is described by alpha(x), where alpha is the angle between
  the normal to the page and the optic axis.  cos(alpha(x)) is the local
  compression factor of the page image in the horizontal direction, at x.
  Thus, if we know alpha(x), we can compute the disparity H(x) required
  to flatten the image by simply integrating 1/cos(alpha), and we could
  compute the remaining disparities, H(x,y) and V(x,y), from the
  page content, as described below.  Unfortunately, we don't know
  alpha.  What do we know?  If there are horizontal text lines
  on the page, we can compute the vertical disparity, V(x,y), which
  is the local translation required to make the text lines parallel
  to the rasters.  If the margins are left and right aligned, we can
  also estimate the horizontal disparity, H(x,y), required to have
  uniform margins.  All that can be done from the image alone,
  assuming we have text lines covering a sufficient part of the page.

  What about alpha(x)?  The basic question relating to (3) is this:

     Is it possible, using the shape of the text lines alone,
     to compute both the vertical and horizontal disparity fields?

  The underlying problem is to separate the line curvature effects due
  to the camera view from those due to actual bending of the page.
  I believe the proper way to do this is to make some measurements
  based on the camera setup, which will depend mostly on the distance
  of the camera from the page, and to a smaller extent on the location
  of the optic axis with respect to the page.

  Here is the procedure.  Photograph a page with a fine 2D line grid
  several times, each with a different slope near the binding.
  This can be done by placing the grid page on books that have
  different shapes z(x) near the binding.  For each one you can
  measure, near the binding:
    (1) ds/dy, the vertical rate of change of slope of the horizontal lines
    (2) the local horizontal compression of the vertical lines due
        to the page angle dz/dx.
  As mentioned above, the local horizontal compression is simply
  cos(dz/dx).  But the measurement you can make on an actual book
  page is (1).  The difficulty is to generate (2) from (1).

  Back to the procedure.  The function in (1), ds/dy, likely needs
  to be measured at a few y locations, because the relation
  between (1) and (2) may weakly depend on the y-location with
  respect to the y-coordinate of the optic axis of the camera.
  From these measurements you can determine, for the camera setup
  that you have, the local horizontal compression, cos(dz/dx), as a
  function of the both vertical location (y) and your measured vertical
  derivative of the text line slope there, ds/dy.  Then with
  appropriate smoothing of your measured values, you can set up a
  horizontal disparity array to correct for the compression due
  to dz/dx.

  Now consider V(x,0) and V(x,h), the vertical disparity along
  the top and bottom of the image.  With a little thought you
  can convince yourself that the local foreshortening,
  as a function of x, is proportional to the difference
  between the slope of V(x,0) and V(x,h).  The horizontal
  disparity can then be computed by integrating the local foreshortening
  over x.  Integration of the slope of V(x,0) and V(x,h) gives
  the vertical disparity itself.  We have to normalize to h, the
  height of the page.  So the very simple result is that

      H(x) ~ (V(x,0) - V(x,h)) / h         [1]

  which is easily computed.  There is a proportionality constant
  that depends on the ratio of h to the distance to the camera.
  Can we actually believe this for the case where the bending
  is independent of y?  I believe the answer is yes,
  as long as you first remove the apparent distortion due
  to the camera being at a finite distance.

  If you know the intersection of the optical axis with the page
  and the distance to the camera, and if the page is perpendicular
  to the optic axis, you can compute the horizontal and vertical
  disparities due to (1) and (2) and remove them.  The resulting
  distortion should be entirely due to bending (3), for which
  the relation

      Hx(x) dx = C * ((Vx(x,0) - Vx(x, h))/h) dx         [2]

  holds for each point in x (Hx and Vx are partial derivatives w/rt x).
  Integrating over x, and using H(0) = 0, we get the result [1].

  I believe this result holds differentially for each value of y, so
  that in the case where the bending is not independent of y,
  the expression (V(x,0) - V(x,h)) / h goes over to Vy(x,y).  Then

     H(x,y) = Integral(0,x) (Vyx(x,y) dx)         [3]

  where Vyx() is the partial derivative of V w/rt both x and y.

  It would be nice if there were a simple mathematical relation between
  the horizontal and vertical disparities for the situation
  where the paper bends without stretching or kinking.
  I had hoped to get a relation between H and V, such as
  Hx(x,y) ~ Vy(x,y), which would imply that H and V are real
  and imaginary parts of a complex potential, each of which
  satisfy the laplace equation.  But then the gradients of the
  two potentials would be normal, and that does not appear to be the case.
  Thus, the questions of proving the relations above (for small bending),
  or finding a simpler relation between H and V than those equations,
  remain open.  So far, we have only used [1] for the horizontal
  disparity H(x).

  In the version of the code that follows, we first use text lines
  to find V(x,y).  Then, we try to compute H(x,y) that will align
  the text vertically on the left and right margins.  This is not
  always possible -- sometimes the right margin is not right justified.
  By default, we don't require the horizontal disparity to have a
  valid page model for dewarping a page, but this requirement can
  be forced using dewarpaUseFullModel().

  As described above, one can add a y-independent component of
  the horizontal disparity H(x) to counter the foreshortening
  effect due to the bending of the page near the binding.
  This requires widening the image on the side near the binding,
  and we do not provide this option here.  However, we do provide
  a function that will generate this disparity field:
       fpixExtraHorizDisparity()

  Here is the basic outline for building the disparity arrays.

  (1) Find lines going approximately through the center of the
      text in each text line.  Accept only lines that are
      close in length to the longest line.
  (2) Use these lines to generate a regular and highly subsampled
      vertical disparity field V(x,y).
  (3) Interpolate this to generate a full resolution vertical
      disparity field.
  (4) For lines that are sufficiently long, determine if the lines
      are left and right-justified, and if so, construct a highly
      subsampled horizontal disparity field H(x,y) that will bring
      them into alignment.
  (5) Interpolate this to generate a full resolution horizontal
      disparity field.
  (6) Apply the vertical dewarping, followed by the horizontal dewarping.

  Step (1) is clearly described by the code in pixGetTextlineCenters().

  Steps (2) and (3) follow directly from the data in step (1),
  and constitute the bulk of the work done in dewarpBuildPageModel().
  Virtually all the noise in the data is smoothed out by doing
  least-square quadratic fits, first horizontally to the data
  points representing the text line centers, and then vertically.
  The trick is to sample these lines on a regular grid.
  First each horizontal line is sampled at equally spaced
  intervals horizontally.  We thus get a set of points,
  one in each line, that are vertically aligned, and
  the data we represent is the vertical distance of each point
  from the min or max value on the curve, depending on the
  sign of the curvature component.  Each of these vertically
  aligned sets of points constitutes a sampled vertical disparity,
  and we do a LS quartic fit to each of them, followed by
  vertical sampling at regular intervals.  We now have a subsampled
  grid of points, all equally spaced, giving at each point the local
  vertical disparity.  Finally, the full resolution vertical disparity
  is formed by interpolation.  All the least square fits do a
  great job of smoothing everything out, as can be observed by
  the contour maps that are generated for the vertical disparity field.

=head1 FUNCTIONS

=head2 dewarpCreate

L_DEWARP * dewarpCreate ( PIX *pixs, l_int32 pageno )

  dewarpCreate()

     Input: pixs (1 bpp)
            pageno (page number)
     Return: dew (or null on error)

  Notes:
      (1) The input pixs is either full resolution or 2x reduced.
      (2) The page number is typically 0-based.  If scanned from a book,
          the even pages are usually on the left.  Disparity arrays
          built for even pages should only be applied to even pages.

=head2 dewarpCreateRef

L_DEWARP * dewarpCreateRef ( l_int32 pageno, l_int32 refpage )

  dewarpCreateRef()

     Input:  pageno (this page number)
             refpage (page number of dewarp disparity arrays to be used)
     Return: dew (or null on error)

  Notes:
      (1) This specifies which dewarp struct should be used for
          the given page.  It is placed in dewarpa for pages
          for which no model can be built.
      (2) This page and the reference page have the same parity and
          the reference page is the closest page with a disparity model
          to this page.

=head2 dewarpDestroy

void dewarpDestroy ( L_DEWARP **pdew )

  dewarpDestroy()

      Input:  &dew (<will be set to null before returning>)
      Return: void

=head2 dewarpRead

L_DEWARP * dewarpRead ( const char *filename )

  dewarpRead()

      Input:  filename
      Return: dew, or null on error

=head2 dewarpReadStream

L_DEWARP * dewarpReadStream ( FILE *fp )

  dewarpReadStream()

      Input:  stream
      Return: dew, or null on error

  Notes:
      (1) The dewarp struct is stored in minimized format, with only
          subsampled disparity arrays.
      (2) The sampling and extra horizontal disparity parameters are
          stored here.  During generation of the dewarp struct, they
          are passed in from the dewarpa.  In readback, it is assumed
          that they are (a) the same for each page and (b) the same
          as the values used to create the dewarpa.

=head2 dewarpWrite

l_int32 dewarpWrite ( const char *filename, L_DEWARP *dew )

  dewarpWrite()

      Input:  filename
              dew
      Return: 0 if OK, 1 on error

=head2 dewarpWriteStream

l_int32 dewarpWriteStream ( FILE *fp, L_DEWARP *dew )

  dewarpWriteStream()

      Input:  stream (opened for "wb")
              dew
      Return: 0 if OK, 1 on error

  Notes:
      (1) This should not be written if there is no sampled
          vertical disparity array, which means that no model has
          been built for this page.

=head2 dewarpaCreate

L_DEWARPA * dewarpaCreate ( l_int32 nptrs, l_int32 sampling, l_int32 redfactor, l_int32 minlines, l_int32 maxdist )

  dewarpaCreate()

     Input: nptrs (number of dewarp page ptrs; typically the number of pages)
            sampling (use 0 for default value; the minimum allowed is 8)
            redfactor (of input images: 1 is full resolution; 2 is 2x reduced)
            minlines (minimum number of lines to accept; use 0 for default)
            maxdist (for locating reference disparity; use -1 for default)
     Return: dewa (or null on error)

  Notes:
      (1) The sampling, minlines and maxdist parameters will be
          applied to all images.
      (2) The sampling factor is used for generating the disparity arrays
          from the input image.  For 2x reduced input, use a sampling
          factor that is half the sampling you want on the full resolution
          images.
      (3) Use @redfactor = 1 for full resolution; 2 for 2x reduction.
          All input images must be at one of these two resolutions.
      (4) @minlines is the minimum number of nearly full-length lines
          required to generate a vertical disparity array.  The default
          number is 15.  Use a smaller number to accept a questionable
          array, but not smaller than 4.
      (5) When a model can't be built for a page, it looks up to @maxdist
          in either direction for a valid model with the same page parity.
          Use -1 for the default value of @maxdist; use 0 to avoid using
          a ref model.
      (6) The ptr array is expanded as necessary to accommodate page images.

=head2 dewarpaCreateFromPixacomp

L_DEWARPA * dewarpaCreateFromPixacomp ( PIXAC *pixac, l_int32 useboth, l_int32 sampling, l_int32 minlines, l_int32 maxdist )

  dewarpaCreateFromPixacomp()

     Input: pixac (pixacomp of G4, 1 bpp images; with 1x1x1 placeholders)
            useboth (0 for vert disparity; 1 for both vert and horiz)
            sampling (use -1 or 0 for default value; otherwise minimum of 5)
            minlines (minimum number of lines to accept; e.g., 10)
            maxdist (for locating reference disparity; use -1 for default)
     Return: dewa (or null on error)

  Notes:
      (1) The returned dewa has disparity arrays calculated and
          is ready for serialization or for use in dewarping.
      (2) The sampling, minlines and maxdist parameters are
          applied to all images.  See notes in dewarpaCreate() for details.
      (3) The pixac is full.  Placeholders, if any, are w=h=d=1 images,
          and the real input images are 1 bpp at full resolution.
          They are assumed to be cropped to the actual page regions,
          and may be arbitrarily sparse in the array.
      (4) The output dewarpa is indexed by the page number.
          The offset in the pixac gives the mapping between the
          array index in the pixac and the page number.
      (5) This adds the ref page models.
      (6) This can be used to make models for any desired set of pages.
          The direct models are only made for pages with images in
          the pixacomp; the ref models are made for pages of the
          same parity within @maxdist of the nearest direct model.

=head2 dewarpaDestroy

void dewarpaDestroy ( L_DEWARPA **pdewa )

  dewarpaDestroy()

      Input:  &dewa (<will be set to null before returning>)
      Return: void

=head2 dewarpaDestroyDewarp

l_int32 dewarpaDestroyDewarp ( L_DEWARPA *dewa, l_int32 pageno )

  dewarpaDestroyDewarp()

      Input:  dewa
              pageno (of dew to be destroyed)
      Return: 0 if OK, 1 on error

=head2 dewarpaGetDewarp

L_DEWARP * dewarpaGetDewarp ( L_DEWARPA *dewa, l_int32 index )

  dewarpaGetDewarp()

      Input:  dewa (populated with dewarp structs for pages)
              index (into dewa: this is the pageno)
      Return: dew (handle; still owned by dewa), or null on error

=head2 dewarpaInsertDewarp

l_int32 dewarpaInsertDewarp ( L_DEWARPA *dewa, L_DEWARP *dew )

  dewarpaInsertDewarp()

      Input:  dewarpa
              dewarp  (to be added)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This inserts the dewarp into the array, which now owns it.
          It also keeps track of the largest page number stored.
          It must be done before the disparity model is built.
      (2) Note that this differs from the usual method of filling out
          arrays in leptonica, where the arrays are compact and
          new elements are typically added to the end.  Here,
          the dewarp can be added anywhere, even beyond the initial
          allocation.

=head2 dewarpaRead

L_DEWARPA * dewarpaRead ( const char *filename )

  dewarpaRead()

      Input:  filename
      Return: dewa, or null on error

=head2 dewarpaReadStream

L_DEWARPA * dewarpaReadStream ( FILE *fp )

  dewarpaReadStream()

      Input:  stream
      Return: dewa, or null on error

  Notes:
      (1) The serialized dewarp contains a Numa that gives the
          (increasing) page number of the dewarp structs that are
          contained.
      (2) Reference pages are added in after readback.

=head2 dewarpaSetCurvatures

l_int32 dewarpaSetCurvatures ( L_DEWARPA *dewa, l_int32 max_linecurv, l_int32 min_diff_linecurv, l_int32 max_diff_linecurv, l_int32 max_edgecurv, l_int32 max_diff_edgecurv )

  dewarpaSetCurvatures()

      Input:  dewa
              max_linecurv (-1 for default)
              min_diff_linecurv (-1 for default; 0 to accept all models)
              max_diff_linecurv (-1 for default)
              max_edgecurv (-1 for default)
              max_diff_edgecurv (-1 for default)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Approximating the line by a quadratic, the coefficent
          of the quadratic term is the curvature, and distance
          units are in pixels (of course).  The curvature is very
          small, so we multiply by 10^6 and express the constraints
          on the model curvatures in micro-units.
      (2) This sets five curvature thresholds:
          * the maximum absolute value of the vertical disparity
            line curvatures
          * the minimum absolute value of the largest difference in
            vertical disparity line curvatures (Use a value of 0
            to accept all models.)
          * the maximum absolute value of the largest difference in
            vertical disparity line curvatures
          * the maximum absolute value of the left and right edge
            curvature for the horizontal disparity
          * the maximum absolute value of the difference between
            left and right edge curvature for the horizontal disparity
          all in micro-units, for dewarping to take place.
          Use -1 for default values.
      (3) An image with a line curvature less than about 0.00001
          has fairly straight textlines.  This is 10 micro-units.
      (4) For example, if @max_linecurv == 100, this would prevent dewarping
          if any of the lines has a curvature exceeding 100 micro-units.
          A model having maximum line curvature larger than about 150
          micro-units should probably not be used.
      (5) A model having a left or right edge curvature larger than
          about 100 micro-units should probably not be used.

=head2 dewarpaSetMaxDistance

l_int32 dewarpaSetMaxDistance ( L_DEWARPA *dewa, l_int32 maxdist )

  dewarpaSetMaxDistance()

      Input:  dewa
              maxdist (for using ref models)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This sets the maxdist field.

=head2 dewarpaUseBothArrays

l_int32 dewarpaUseBothArrays ( L_DEWARPA *dewa, l_int32 useboth )

  dewarpaUseBothArrays()

      Input:  dewa
              useboth (0 for false, 1 for true)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This sets the useboth field.  If set, this will attempt
          to apply both vertical and horizontal disparity arrays.
          Note that a model with only a vertical disparity array will
          always be valid.

=head2 dewarpaWrite

l_int32 dewarpaWrite ( const char *filename, L_DEWARPA *dewa )

  dewarpaWrite()

      Input:  filename
              dewa
      Return: 0 if OK, 1 on error

=head2 dewarpaWriteStream

l_int32 dewarpaWriteStream ( FILE *fp, L_DEWARPA *dewa )

  dewarpaWriteStream()

      Input:  stream (opened for "wb")
              dewa
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
