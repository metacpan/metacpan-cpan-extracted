package Image::Leptonica::Func::readbarcode;
$Image::Leptonica::Func::readbarcode::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::readbarcode

=head1 VERSION

version 0.04

=head1 C<readbarcode.c>

  readbarcode.c

      Basic operations to locate and identify the line widths
      in 1D barcodes.

      Top level
          SARRAY          *pixProcessBarcodes()

      Next levels
          PIXA            *pixExtractBarcodes()
          SARRAY          *pixReadBarcodes()
          l_int32          pixReadBarcodeWidths()

      Location
          BOXA            *pixLocateBarcodes()
          static PIX      *pixGenerateBarcodeMask()

      Extraction and deskew
          PIXA            *pixDeskewBarcodes()

      Process to get line widths
          NUMA            *pixExtractBarcodeWidths1()
          NUMA            *pixExtractBarcodeWidths2()
          NUMA            *pixExtractBarcodeCrossings()

      Average adjacent rasters
          static NUMA     *pixAverageRasterScans()

      Signal processing for barcode widths
          NUMA            *numaQuantizeCrossingsByWidth()
          static l_int32   numaGetCrossingDistances()
          static NUMA     *numaLocatePeakRanges()
          static NUMA     *numaGetPeakCentroids()
          static NUMA     *numaGetPeakWidthLUT()
          NUMA            *numaQuantizeCrossingsByWindow()
          static l_int32   numaEvalBestWidthAndShift()
          static l_int32   numaEvalSyncError()


  NOTE CAREFULLY: This is "early beta" code.  It has not been tuned
  to work robustly on a large database of barcode images.  I'm putting
  it out so that people can play with it, find out how it breaks, and
  contribute decoders for other barcode formats.  Both the functional
  interfaces and ABI will almost certainly change in the coming
  few months.  The actual decoder, in bardecode.c, at present only
  works on the following codes: Code I2of5, Code 2of5, Code 39, Code 93
  Codabar and UPCA.  To add another barcode format, it is necessary
  to make changes in readbarcode.h and bardecode.c.
  The program prog/barcodetest shows how to run from the top level
  (image --> decoded data).

=head1 FUNCTIONS

=head2 numaQuantizeCrossingsByWidth

NUMA * numaQuantizeCrossingsByWidth ( NUMA *nas, l_float32 binfract, NUMA **pnaehist, NUMA **pnaohist, l_int32 debugflag )

  numaQuantizeCrossingsByWidth()

      Input:  nas (numa of crossing locations, in pixel units)
              binfract (histo binsize as a fraction of minsize; e.g., 0.25)
              &naehist (<optional return> histo of even (black) bar widths)
              &naohist (<optional return> histo of odd (white) bar widths)
              debugflag (1 to generate plots of histograms of bar widths)
      Return: nad (sequence of widths, in unit sizes), or null on error

  Notes:
      (1) This first computes the histogram of black and white bar widths,
          binned in appropriate units.  There should be well-defined
          peaks, each corresponding to a specific width.  The sequence
          of barcode widths (namely, the integers from the set {1,2,3,4})
          is returned.
      (2) The optional returned histograms are binned in width units
          that are inversely proportional to @binfract.  For example,
          if @binfract = 0.25, there are 4.0 bins in the distance of
          the width of the narrowest bar.

=head2 numaQuantizeCrossingsByWindow

NUMA * numaQuantizeCrossingsByWindow ( NUMA *nas, l_float32 ratio, l_float32 *pwidth, l_float32 *pfirstloc, NUMA **pnac, l_int32 debugflag )

  numaQuantizeCrossingsByWindow()

      Input:  nas (numa of crossing locations)
              ratio (of max window size over min window size in search;
                     typ. 2.0)
              &width (<optional return> best window width)
              &firstloc (<optional return> center of window for first xing)
              &nac (<optional return> array of window crossings (0, 1, 2))
              debugflag (1 to generate various plots of intermediate results)
      Return: nad (sequence of widths, in unit sizes), or null on error

  Notes:
      (1) The minimum size of the window is set by the minimum
          distance between zero crossings.
      (2) The optional return signal @nac is a sequence of 0s, 1s,
          and perhaps a few 2s, giving the number of crossings in each window.
          On the occasion where there is a '2', it is interpreted as
          ending two runs: the previous one and another one that has length 1.

=head2 pixDeskewBarcode

PIX * pixDeskewBarcode ( PIX *pixs, PIX *pixb, BOX *box, l_int32 margin, l_int32 threshold, l_float32 *pangle, l_float32 *pconf )

  pixDeskewBarcode()

      Input:  pixs (input image; 8 bpp)
              pixb (binarized edge-filtered input image)
              box (identified region containing barcode)
              margin (of extra pixels around box to extract)
              threshold (for binarization; ~20)
              &angle (<optional return> in degrees, clockwise is positive)
              &conf (<optional return> confidence)
      Return: pixd (deskewed barcode), or null on error

  Note:
     (1) The (optional) angle returned is the angle in degrees (cw positive)
         necessary to rotate the image so that it is deskewed.

