package Image::Leptonica::Func::conncomp;
$Image::Leptonica::Func::conncomp::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::conncomp

=head1 VERSION

version 0.04

=head1 C<conncomp.c>

  conncomp.c

    Connected component counting and extraction, using Heckbert's
    stack-based filling algorithm.

      4- and 8-connected components: counts, bounding boxes and images

      Top-level calls:
           BOXA     *pixConnComp()
           BOXA     *pixConnCompPixa()
           BOXA     *pixConnCompBB()
           l_int32   pixCountConnComp()

      Identify the next c.c. to be erased:
           l_int32   nextOnPixelInRaster()
           l_int32   nextOnPixelInRasterLow()

      Erase the c.c., saving the b.b.:
           BOX      *pixSeedfillBB()
           BOX      *pixSeedfill4BB()
           BOX      *pixSeedfill8BB()

      Just erase the c.c.:
           l_int32   pixSeedfill()
           l_int32   pixSeedfill4()
           l_int32   pixSeedfill8()

      Static stack helper functions for single raster line seedfill:
           static void    pushFillsegBB()
           static void    pushFillseg()
           static void    popFillseg()

  The basic method in pixConnCompBB() is very simple.  We scan the
  image in raster order, looking for the next ON pixel.  When it
  is found, we erase it and every pixel of the 4- or 8-connected
  component to which it belongs, using Heckbert's seedfill
  algorithm.  As pixels are erased, we keep track of the
  minimum rectangle that encloses all erased pixels; after
  the connected component has been erased, we save its
  bounding box in an array of boxes.  When all pixels in the
  image have been erased, we have an array that describes every
  4- or 8-connected component in terms of its bounding box.

  pixConnCompPixa() is a slight variation on pixConnCompBB(),
  where we additionally save an array of images (in a Pixa)
  of each of the 4- or 8-connected components.  This is done trivially
  by maintaining two temporary images.  We erase a component from one,
  and use the bounding box to extract the pixels within the b.b.
  from each of the two images.  An XOR between these subimages
  gives the erased component.  Then we erase the component from the
  second image using the XOR again, with the extracted component
  placed on the second image at the location of the bounding box.
  Rasterop does all the work.  At the end, we have an array
  of the 4- or 8-connected components, as well as an array of the
  bounding boxes that describe where they came from in the original image.

  If you just want the number of connected components, pixCountConnComp()
  is a bit faster than pixConnCompBB(), because it doesn't have to
  keep track of the bounding rectangles for each c.c.

=head1 FUNCTIONS

=head2 nextOnPixelInRaster

l_int32 nextOnPixelInRaster ( PIX *pixs, l_int32 xstart, l_int32 ystart, l_int32 *px, l_int32 *py )

  nextOnPixelInRaster()

      Input:  pixs (1 bpp)
              xstart, ystart  (starting point for search)
              &x, &y  (<return> coord value of next ON pixel)
      Return: 1 if a pixel is found; 0 otherwise or on error

=head2 pixConnComp

BOXA * pixConnComp ( PIX *pixs, PIXA **ppixa, l_int32 connectivity )

  pixConnComp()

      Input:  pixs (1 bpp)
              &pixa   (<optional return> pixa of each c.c.)
              connectivity (4 or 8)
      Return: boxa, or null on error

  Notes:
      (1) This is the top-level call for getting bounding boxes or
          a pixa of the components, and it can be used instead
          of either pixConnCompBB() or pixConnCompPixa(), rsp.

=head2 pixConnCompBB

BOXA * pixConnCompBB ( PIX *pixs, l_int32 connectivity )

  pixConnCompBB()

      Input:  pixs (1 bpp)
              connectivity (4 or 8)
      Return: boxa, or null on error

 Notes:
     (1) Finds bounding boxes of 4- or 8-connected components
         in a binary image.
     (2) This works on a copy of the input pix.  The c.c. are located
         in raster order and erased one at a time.  In the process,
         the b.b. is computed and saved.

=head2 pixConnCompPixa

BOXA * pixConnCompPixa ( PIX *pixs, PIXA **ppixa, l_int32 connectivity )

  pixConnCompPixa()

      Input:  pixs (1 bpp)
              &pixa (<return> pixa of each c.c.)
              connectivity (4 or 8)
      Return: boxa, or null on error

  Notes:
      (1) This finds bounding boxes of 4- or 8-connected components
          in a binary image, and saves images of each c.c
          in a pixa array.
      (2) It sets up 2 temporary pix, and for each c.c. that is
          located in raster order, it erases the c.c. from one pix,
          then uses the b.b. to extract the c.c. from the two pix using
          an XOR, and finally erases the c.c. from the second pix.
      (3) A clone of the returned boxa (where all boxes in the array
          are clones) is inserted into the pixa.
      (4) If the input is valid, this always returns a boxa and a pixa.
          If pixs is empty, the boxa and pixa will be empty.

=head2 pixCountConnComp

