package Image::Leptonica::Func::graymorphlow;
$Image::Leptonica::Func::graymorphlow::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::graymorphlow

=head1 VERSION

version 0.04

=head1 C<graymorphlow.c>

  graymorphlow.c

      Low-level grayscale morphological operations

            void     dilateGrayLow()
            void     erodeGrayLow()


      We use the van Herk/Gil-Werman (vHGW) algorithm, [van Herk,
      Patt. Recog. Let. 13, pp. 517-521, 1992; Gil and Werman,
      IEEE Trans PAMI 15(5), pp. 504-507, 1993.]
      This was the first grayscale morphology
      algorithm to compute dilation and erosion with
      complexity independent of the size of the structuring
      element.  It is simple and elegant, and surprising that
      it was discovered as recently as 1992.  It works for
      SEs composed of horizontal and/or vertical lines.  The
      general case requires finding the Min or Max over an
      arbitrary set of pixels, and this requires a number of
      pixel comparisons equal to the SE "size" at each pixel
      in the image.  The vHGW algorithm requires not
      more than 3 comparisons at each point.  The algorithm has been
      recently refined by Gil and Kimmel ("Efficient Dilation
      Erosion, Opening and Closing Algorithms", in "Mathematical
      Morphology and its Applications to Image and Signal Processing",
      the proceedings of the International Symposium on Mathematical
      Morphology, Palo Alto, CA, June 2000, Kluwer Academic
      Publishers, pp. 301-310).  They bring this number down below
      1.5 comparisons per output pixel but at a cost of significantly
      increased complexity, so I don't bother with that here.

      In brief, the method is as follows.  We evaluate the dilation
      in groups of "size" pixels, equal to the size of the SE.
      For horizontal, we start at x = "size"/2 and go
      (w - 2 * ("size"/2))/"size" steps.  This means that
      we don't evaluate the first 0.5 * "size" pixels and, worst
      case, the last 1.5 * "size" pixels.  Thus we embed the
      image in a larger image with these augmented dimensions, where
      the new border pixels are appropriately initialized (0 for
      dilation; 255 for erosion), and remove the boundary at the end.
      (For vertical, use h instead of w.)   Then for each group
      of "size" pixels, we form an array of length 2 * "size" + 1,
      consisting of backward and forward partial maxima (for
      dilation) or minima (for erosion).  This represents a
      jumping window computed from the source image, over which
      the SE will slide.  The center of the array gets the source
      pixel at the center of the SE.  Call this the center pixel
      of the window.  Array values to left of center get
      the maxima(minima) of the pixels from the center
      one and going to the left an equal distance.  Array
      values to the right of center get the maxima(minima) to
      the pixels from the center one and going to the right
      an equal distance.  These are computed sequentially starting
      from the center one.  The SE (of length "size") can slide over this
      window (of length 2 * "size + 1) at "size" different places.
      At each place, the maxima(minima) of the values in the window
      that correspond to the end points of the SE give the extremal
      values over that interval, and these are stored at the dest
      pixel corresponding to the SE center.  A picture is worth
      at least this many words, so if this isn't clear, see the
      leptonica documentation on grayscale morphology.

=head1 FUNCTIONS

=head2 dilateGrayLow

void dilateGrayLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_int32 size, l_int32 direction, l_uint8 *buffer, l_uint8 *maxarray )

  dilateGrayLow()

    Input:  datad, w, h, wpld (8 bpp image)
            datas, wpls  (8 bpp image, of same dimensions)
            size  (full length of SEL; restricted to odd numbers)
            direction  (L_HORIZ or L_VERT)
            buffer  (holds full line or column of src image pixels)
            maxarray  (array of dimension 2*size+1)
    Return: void

    Notes:
        (1) To eliminate border effects on the actual image, these images
            are prepared with an additional border of dimensions:
               leftpix = 0.5 * size
               rightpix = 1.5 * size
               toppix = 0.5 * size
               bottompix = 1.5 * size
            and we initialize the src border pixels to 0.
            This allows full processing over the actual image; at
            the end the border is removed.
        (2) Uses algorithm of van Herk, Gil and Werman

=head2 erodeGrayLow

void erodeGrayLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 wpld, l_uint32 *datas, l_int32 wpls, l_int32 size, l_int32 direction, l_uint8 *buffer, l_uint8 *minarray )

  erodeGrayLow()

    Input:  datad, w, h, wpld (8 bpp image)
            datas, wpls  (8 bpp image, of same dimensions)
            size  (full length of SEL; restricted to odd numbers)
            direction  (L_HORIZ or L_VERT)
            buffer  (holds full line or column of src image pixels)
            minarray  (array of dimension 2*size+1)
    Return: void

    Notes:
        (1) See notes in dilateGrayLow()

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
