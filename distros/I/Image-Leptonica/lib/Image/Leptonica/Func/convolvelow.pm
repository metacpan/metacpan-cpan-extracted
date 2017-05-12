package Image::Leptonica::Func::convolvelow;
$Image::Leptonica::Func::convolvelow::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::convolvelow

=head1 VERSION

version 0.04

=head1 C<convolvelow.c>

  convolvelow.c

      Grayscale block convolution
          void      blockconvLow()
          void      blockconvAccumLow()

      Binary block sum and rank filter
          void      blocksumLow()

=head1 FUNCTIONS

=head2 blockconvAccumLow

void blockconvAccumLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 wpld, l_uint32 *datas, l_int32 d, l_int32 wpls )

  blockconvAccumLow()

      Input:  datad  (32 bpp dest)
              w, h, wpld (of 32 bpp dest)
              datas (1, 8 or 32 bpp src)
              d (bpp of src)
              wpls (of src)
      Return: void

  Notes:
      (1) The general recursion relation is
             a(i,j) = v(i,j) + a(i-1, j) + a(i, j-1) - a(i-1, j-1)
          For the first line, this reduces to the special case
             a(i,j) = v(i,j) + a(i, j-1)
          For the first column, the special case is
             a(i,j) = v(i,j) + a(i-1, j)

=head2 blockconvLow

void blockconvLow ( l_uint32 *data, l_int32 w, l_int32 h, l_int32 wpl, l_uint32 *dataa, l_int32 wpla, l_int32 wc, l_int32 hc )

  blockconvLow()

      Input:  data   (data of input image, to be convolved)
              w, h, wpl
              dataa    (data of 32 bpp accumulator)
              wpla     (accumulator)
              wc      (convolution "half-width")
              hc      (convolution "half-height")
      Return: void

  Notes:
      (1) The full width and height of the convolution kernel
          are (2 * wc + 1) and (2 * hc + 1).
      (2) The lack of symmetry between the handling of the
          first (hc + 1) lines and the last (hc) lines,
          and similarly with the columns, is due to fact that
          for the pixel at (x,y), the accumulator values are
          taken at (x + wc, y + hc), (x - wc - 1, y + hc),
          (x + wc, y - hc - 1) and (x - wc - 1, y - hc - 1).
      (3) We compute sums, normalized as if there were no reduced
          area at the boundary.  This under-estimates the value
          of the boundary pixels, so we multiply them by another
          normalization factor that is greater than 1.
      (4) This second normalization is done first for the first
          hc + 1 lines; then for the last hc lines; and finally
          for the first wc + 1 and last wc columns in the intermediate
          lines.
      (5) The caller should verify that wc < w and hc < h.
          Under those conditions, illegal reads and writes can occur.
      (6) Implementation note: to get the same results in the interior
          between this function and pixConvolve(), it is necessary to
          add 0.5 for roundoff in the main loop that runs over all pixels.
          However, if we do that and have white (255) pixels near the
          image boundary, some overflow occurs for pixels very close
          to the boundary.  We can't fix this by subtracting from the
          normalized values for the boundary pixels, because this results
          in underflow if the boundary pixels are black (0).  Empirically,
          adding 0.25 (instead of 0.5) before truncating in the main
          loop will not cause overflow, but this gives some
          off-by-1-level errors in interior pixel values.  So we add
          0.5 for roundoff in the main loop, and for pixels within a
          half filter width of the boundary, use a L_MIN of the
          computed value and 255 to avoid overflow during normalization.

=head2 blocksumLow

void blocksumLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 wpl, l_uint32 *dataa, l_int32 wpla, l_int32 wc, l_int32 hc )

  blocksumLow()

      Input:  datad  (of 8 bpp dest)
              w, h, wpl  (of 8 bpp dest)
              dataa (of 32 bpp accum)
              wpla  (of 32 bpp accum)
              wc, hc  (convolution "half-width" and "half-height")
      Return: void

  Notes:
      (1) The full width and height of the convolution kernel
          are (2 * wc + 1) and (2 * hc + 1).
      (2) The lack of symmetry between the handling of the
          first (hc + 1) lines and the last (hc) lines,
          and similarly with the columns, is due to fact that
          for the pixel at (x,y), the accumulator values are
          taken at (x + wc, y + hc), (x - wc - 1, y + hc),
          (x + wc, y - hc - 1) and (x - wc - 1, y - hc - 1).
      (3) Compute sums of ON pixels within the block filter size,
          normalized between 0 and 255, as if there were no reduced
          area at the boundary.  This under-estimates the value
          of the boundary pixels, so we multiply them by another
          normalization factor that is greater than 1.
      (4) This second normalization is done first for the first
          hc + 1 lines; then for the last hc lines; and finally
          for the first wc + 1 and last wc columns in the intermediate
          lines.
      (5) The caller should verify that wc < w and hc < h.
          Under those conditions, illegal reads and writes can occur.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
