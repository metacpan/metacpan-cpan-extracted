package Image::Leptonica::Func::seedfilllow;
$Image::Leptonica::Func::seedfilllow::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::seedfilllow

=head1 VERSION

version 0.04

=head1 C<seedfilllow.c>

  seedfilllow.c

      Seedfill:
      Gray seedfill (source: Luc Vincent:fast-hybrid-grayscale-reconstruction)
               void   seedfillBinaryLow()
               void   seedfillGrayLow()
               void   seedfillGrayInvLow()
               void   seedfillGrayLowSimple()
               void   seedfillGrayInvLowSimple()

      Distance function:
               void   distanceFunctionLow()

      Seed spread:
               void   seedspreadLow()

=head1 FUNCTIONS

=head2 distanceFunctionLow

void distanceFunctionLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 d, l_int32 wpld, l_int32 connectivity )

  distanceFunctionLow()

=head2 seedfillBinaryLow

void seedfillBinaryLow ( l_uint32 *datas, l_int32 hs, l_int32 wpls, l_uint32 *datam, l_int32 hm, l_int32 wplm, l_int32 connectivity )

  seedfillBinaryLow()

  Notes:
      (1) This is an in-place fill, where the seed image is
          filled, clipping to the filling mask, in one full
          cycle of UL -> LR and LR -> UL raster scans.
      (2) Assume the mask is a filling mask, not a blocking mask.
      (3) Assume that the RHS pad bits of the mask
          are properly set to 0.
      (4) Clip to the smallest dimensions to avoid invalid reads.

=head2 seedfillGrayInvLow

void seedfillGrayInvLow ( l_uint32 *datas, l_int32 w, l_int32 h, l_int32 wpls, l_uint32 *datam, l_int32 wplm, l_int32 connectivity )

  seedfillGrayInvLow()

  Notes:
      (1) The pixels are numbered as follows:
              1  2  3
              4  x  5
              6  7  8
          This low-level filling operation consists of two scans,
          raster and anti-raster, covering the entire seed image.
          During the anti-raster scan, every pixel p such that its
          current value could still be propogated during the next
          raster scanning is put into the FIFO-queue.
          Next step is the propagation step where where we update
          and propagate the values using FIFO structure created in
          anti-raster scan.
      (2) The "Inv" signifies the fact that in this case, filling
          of the seed only takes place when the seed value is
          greater than the mask value.  The mask will act to stop
          the fill when it is higher than the seed level.  (This is
          in contrast to conventional grayscale filling where the
          seed always fills below the mask.)
      (3) An example of use is a basin, described by the mask (pixm),
          where within the basin, the seed pix (pixs) gets filled to the
          height of the highest seed pixel that is above its
          corresponding max pixel.  Filling occurs while the
          propagating seed pixels in pixs are larger than the
          corresponding mask values in pixm.
      (4) Reference paper :
            L. Vincent, Morphological grayscale reconstruction in image
            analysis: applications and efficient algorithms, IEEE Transactions
            on  Image Processing, vol. 2, no. 2, pp. 176-201, 1993.

=head2 seedfillGrayInvLowSimple

void seedfillGrayInvLowSimple ( l_uint32 *datas, l_int32 w, l_int32 h, l_int32 wpls, l_uint32 *datam, l_int32 wplm, l_int32 connectivity )

  seedfillGrayInvLowSimple()

  Notes:
      (1) The pixels are numbered as follows:
              1  2  3
              4  x  5
              6  7  8
          This low-level filling operation consists of two scans,
          raster and anti-raster, covering the entire seed image.
          The caller typically iterates until the filling is
          complete.
      (2) The "Inv" signifies the fact that in this case, filling
          of the seed only takes place when the seed value is
          greater than the mask value.  The mask will act to stop
          the fill when it is higher than the seed level.  (This is
          in contrast to conventional grayscale filling where the
          seed always fills below the mask.)
      (3) An example of use is a basin, described by the mask (pixm),
          where within the basin, the seed pix (pixs) gets filled to the
          height of the highest seed pixel that is above its
          corresponding max pixel.  Filling occurs while the
          propagating seed pixels in pixs are larger than the
          corresponding mask values in pixm.

