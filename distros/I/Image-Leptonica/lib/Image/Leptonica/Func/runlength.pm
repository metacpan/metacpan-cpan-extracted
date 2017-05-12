package Image::Leptonica::Func::runlength;
$Image::Leptonica::Func::runlength::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::runlength

=head1 VERSION

version 0.04

=head1 C<runlength.c>

  runlength.c

     Label pixels by membership in runs
           PIX         *pixStrokeWidthTransform()
           static PIX  *pixFindMinRunsOrthogonal()
           PIX         *pixRunlengthTransform()

     Find runs along horizontal and vertical lines
           l_int32      pixFindHorizontalRuns()
           l_int32      pixFindVerticalRuns()

     Compute runlength-to-membership transform on a line
           l_int32      runlengthMembershipOnLine()

     Make byte position LUT
           l_int32      makeMSBitLocTab()

=head1 FUNCTIONS

=head2 makeMSBitLocTab

l_int32 * makeMSBitLocTab ( l_int32 bitval )

  makeMSBitLocTab()

      Input:  bitval (either 0 or 1)
      Return: table (giving, for an input byte, the MS bit location,
                     starting at 0 with the MSBit in the byte),
                     or null on error.

  Notes:
      (1) If bitval == 1, it finds the leftmost ON pixel in a byte;
          otherwise if bitval == 0, it finds the leftmost OFF pixel.
      (2) If there are no pixels of the indicated color in the byte,
          this returns 8.

=head2 pixFindHorizontalRuns

l_int32 pixFindHorizontalRuns ( PIX *pix, l_int32 y, l_int32 *xstart, l_int32 *xend, l_int32 *pn )

  pixFindHorizontalRuns()

      Input:  pix (1 bpp)
              y (line to traverse)
              xstart (returns array of start positions for fg runs)
              xend (returns array of end positions for fg runs)
              &n  (<return> the number of runs found)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This finds foreground horizontal runs on a single scanline.
      (2) To find background runs, use pixInvert() before applying
          this function.
      (3) The xstart and xend arrays are input.  They should be
          of size w/2 + 1 to insure that they can hold
          the maximum number of runs in the raster line.

=head2 pixFindVerticalRuns

l_int32 pixFindVerticalRuns ( PIX *pix, l_int32 x, l_int32 *ystart, l_int32 *yend, l_int32 *pn )

  pixFindVerticalRuns()

      Input:  pix (1 bpp)
              x (line to traverse)
              ystart (returns array of start positions for fg runs)
              yend (returns array of end positions for fg runs)
              &n   (<return> the number of runs found)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This finds foreground vertical runs on a single scanline.
      (2) To find background runs, use pixInvert() before applying
          this function.
      (3) The ystart and yend arrays are input.  They should be
          of size h/2 + 1 to insure that they can hold
          the maximum number of runs in the raster line.

=head2 pixRunlengthTransform

PIX * pixRunlengthTransform ( PIX *pixs, l_int32 color, l_int32 direction, l_int32 depth )

  pixRunlengthTransform()

      Input:   pixs (1 bpp)
               color (0 for white runs, 1 for black runs)
               direction (L_HORIZONTAL_RUNS, L_VERTICAL_RUNS)
               depth (8 or 16 bpp)
      Return:  pixd (8 or 16 bpp), or null on error

  Notes:
      (1) The dest Pix is 8 or 16 bpp, with the pixel values
          equal to the runlength in which it is a member.
          The length is clipped to the max pixel value if necessary.
      (2) The color determines if we're labelling white or black runs.
      (3) A pixel that is not a member of the chosen color gets
          value 0; it belongs to a run of length 0 of the
          chosen color.
      (4) To convert for maximum dynamic range, either linear or
          log, use pixMaxDynamicRange().

=head2 pixStrokeWidthTransform

PIX * pixStrokeWidthTransform ( PIX *pixs, l_int32 color, l_int32 depth, l_int32 nangles )

  pixStrokeWidthTransform()

      Input:   pixs (1 bpp)
               color (0 for white runs, 1 for black runs)
               depth (of pixd: 8 or 16 bpp)
               nangles (2, 4, 6 or 8)
      Return:  pixd (8 or 16 bpp), or null on error

  Notes:
      (1) The dest Pix is 8 or 16 bpp, with the pixel values
          equal to the stroke width in which it is a member.
          The values are clipped to the max pixel value if necessary.
      (2) The color determines if we're labelling white or black strokes.
      (3) A pixel that is not a member of the chosen color gets
          value 0; it belongs to a width of length 0 of the
          chosen color.
      (4) This chooses, for each dest pixel, the minimum of sets
          of runlengths through each pixel.  Here are the sets:
            nangles    increment          set
            -------    ---------    --------------------------------
               2          90       {0, 90}
               4          45       {0, 45, 90, 135}
               6          30       {0, 30, 60, 90, 120, 150}
               8          22.5     {0, 22.5, 45, 67.5, 90, 112.5, 135, 157.5}
      (5) Runtime scales linearly with (nangles - 2).

=head2 runlengthMembershipOnLine

l_int32 runlengthMembershipOnLine ( l_int32 *buffer, l_int32 size, l_int32 depth, l_int32 *start, l_int32 *end, l_int32 n )

  runlengthMembershipOnLine()

      Input:   buffer (into which full line of data is placed)
               size (full size of line; w or h)
               depth (8 or 16 bpp)
               start (array of start positions for fg runs)
               end (array of end positions for fg runs)
               n   (the number of runs)
      Return:  0 if OK; 1 on error

  Notes:
      (1) Converts a set of runlengths into a buffer of
          runlength membership values.
      (2) Initialization of the array gives pixels that are
          not within a run the value 0.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