l_int32 pixCountConnComp ( PIX *pixs, l_int32 connectivity, l_int32 *pcount )

  pixCountConnComp()

      Input:  pixs (1 bpp)
              connectivity (4 or 8)
              &count (<return>
      Return: 0 if OK, 1 on error

 Notes:
     (1) This is the top-level call for getting the number of
         4- or 8-connected components in a 1 bpp image.
     (2) It works on a copy of the input pix.  The c.c. are located
         in raster order and erased one at a time.

=head2 pixSeedfill

l_int32 pixSeedfill ( PIX *pixs, L_STACK *stack, l_int32 x, l_int32 y, l_int32 connectivity )

  pixSeedfill()

      Input:  pixs (1 bpp)
              stack (for holding fillsegs)
              x,y   (location of seed pixel)
              connectivity  (4 or 8)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This removes the component from pixs with a fg pixel at (x,y).
      (2) See pixSeedfill4() and pixSeedfill8() for details.

=head2 pixSeedfill4

l_int32 pixSeedfill4 ( PIX *pixs, L_STACK *stack, l_int32 x, l_int32 y )

  pixSeedfill4()

      Input:  pixs (1 bpp)
              stack (for holding fillsegs)
              x,y   (location of seed pixel)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is Paul Heckbert's stack-based 4-cc seedfill algorithm.
      (2) This operates on the input 1 bpp pix to remove the fg seed
          pixel, at (x,y), and all pixels that are 4-connected to it.
          The seed pixel at (x,y) must initially be ON.
      (3) Reference: see pixSeedFill4BB()

=head2 pixSeedfill4BB

BOX * pixSeedfill4BB ( PIX *pixs, L_STACK *stack, l_int32 x, l_int32 y )

  pixSeedfill4BB()

      Input:  pixs (1 bpp)
              stack (for holding fillsegs)
              x,y   (location of seed pixel)
      Return: box or null on error.

  Notes:
      (1) This is Paul Heckbert's stack-based 4-cc seedfill algorithm.
      (2) This operates on the input 1 bpp pix to remove the fg seed
          pixel, at (x,y), and all pixels that are 4-connected to it.
          The seed pixel at (x,y) must initially be ON.
      (3) Returns the bounding box of the erased 4-cc component.
      (4) Reference: see Paul Heckbert's stack-based seed fill algorithm
          in "Graphic Gems", ed. Andrew Glassner, Academic
          Press, 1990.  The algorithm description is given
          on pp. 275-277; working C code is on pp. 721-722.)
          The code here follows Heckbert's exactly, except
          we use function calls instead of macros for
          pushing data on and popping data off the stack.
          This makes sense to do because Heckbert's fixed-size
          stack with macros is dangerous: images exist that
          will overrun the stack and crash.   The stack utility
          here grows dynamically as needed, and the fillseg
          structures that are not in use are stored in another
          stack for reuse.  It should be noted that the
          overhead in the function calls (vs. macros) is negligible.

=head2 pixSeedfill8

l_int32 pixSeedfill8 ( PIX *pixs, L_STACK *stack, l_int32 x, l_int32 y )

  pixSeedfill8()

      Input:  pixs (1 bpp)
              stack (for holding fillsegs)
              x,y   (location of seed pixel)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is Paul Heckbert's stack-based 8-cc seedfill algorithm.
      (2) This operates on the input 1 bpp pix to remove the fg seed
          pixel, at (x,y), and all pixels that are 8-connected to it.
          The seed pixel at (x,y) must initially be ON.
      (3) Reference: see pixSeedFill8BB()

=head2 pixSeedfill8BB

BOX * pixSeedfill8BB ( PIX *pixs, L_STACK *stack, l_int32 x, l_int32 y )

  pixSeedfill8BB()

      Input:  pixs (1 bpp)
              stack (for holding fillsegs)
              x,y   (location of seed pixel)
      Return: box or null on error.

  Notes:
      (1) This is Paul Heckbert's stack-based 8-cc seedfill algorithm.
      (2) This operates on the input 1 bpp pix to remove the fg seed
          pixel, at (x,y), and all pixels that are 8-connected to it.
          The seed pixel at (x,y) must initially be ON.
      (3) Returns the bounding box of the erased 8-cc component.
      (4) Reference: see Paul Heckbert's stack-based seed fill algorithm
          in "Graphic Gems", ed. Andrew Glassner, Academic
          Press, 1990.  The algorithm description is given
          on pp. 275-277; working C code is on pp. 721-722.)
          The code here follows Heckbert's closely, except
          the leak checks are changed for 8 connectivity.
          See comments on pixSeedfill4BB() for more details.

=head2 pixSeedfillBB

BOX * pixSeedfillBB ( PIX *pixs, L_STACK *stack, l_int32 x, l_int32 y, l_int32 connectivity )

  pixSeedfillBB()

      Input:  pixs (1 bpp)
              stack (for holding fillsegs)
              x,y   (location of seed pixel)
              connectivity  (4 or 8)
      Return: box or null on error

  Notes:
      (1) This is the high-level interface to Paul Heckbert's
          stack-based seedfill algorithm.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
