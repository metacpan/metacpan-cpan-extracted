package Image::Leptonica::Func::pixtiling;
$Image::Leptonica::Func::pixtiling::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pixtiling

=head1 VERSION

version 0.04

=head1 C<pixtiling.c>

   pixtiling.c

        PIXTILING       *pixTilingCreate()
        void            *pixTilingDestroy()
        l_int32          pixTilingGetCount()
        l_int32          pixTilingGetSize()
        PIX             *pixTilingGetTile()
        l_int32          pixTilingNoStripOnPaint()
        l_int32          pixTilingPaintTile()


   This provides a simple way to split an image into tiles
   and to perform operations independently on each tile.

   The tile created with pixTilingGetTile() can have pixels in
   adjacent tiles for computation.  The number of extra pixels
   on each side of the tile is given by an 'overlap' parameter
   to pixTilingCreate().  For tiles at the boundary of
   the input image, quasi-overlap pixels are created by reflection
   symmetry into the tile.

   Here's a typical intended usage.  Suppose you want to parallelize
   the operation on an image, by operating on tiles.  For each
   tile, you want to generate an in-place image result at the same
   resolution.  Suppose you choose a one-dimensional vertical tiling,
   where the desired tile width is 256 pixels and the overlap is
   30 pixels on left and right sides:

     PIX *pixd = pixCreateTemplateNoInit(pixs);  // output
     PIXTILING  *pt = pixTilingCreate(pixs, 0, 1, 256, 30, 0);
     pixTilingGetCount(pt, &nx, NULL);
     for (j = 0; j < nx; j++) {
         PIX *pixt = pixTilingGetTile(pt, 0, j);
         SomeInPlaceOperation(pixt, 30, 0, ...);
         pixTilingPaintTile(pixd, 0, j, pixt, pt);
         pixDestroy(&pixt);
     }

   In this example, note the following:
    - The unspecfified in-place operation could instead generate
      a new pix.  If this is done, the resulting pix must be the
      same size as pixt, because pixTilingPaintTile() makes that
      assumption, removing the overlap pixels before painting
      into the destination.
    - The 'overlap' parameters have been included in your function,
      to indicate which pixels are not in the exterior overlap region.
      You will need to change only pixels that are not in the overlap
      region, because those are the pixels that will be painted
      into the destination.
    - For tiles on the outside of the image, mirrored pixels are
      added to substitute for the overlap that is added to interior
      tiles.  This allows you to implement your function without
      reference to which tile it is; no special coding is necessary
      for pixels that are near the image boundary.
    - The tiles are labeled by (i, j) = (row, column),
      and in this example there is one row and nx columns.

=head1 FUNCTIONS

=head2 pixTilingCreate

PIXTILING * pixTilingCreate ( PIX *pixs, l_int32 nx, l_int32 ny, l_int32 w, l_int32 h, l_int32 xoverlap, l_int32 yoverlap )

  pixTilingCreate()

      Input:  pixs  (pix to be tiled; any depth; colormap OK)
              nx    (number of tiles across image)
              ny    (number of tiles down image)
              w     (desired width of each tile)
              h     (desired height of each tile)
              overlap (amount of overlap into neighboring tile on each side)
      Return: pixtiling, or null on error

  Notes:
      (1) We put a clone of pixs in the PixTiling.
      (2) The input to pixTilingCreate() for horizontal tiling can be
          either the number of tiles across the image or the approximate
          width of the tiles.  If the latter, the actual width will be
          determined by making all tiles but the last of equal width, and
          making the last as close to the others as possible.  The same
          consideration is applied independently to the vertical tiling.
          To specify tile width, set nx = 0; to specify the number of
          tiles horizontally across the image, set w = 0.
      (3) If pixs is to be tiled in one-dimensional strips, use ny = 1 for
          vertical strips and nx = 1 for horizontal strips.
      (4) The overlap must not be larger than the width or height of
          the leftmost or topmost tile(s).

=head2 pixTilingDestroy

void pixTilingDestroy ( PIXTILING **ppt )

  pixTilingDestroy()

      Input:  &pt (<will be set to null before returning>)
      Return: void

=head2 pixTilingGetCount

l_int32 pixTilingGetCount ( PIXTILING *pt, l_int32 *pnx, l_int32 *pny )

  pixTilingGetCount()

      Input:  pt (pixtiling)
              &nx (<optional return> nx; can be null)
              &ny (<optional return> ny; can be null)
      Return: 0 if OK, 1 on error

=head2 pixTilingGetSize

l_int32 pixTilingGetSize ( PIXTILING *pt, l_int32 *pw, l_int32 *ph )

  pixTilingGetSize()

      Input:  pt (pixtiling)
              &w (<optional return> tile width; can be null)
              &h (<optional return> tile height; can be null)
      Return: 0 if OK, 1 on error

=head2 pixTilingGetTile

PIX * pixTilingGetTile ( PIXTILING *pt, l_int32 i, l_int32 j )

  pixTilingGetTile()

      Input:  pt (pixtiling)
              i (tile row index)
              j (tile column index)
      Return: pixd (tile with appropriate boundary (overlap) pixels added),
                    or null on error

=head2 pixTilingNoStripOnPaint

l_int32 pixTilingNoStripOnPaint ( PIXTILING *pt )

  pixTilingNoStripOnPaint()

      Input:  pt (pixtiling)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The default for paint is to strip out the overlap pixels
          that are added by pixTilingGetTile().  However, some
          operations will generate an image with these pixels
          stripped off.  This tells the paint operation not
          to strip the added boundary pixels when painting.

=head2 pixTilingPaintTile

l_int32 pixTilingPaintTile ( PIX *pixd, l_int32 i, l_int32 j, PIX *pixs, PIXTILING *pt )

  pixTilingPaintTile()

      Input:  pixd (dest: paint tile onto this, without overlap)
              i (tile row index)
              j (tile column index)
              pixs (source: tile to be painted from)
              pt (pixtiling struct)
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