=head2 seedfillGrayLow

void seedfillGrayLow ( l_uint32 *datas, l_int32 w, l_int32 h, l_int32 wpls, l_uint32 *datam, l_int32 wplm, l_int32 connectivity )

  seedfillGrayLow()

  Notes:
      (1) The pixels are numbered as follows:
              1  2  3
              4  x  5
              6  7  8
          This low-level filling operation consists of two scans,
          raster and anti-raster, covering the entire seed image.
          This is followed by a breadth-first propagation operation to
          complete the fill.
          During the anti-raster scan, every pixel p whose current value
          could still be propagated after the anti-raster scan is put into
          the FIFO queue.
          The propagation step is a breadth-first fill to completion.
          Unlike the simple grayscale seedfill pixSeedfillGraySimple(),
          where at least two full raster/anti-raster iterations are required
          for completion and verification, the hybrid method uses only a
          single raster/anti-raster set of scans.
      (2) The filling action can be visualized from the following example.
          Suppose the mask, which clips the fill, is a sombrero-shaped
          surface, where the highest point is 200 and the low pixels
          around the rim are 30.  Beyond the rim, the mask goes up a bit.
          Suppose the seed, which is filled, consists of a single point
          of height 150, located below the max of the mask, with
          the rest 0.  Then in the raster scan, nothing happens until
          the high seed point is encountered, and then this value is
          propagated right and down, until it hits the side of the
          sombrero.   The seed can never exceed the mask, so it fills
          to the rim, going lower along the mask surface.  When it
          passes the rim, the seed continues to fill at the rim
          height to the edge of the seed image.  Then on the
          anti-raster scan, the seed fills flat inside the
          sombrero to the upper and left, and then out from the
          rim as before.  The final result has a seed that is
          flat outside the rim, and inside it fills the sombrero
          but only up to 150.  If the rim height varies, the
          filled seed outside the rim will be at the highest
          point on the rim, which is a saddle point on the rim.
      (3) Reference paper :
            L. Vincent, Morphological grayscale reconstruction in image
            analysis: applications and efficient algorithms, IEEE Transactions
            on  Image Processing, vol. 2, no. 2, pp. 176-201, 1993.

=head2 seedfillGrayLowSimple

void seedfillGrayLowSimple ( l_uint32 *datas, l_int32 w, l_int32 h, l_int32 wpls, l_uint32 *datam, l_int32 wplm, l_int32 connectivity )

  seedfillGrayLowSimple()

  Notes:
      (1) The pixels are numbered as follows:
              1  2  3
              4  x  5
              6  7  8
          This low-level filling operation consists of two scans,
          raster and anti-raster, covering the entire seed image.
          The caller typically iterates until the filling is
          complete.
      (2) The filling action can be visualized from the following example.
          Suppose the mask, which clips the fill, is a sombrero-shaped
          surface, where the highest point is 200 and the low pixels
          around the rim are 30.  Beyond the rim, the mask goes up a bit.
          Suppose the seed, which is filled, consists of a single point
          of height 150, located below the max of the mask, with
          the rest 0.  Then in the raster scan, nothing happens until
          the high seed point is encountered, and then this value is
          propagated right and down, until it hits the side of the
          sombrero.   The seed can never exceed the mask, so it fills
          to the rim, going lower along the mask surface.  When it
          passes the rim, the seed continues to fill at the rim
          height to the edge of the seed image.  Then on the
          anti-raster scan, the seed fills flat inside the
          sombrero to the upper and left, and then out from the
          rim as before.  The final result has a seed that is
          flat outside the rim, and inside it fills the sombrero
          but only up to 150.  If the rim height varies, the
          filled seed outside the rim will be at the highest
          point on the rim, which is a saddle point on the rim.

=head2 seedspreadLow

void seedspreadLow ( l_uint32 *datad, l_int32 w, l_int32 h, l_int32 wpld, l_uint32 *datat, l_int32 wplt, l_int32 connectivity )

  seedspreadLow()

    See pixSeedspread() for a brief description of the algorithm here.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
