package Image::Leptonica::Func::rank;
$Image::Leptonica::Func::rank::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::rank

=head1 VERSION

version 0.04

=head1 C<rank.c>

  rank.c

      Rank filter (gray and rgb)
          PIX      *pixRankFilter()
          PIX      *pixRankFilterRGB()
          PIX      *pixRankFilterGray()

      Median filter
          PIX      *pixMedianFilter()

      Rank filter (accelerated with downscaling)
          PIX      *pixRankFilterWithScaling()

  What is a brick rank filter?

    A brick rank order filter evaluates, for every pixel in the image,
    a rectangular set of n = wf x hf pixels in its neighborhood (where the
    pixel in question is at the "center" of the rectangle and is
    included in the evaluation).  It determines the value of the
    neighboring pixel that is the r-th smallest in the set,
    where r is some integer between 1 and n.  The input rank parameter
    is a fraction between 0.0 and 1.0, where 0.0 represents the
    smallest value (r = 1) and 1.0 represents the largest value (r = n).
    A median filter is a rank filter where rank = 0.5.

    It is important to note that grayscale erosion is equivalent
    to rank = 0.0, and grayscale dilation is equivalent to rank = 1.0.
    These are much easier to calculate than the general rank value,
    thanks to the van Herk/Gil-Werman algorithm:
       http://www.leptonica.com/grayscale-morphology.html
    so you should use pixErodeGray() and pixDilateGray() for
    rank 0.0 and 1.0, rsp.  See notes below in the function header.

  How is a rank filter implemented efficiently on an image?

    Sorting will not work.

      * The best sort algorithms are O(n*logn), where n is the number
        of values to be sorted (the area of the filter).  For large
        filters this is an impractically large number.

      * Selection of the rank value is O(n).  (To understand why it's not
        O(n*logn), see Numerical Recipes in C, 2nd edition, 1992,  p. 355ff).
        This also still far too much computation for large filters.

      * Suppose we get clever.  We really only need to do an incremental
        selection or sorting, because, for example, moving the filter
        down by one pixel causes one filter width of pixels to be added
        and another to be removed.  Can we do this incrementally in
        an efficient way?  Unfortunately, no.  The sorted values will be
        in an array.  Even if the filter width is 1, we can expect to
        have to move O(n) pixels, because insertion and deletion can happen
        anywhere in the array.  By comparison, heapsort is excellent for
        incremental sorting, where the cost for insertion or deletion
        is O(logn), because the array itself doesn't need to
        be sorted into strictly increasing order.  However, heapsort
        only gives the max (or min) value, not the general rank value.

    This leaves histograms.

      * Represented as an array.  The problem with an array of 256
        bins is that, in general, a significant fraction of the
        entire histogram must be summed to find the rank value bin.
        Suppose the filter size is 5x5.  You spend most of your time
        adding zeroes.  Ouch!

      * Represented as a linked list.  This would overcome the
        summing-over-empty-bin problem, but you lose random access
        for insertions and deletions.  No way.

      * Two histogram solution.  Maintain two histograms with
        bin sizes of 1 and 16.  Proceed from coarse to fine.
        First locate the coarse bin for the given rank, of which
        there are only 16.  Then, in the 256 entry (fine) histogram,
        you need look at a maximum of 16 bins.  For each output
        pixel, the average number of bins summed over, both in the
        coarse and fine histograms, is thus 16.

  If someone has a better method, please let me know!

  The rank filtering operation is relatively expensive, compared to most
  of the other imaging operations.  The speed is only weakly dependent
  on the size of the rank filter.  On standard hardware, it runs at
  about 10 Mpix/sec for a 50 x 50 filter, and 25 Mpix/sec for
  a 5 x 5 filter.   For applications where the rank filter can be
  performed on a downscaled image, significant speedup can be
  achieved because the time goes as the square of the scaling factor.
  We provide an interface that handles the details, and only
  requires the amount of downscaling to be input.

=head1 FUNCTIONS

=head2 pixMedianFilter

