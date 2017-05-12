package Image::Leptonica::Func::pixafunc2;
$Image::Leptonica::Func::pixafunc2::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pixafunc2

=head1 VERSION

version 0.04

=head1 C<pixafunc2.c>

   pixafunc2.c

      Pixa Display (render into a pix)
           PIX      *pixaDisplay()
           PIX      *pixaDisplayOnColor()
           PIX      *pixaDisplayRandomCmap()
           PIX      *pixaDisplayLinearly()
           PIX      *pixaDisplayOnLattice()
           PIX      *pixaDisplayUnsplit()
           PIX      *pixaDisplayTiled()
           PIX      *pixaDisplayTiledInRows()
           PIX      *pixaDisplayTiledAndScaled()

      Pixaa Display (render into a pix)
           PIX      *pixaaDisplay()
           PIX      *pixaaDisplayByPixa()
           PIXA     *pixaaDisplayTiledAndScaled()

      Conversion of all pix to specified type (e.g., depth)
           PIXA     *pixaConvertTo1()
           PIXA     *pixaConvertTo8()
           PIXA     *pixaConvertTo8Color()
           PIXA     *pixaConvertTo32()

      Tile N-Up
           l_int32   convertToNUpFiles()
           PIXA     *convertToNUpPixa()

  We give seven methods for displaying a pixa in a pix.
  Some work for 1 bpp input; others for any input depth.
  Some give an output depth that depends on the input depth;
  others give a different output depth or allow you to choose it.
  Some use a boxes to determine where each pix goes; others tile
  onto a regular lattice; yet others tile onto an irregular lattice.

  Here is a brief description of what the pixa display functions do.

    pixaDisplay()
        This uses the boxes to lay out each pix.  It is typically
        used to reconstruct a pix that has been broken into components.
    pixaDisplayOnColor()
        pixaDisplay() with choice of background color
    pixaDisplayRandomCmap()
        This also uses the boxes to lay out each pix.  However, it creates
        a colormapped dest, where each 1 bpp pix is given a randomly
        generated color (up to 256 are used).
    pixaDisplayLinearly()
        This puts each pix, sequentially, in a line, either horizontally
        or vertically.
    pixaDisplayOnLattice()
        This puts each pix, sequentially, onto a regular lattice,
        omitting any pix that are too big for the lattice size.
        This is useful, for example, to store bitmapped fonts,
        where all the characters are stored in a single image.
    pixaDisplayUnsplit()
        This lays out a mosaic of tiles (the pix in the pixa) that
        are all of equal size.  (Don't use this for unequal sized pix!)
        For example, it can be used to invert the action of
        pixaSplitPix().
    pixaDisplayTiled()
        Like pixaDisplayOnLattice(), this places each pix on a regular
        lattice, but here the lattice size is determined by the
        largest component, and no components are omitted.  This is
        dangerous if there are thousands of small components and
        one or more very large one, because the size of the resulting
        pix can be huge!
    pixaDisplayTiledInRows()
        This puts each pix down in a series of rows, where the upper
        edges of each pix in a row are aligned and there is a uniform
        spacing between the pix.  The height of each row is determined
        by the tallest pix that was put in the row.  This function
        is a reasonably efficient way to pack the subimages.
        A boxa of the locations of each input pix is stored in the output.
    pixaDisplayTiledAndScaled()
        This scales each pix to a given width and output depth,
        and then tiles them in rows with a given number placed in
        each row.  This is very useful for presenting a sequence
        of images that can be at different resolutions, but which
        are derived from the same initial image.

=head1 FUNCTIONS

=head2 convertToNUpFiles

l_int32 convertToNUpFiles ( const char *dir, const char *substr, l_int32 nx, l_int32 ny, l_float32 scaling, l_int32 spacing, l_int32 border, const char *outdir )

  convertToNUpFiles()

      Input:  indir (full path to directory of images)
              substr (<optional> can be null)
              nx, ny (in [1, ... 50], tiling factors in each direction)
              scaling (approximate overall scaling factor, after tiling)
              spacing  (between images, and on outside)
              border (width of additional black border on each image;
                      use 0 for no border)
              outdir (subdirectory of /tmp to put N-up tiled images)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Each set of nx*ny images is scaled and tiled into a single
          image, that is written out to @outdir.
      (2) All images in each nx*ny set are scaled to the same width.
          This is typically used when all images are roughly the same
          size.
      (3) Typical values for nx and ny are in [2 ... 5].
      (4) The reciprocal of nx is used for scaling.  If nx == ny, the
          resulting image shape is similar to that of the input images.

=head2 convertToNUpPixa

PIXA * convertToNUpPixa ( const char *dir, const char *substr, l_int32 nx, l_int32 ny, l_float32 scaling, l_int32 spacing, l_int32 border )

  convertToNUpPixa()

      Input:  dir (full path to directory of images)
              substr (<optional> can be null)
              nx, ny (in [1, ... 50], tiling factors in each direction)
              scaling (approximate overall scaling factor, after tiling)
              spacing  (between images, and on outside)
              border (width of additional black border on each image;
                      use 0 for no border)
      Return: pixad, or null on error

  Notes:
      (1) See notes for filesTileNUp()

=head2 pixaConvertTo1

PIXA * pixaConvertTo1 ( PIXA *pixas, l_int32 thresh )

  pixaConvertTo1()

      Input:  pixas
              thresh (threshold for final binarization from 8 bpp gray)
      Return: pixad, or null on error

=head2 pixaConvertTo32

PIXA * pixaConvertTo32 ( PIXA *pixas )

  pixaConvertTo32()

      Input:  pixas
      Return: pixad (32 bpp rgb), or null on error

  Notes:
      (1) See notes for pixConvertTo32(), applied to each pix in pixas.

=head2 pixaConvertTo8

PIXA * pixaConvertTo8 ( PIXA *pixas, l_int32 cmapflag )

  pixaConvertTo8()

      Input:  pixas
              cmapflag (1 to give pixd a colormap; 0 otherwise)
      Return: pixad (each pix is 8 bpp), or null on error

  Notes:
      (1) See notes for pixConvertTo8(), applied to each pix in pixas.

=head2 pixaConvertTo8Color

PIXA * pixaConvertTo8Color ( PIXA *pixas, l_int32 dither )

  pixaConvertTo8Color()

      Input:  pixas
              ditherflag (1 to dither if necessary; 0 otherwise)
      Return: pixad (each pix is 8 bpp), or null on error

  Notes:
      (1) See notes for pixConvertTo8Color(), applied to each pix in pixas.

=head2 pixaDisplay

PIX * pixaDisplay ( PIXA *pixa, l_int32 w, l_int32 h )

  pixaDisplay()

      Input:  pixa
              w, h (if set to 0, determines the size from the
                    b.b. of the components in pixa)
      Return: pix, or null on error

  Notes:
      (1) This uses the boxes to place each pix in the rendered composite.
      (2) Set w = h = 0 to use the b.b. of the components to determine
          the size of the returned pix.
      (3) Uses the first pix in pixa to determine the depth.
      (4) The background is written "white".  On 1 bpp, each successive
          pix is "painted" (adding foreground), whereas for grayscale
          or color each successive pix is blitted with just the src.
      (5) If the pixa is empty, returns an empty 1 bpp pix.

=head2 pixaDisplayLinearly

PIX * pixaDisplayLinearly ( PIXA *pixas, l_int32 direction, l_float32 scalefactor, l_int32 background, l_int32 spacing, l_int32 border, BOXA **pboxa )

  pixaDisplayLinearly()

      Input:  pixa
              direction (L_HORIZ or L_VERT)
              scalefactor (applied to every pix; use 1.0 for no scaling)
              background (0 for white, 1 for black; this is the color
                 of the spacing between the images)
              spacing  (between images, and on outside)
              border (width of black border added to each image;
                      use 0 for no border)
              &boxa (<optional return> location of images in output pix
      Return: pix of composite images, or null on error

  Notes:
      (1) This puts each pix, sequentially, in a line, either horizontally
          or vertically.
      (2) If any pix has a colormap, all pix are rendered in rgb.
      (3) The boxa gives the location of each image.

=head2 pixaDisplayOnColor

PIX * pixaDisplayOnColor ( PIXA *pixa, l_int32 w, l_int32 h, l_uint32 bgcolor )

  pixaDisplayOnColor()

      Input:  pixa
              w, h (if set to 0, determines the size from the
                    b.b. of the components in pixa)
              color (background color to use)
      Return: pix, or null on error

  Notes:
      (1) This uses the boxes to place each pix in the rendered composite.
      (2) Set w = h = 0 to use the b.b. of the components to determine
          the size of the returned pix.
      (3) If any pix in @pixa are colormapped, or if the pix have
          different depths, it returns a 32 bpp pix.  Otherwise,
          the depth of the returned pixa equals that of the pix in @pixa.
      (4) If the pixa is empty, return null.

=head2 pixaDisplayOnLattice

PIX * pixaDisplayOnLattice ( PIXA *pixa, l_int32 cellw, l_int32 cellh, l_int32 *pncols, BOXA **pboxa )

  pixaDisplayOnLattice()

      Input:  pixa
              cellw (lattice cell width)
              cellh (lattice cell height)
              &ncols (<optional return> number of columns in output lattice)
              &boxa (<optional return> location of images in lattice)
      Return: pix of composite images, or null on error

  Notes:
      (1) This places each pix on sequentially on a regular lattice
          in the rendered composite.  If a pix is too large to fit in the
          allocated lattice space, it is not rendered.
      (2) If any pix has a colormap, all pix are rendered in rgb.
      (3) This is useful when putting bitmaps of components,
          such as characters, into a single image.
      (4) The boxa gives the location of each image.  The UL corner
          of each image is on a lattice cell corner.  Omitted images
          (due to size) are assigned an invalid width and height of 0.

=head2 pixaDisplayRandomCmap

PIX * pixaDisplayRandomCmap ( PIXA *pixa, l_int32 w, l_int32 h )

  pixaDisplayRandomCmap()

      Input:  pixa (of 1 bpp components, with boxa)
              w, h (if set to 0, determines the size from the
                    b.b. of the components in pixa)
      Return: pix (8 bpp, cmapped, with random colors on the components),
              or null on error

  Notes:
      (1) This uses the boxes to place each pix in the rendered composite.
      (2) By default, the background color is: black, cmap index 0.
          This can be changed by pixcmapResetColor()

=head2 pixaDisplayTiled

PIX * pixaDisplayTiled ( PIXA *pixa, l_int32 maxwidth, l_int32 background, l_int32 spacing )

  pixaDisplayTiled()

      Input:  pixa
              maxwidth (of output image)
              background (0 for white, 1 for black)
              spacing
      Return: pix of tiled images, or null on error

  Notes:
      (1) This renders a pixa to a single image file of width not to
          exceed maxwidth, with background color either white or black,
          and with each subimage spaced on a regular lattice.
      (2) The lattice size is determined from the largest width and height,
          separately, of all pix in the pixa.
      (3) All pix in the pixa must be of equal depth.
      (4) If any pix has a colormap, all pix are rendered in rgb.
      (5) Careful: because no components are omitted, this is
          dangerous if there are thousands of small components and
          one or more very large one, because the size of the
          resulting pix can be huge!

=head2 pixaDisplayTiledAndScaled

PIX * pixaDisplayTiledAndScaled ( PIXA *pixa, l_int32 outdepth, l_int32 tilewidth, l_int32 ncols, l_int32 background, l_int32 spacing, l_int32 border )

  pixaDisplayTiledAndScaled()

      Input:  pixa
              outdepth (output depth: 1, 8 or 32 bpp)
              tilewidth (each pix is scaled to this width)
              ncols (number of tiles in each row)
              background (0 for white, 1 for black; this is the color
                 of the spacing between the images)
              spacing  (between images, and on outside)
              border (width of additional black border on each image;
                      use 0 for no border)
      Return: pix of tiled images, or null on error

  Notes:
      (1) This can be used to tile a number of renderings of
          an image that are at different scales and depths.
      (2) Each image, after scaling and optionally adding the
          black border, has width 'tilewidth'.  Thus, the border does
          not affect the spacing between the image tiles.  The
          maximum allowed border width is tilewidth / 5.

=head2 pixaDisplayTiledInRows

PIX * pixaDisplayTiledInRows ( PIXA *pixa, l_int32 outdepth, l_int32 maxwidth, l_float32 scalefactor, l_int32 background, l_int32 spacing, l_int32 border )

  pixaDisplayTiledInRows()

      Input:  pixa
              outdepth (output depth: 1, 8 or 32 bpp)
              maxwidth (of output image)
              scalefactor (applied to every pix; use 1.0 for no scaling)
              background (0 for white, 1 for black; this is the color
                 of the spacing between the images)
              spacing  (between images, and on outside)
              border (width of black border added to each image;
                      use 0 for no border)
      Return: pixd (of tiled images), or null on error

  Notes:
      (1) This renders a pixa to a single image file of width not to
          exceed maxwidth, with background color either white or black,
          and with each row tiled such that the top of each pix is
          aligned and separated by 'spacing' from the next one.
          A black border can be added to each pix.
      (2) All pix are converted to outdepth; existing colormaps are removed.
      (3) This does a reasonably spacewise-efficient job of laying
          out the individual pix images into a tiled composite.
      (4) A serialized boxa giving the location in pixd of each input
          pix (without added border) is stored in the text string of pixd.
          This allows, e.g., regeneration of a pixa from pixd, using
          pixaCreateFromBoxa().  If there is no scaling and the depth of
          each input pix in the pixa is the same, this tiling operation
          can be inverted using the boxa (except for loss of text in
          each of the input pix):
            pix1 = pixaDisplayTiledInRows(pixa1, 1, 1500, 1.0, 0, 30, 0);
            char *boxatxt = pixGetText(pix1);
            boxa1 = boxaReadMem((l_uint8 *)boxatxt, strlen(boxatxt));
            pixa2 = pixaCreateFromBoxa(pix1, boxa1, NULL);

=head2 pixaDisplayUnsplit

PIX * pixaDisplayUnsplit ( PIXA *pixa, l_int32 nx, l_int32 ny, l_int32 borderwidth, l_uint32 bordercolor )

  pixaDisplayUnsplit()

      Input:  pixa
              nx   (number of mosaic cells horizontally)
              ny   (number of mosaic cells vertically)
              borderwidth  (of added border on all sides)
              bordercolor  (in our RGBA format: 0xrrggbbaa)
      Return: pix of tiled images, or null on error

  Notes:
      (1) This is a logical inverse of pixaSplitPix().  It
          constructs a pix from a mosaic of tiles, all of equal size.
      (2) For added generality, a border of arbitrary color can
          be added to each of the tiles.
      (3) In use, pixa will typically have either been generated
          from pixaSplitPix() or will derived from a pixa that
          was so generated.
      (4) All pix in the pixa must be of equal depth, and, if
          colormapped, have the same colormap.

=head2 pixaaDisplay

PIX * pixaaDisplay ( PIXAA *paa, l_int32 w, l_int32 h )

  pixaaDisplay()

      Input:  paa
              w, h (if set to 0, determines the size from the
                    b.b. of the components in paa)
      Return: pix, or null on error

  Notes:
      (1) Each pix of the paa is displayed at the location given by
          its box, translated by the box of the containing pixa
          if it exists.

=head2 pixaaDisplayByPixa

PIX * pixaaDisplayByPixa ( PIXAA *paa, l_int32 xspace, l_int32 yspace, l_int32 maxw )

  pixaaDisplayByPixa()

      Input:  paa (with pix that may have different depths)
              xspace between pix in pixa
              yspace between pixa
              max width of output pix
      Return: pixd, or null on error

  Notes:
      (1) Displays each pixa on a line (or set of lines),
          in order from top to bottom.  Within each pixa,
          the pix are displayed in order from left to right.
      (2) The sizes and depths of each pix can differ.  The output pix
          has a depth equal to the max depth of all the pix.
      (3) This ignores the boxa of the paa.

=head2 pixaaDisplayTiledAndScaled

PIXA * pixaaDisplayTiledAndScaled ( PIXAA *paa, l_int32 outdepth, l_int32 tilewidth, l_int32 ncols, l_int32 background, l_int32 spacing, l_int32 border )

  pixaaDisplayTiledAndScaled()

      Input:  paa
              outdepth (output depth: 1, 8 or 32 bpp)
              tilewidth (each pix is scaled to this width)
              ncols (number of tiles in each row)
              background (0 for white, 1 for black; this is the color
                 of the spacing between the images)
              spacing  (between images, and on outside)
              border (width of additional black border on each image;
                      use 0 for no border)
      Return: pixa (of tiled images, one image for each pixa in
                    the paa), or null on error

  Notes:
      (1) For each pixa, this generates from all the pix a
          tiled/scaled output pix, and puts it in the output pixa.
      (2) See comments in pixaDisplayTiledAndScaled().

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