=head2 pixExtractBarcodeCrossings

NUMA * pixExtractBarcodeCrossings ( PIX *pixs, l_float32 thresh, l_int32 debugflag )

  pixExtractBarcodeCrossings()

      Input:  pixs (input image; 8 bpp)
              thresh (estimated pixel threshold for crossing
                      white <--> black; typ. ~120)
              debugflag (use 1 to generate debug output)
      Return: numa (of crossings, in pixel units), or null on error

=head2 pixExtractBarcodeWidths1

NUMA * pixExtractBarcodeWidths1 ( PIX *pixs, l_float32 thresh, l_float32 binfract, NUMA **pnaehist, NUMA **pnaohist, l_int32 debugflag )

  pixExtractBarcodeWidths1()

      Input:  pixs (input image; 8 bpp)
              thresh (estimated pixel threshold for crossing
                      white <--> black; typ. ~120)
              binfract (histo binsize as a fraction of minsize; e.g., 0.25)
              &naehist (<optional return> histogram of black widths; NULL ok)
              &naohist (<optional return> histogram of white widths; NULL ok)
              debugflag (use 1 to generate debug output)
      Return: nad (numa of barcode widths in encoded integer units),
                  or null on error

  Note:
     (1) The widths are alternating black/white, starting with black
         and ending with black.
     (2) This method uses the widths of the bars directly, in terms
         of the (float) number of pixels between transitions.
         The histograms of these widths for black and white bars is
         generated and interpreted.

=head2 pixExtractBarcodeWidths2

NUMA * pixExtractBarcodeWidths2 ( PIX *pixs, l_float32 thresh, l_float32 *pwidth, NUMA **pnac, l_int32 debugflag )

  pixExtractBarcodeWidths2()

      Input:  pixs (input image; 8 bpp)
              thresh (estimated pixel threshold for crossing
                      white <--> black; typ. ~120)
              &width (<optional return> best decoding window width, in pixels)
              &nac (<optional return> number of transitions in each window)
              debugflag (use 1 to generate debug output)
      Return: nad (numa of barcode widths in encoded integer units),
                  or null on error

  Notes:
      (1) The widths are alternating black/white, starting with black
          and ending with black.
      (2) The optional best decoding window width is the width of the window
          that is used to make a decision about whether a transition occurs.
          It is approximately the average width in pixels of the narrowest
          white and black bars (i.e., those corresponding to unit width).
      (3) The optional return signal @nac is a sequence of 0s, 1s,
          and perhaps a few 2s, giving the number of crossings in each window.
          On the occasion where there is a '2', it is interpreted as
          as ending two runs: the previous one and another one that has length 1.

=head2 pixExtractBarcodes

PIXA * pixExtractBarcodes ( PIX *pixs, l_int32 debugflag )

  pixExtractBarcodes()

      Input:  pixs (8 bpp, no colormap)
              debugflag (use 1 to generate debug output)
      Return: pixa (deskewed and cropped barcodes), or null if
                    none found or on error

=head2 pixLocateBarcodes

BOXA * pixLocateBarcodes ( PIX *pixs, l_int32 thresh, PIX **ppixb, PIX **ppixm )

  pixLocateBarcodes()

      Input:  pixs (any depth)
              thresh (for binarization of edge filter output; typ. 20)
              &pixb (<optional return> binarized edge filtered input image)
              &pixm (<optional return> mask over barcodes)
      Return: boxa (location of barcodes), or null if none found or on error

=head2 pixProcessBarcodes

SARRAY * pixProcessBarcodes ( PIX *pixs, l_int32 format, l_int32 method, SARRAY **psaw, l_int32 debugflag )

  pixProcessBarcodes()

      Input:  pixs (any depth)
              format (L_BF_ANY, L_BF_CODEI2OF5, L_BF_CODE93, ...)
              method (L_USE_WIDTHS, L_USE_WINDOWS)
              &saw (<optional return> sarray of bar widths)
              debugflag (use 1 to generate debug output)
      Return: sarray (text of barcodes), or null if none found or on error

=head2 pixReadBarcodeWidths

NUMA * pixReadBarcodeWidths ( PIX *pixs, l_int32 method, l_int32 debugflag )

  pixReadBarcodeWidths()

      Input:  pixs (of 8 bpp deskewed and cropped barcode)
              method (L_USE_WIDTHS, L_USE_WINDOWS);
              debugflag (use 1 to generate debug output)
      Return: na (numa of widths (each in set {1,2,3,4}), or null on error

=head2 pixReadBarcodes

SARRAY * pixReadBarcodes ( PIXA *pixa, l_int32 format, l_int32 method, SARRAY **psaw, l_int32 debugflag )

  pixReadBarcodes()

      Input:  pixa (of 8 bpp deskewed and cropped barcodes)
              format (L_BF_ANY, L_BF_CODEI2OF5, L_BF_CODE93, ...)
              method (L_USE_WIDTHS, L_USE_WINDOWS);
              &saw (<optional return> sarray of bar widths)
              debugflag (use 1 to generate debug output)
      Return: sa (sarray of widths, one string for each barcode found),
                  or null on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