PIX * pixMedianFilter ( PIX *pixs, l_int32 wf, l_int32 hf )

  pixMedianFilter()

      Input:  pixs (8 or 32 bpp; no colormap)
              wf, hf  (width and height of filter; each is >= 1)
      Return: pixd (of median values), or null on error

=head2 pixRankFilter

PIX * pixRankFilter ( PIX *pixs, l_int32 wf, l_int32 hf, l_float32 rank )

  pixRankFilter()

      Input:  pixs (8 or 32 bpp; no colormap)
              wf, hf  (width and height of filter; each is >= 1)
              rank (in [0.0 ... 1.0])
      Return: pixd (of rank values), or null on error

  Notes:
      (1) This defines, for each pixel in pixs, a neighborhood of
          pixels given by a rectangle "centered" on the pixel.
          This set of wf*hf pixels has a distribution of values.
          For each component, if the values are sorted in increasing
          order, we choose the component such that rank*(wf*hf-1)
          pixels have a lower or equal value and
          (1-rank)*(wf*hf-1) pixels have an equal or greater value.
      (2) See notes in pixRankFilterGray() for further details.

=head2 pixRankFilterGray

PIX * pixRankFilterGray ( PIX *pixs, l_int32 wf, l_int32 hf, l_float32 rank )

  pixRankFilterGray()

      Input:  pixs (8 bpp; no colormap)
              wf, hf  (width and height of filter; each is >= 1)
              rank (in [0.0 ... 1.0])
      Return: pixd (of rank values), or null on error

  Notes:
      (1) This defines, for each pixel in pixs, a neighborhood of
          pixels given by a rectangle "centered" on the pixel.
          This set of wf*hf pixels has a distribution of values,
          and if they are sorted in increasing order, we choose
          the pixel such that rank*(wf*hf-1) pixels have a lower
          or equal value and (1-rank)*(wf*hf-1) pixels have an equal
          or greater value.
      (2) By this definition, the rank = 0.0 pixel has the lowest
          value, and the rank = 1.0 pixel has the highest value.
      (3) We add mirrored boundary pixels to avoid boundary effects,
          and put the filter center at (0, 0).
      (4) This dispatches to grayscale erosion or dilation if the
          filter dimensions are odd and the rank is 0.0 or 1.0, rsp.
      (5) Returns a copy if both wf and hf are 1.
      (6) Uses row-major or column-major incremental updates to the
          histograms depending on whether hf > wf or hv <= wf, rsp.

=head2 pixRankFilterRGB

PIX * pixRankFilterRGB ( PIX *pixs, l_int32 wf, l_int32 hf, l_float32 rank )

  pixRankFilterRGB()

      Input:  pixs (32 bpp)
              wf, hf  (width and height of filter; each is >= 1)
              rank (in [0.0 ... 1.0])
      Return: pixd (of rank values), or null on error

  Notes:
      (1) This defines, for each pixel in pixs, a neighborhood of
          pixels given by a rectangle "centered" on the pixel.
          This set of wf*hf pixels has a distribution of values.
          For each component, if the values are sorted in increasing
          order, we choose the component such that rank*(wf*hf-1)
          pixels have a lower or equal value and
          (1-rank)*(wf*hf-1) pixels have an equal or greater value.
      (2) Apply gray rank filtering to each component independently.
      (3) See notes in pixRankFilterGray() for further details.

=head2 pixRankFilterWithScaling

PIX * pixRankFilterWithScaling ( PIX *pixs, l_int32 wf, l_int32 hf, l_float32 rank, l_float32 scalefactor )

  pixRankFilterWithScaling()

      Input:  pixs (8 or 32 bpp; no colormap)
              wf, hf  (width and height of filter; each is >= 1)
              rank (in [0.0 ... 1.0])
              scalefactor (scale factor; must be >= 0.2 and <= 0.7)
      Return: pixd (of rank values), or null on error

  Notes:
      (1) This is a convenience function that downscales, does
          the rank filtering, and upscales.  Because the down-
          and up-scaling functions are very fast compared to
          rank filtering, the time it takes is reduced from that
          for the simple rank filtering operation by approximately
          the square of the scaling factor.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
