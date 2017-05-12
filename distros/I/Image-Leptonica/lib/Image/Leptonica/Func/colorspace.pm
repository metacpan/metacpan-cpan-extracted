package Image::Leptonica::Func::colorspace;
$Image::Leptonica::Func::colorspace::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::colorspace

=head1 VERSION

version 0.04

=head1 C<colorspace.c>

  colorspace.c

      Colorspace conversion between RGB and HSV
           PIX        *pixConvertRGBToHSV()
           PIX        *pixConvertHSVToRGB()
           l_int32     convertRGBToHSV()
           l_int32     convertHSVToRGB()
           l_int32     pixcmapConvertRGBToHSV()
           l_int32     pixcmapConvertHSVToRGB()
           PIX        *pixConvertRGBToHue()
           PIX        *pixConvertRGBToSaturation()
           PIX        *pixConvertRGBToValue()

      Selection and display of range of colors in HSV space
           PIX        *pixMakeRangeMaskHS()
           PIX        *pixMakeRangeMaskHV()
           PIX        *pixMakeRangeMaskSV()
           PIX        *pixMakeHistoHS()
           PIX        *pixMakeHistoHV()
           PIX        *pixMakeHistoSV()
           PIX        *pixFindHistoPeaksHSV()
           PIX        *displayHSVColorRange()

      Colorspace conversion between RGB and YUV
           PIX        *pixConvertRGBToYUV()
           PIX        *pixConvertYUVToRGB()
           l_int32     convertRGBToYUV()
           l_int32     convertYUVToRGB()
           l_int32     pixcmapConvertRGBToYUV()
           l_int32     pixcmapConvertYUVToRGB()

=head1 FUNCTIONS

=head2 convertHSVToRGB

l_int32 convertHSVToRGB ( l_int32 hval, l_int32 sval, l_int32 vval, l_int32 *prval, l_int32 *pgval, l_int32 *pbval )

  convertHSVToRGB()

      Input:  hval, sval, vval
              &rval, &gval, &bval (<return> RGB values)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See convertRGBToHSV() for valid input range of HSV values
          and their interpretation in color space.

=head2 convertRGBToHSV

l_int32 convertRGBToHSV ( l_int32 rval, l_int32 gval, l_int32 bval, l_int32 *phval, l_int32 *psval, l_int32 *pvval )

  convertRGBToHSV()

      Input:  rval, gval, bval (RGB input)
              &hval, &sval, &vval (<return> HSV values)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The range of returned values is:
            h [0 ... 239]
            s [0 ... 255]
            v [0 ... 255]
      (2) If r = g = b, the pixel is gray (s = 0), and we define h = 0.
      (3) h wraps around, so that h = 0 and h = 240 are equivalent
          in hue space.
      (4) h has the following correspondence to color:
            h = 0         magenta
            h = 40        red
            h = 80        yellow
            h = 120       green
            h = 160       cyan
            h = 200       blue

=head2 convertRGBToYUV

l_int32 convertRGBToYUV ( l_int32 rval, l_int32 gval, l_int32 bval, l_int32 *pyval, l_int32 *puval, l_int32 *pvval )

  convertRGBToYUV()

      Input:  rval, gval, bval (RGB input)
              &yval, &uval, &vval (<return> YUV values)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The range of returned values is:
            Y [16 ... 235]
            U [16 ... 240]
            V [16 ... 240]

=head2 convertYUVToRGB

l_int32 convertYUVToRGB ( l_int32 yval, l_int32 uval, l_int32 vval, l_int32 *prval, l_int32 *pgval, l_int32 *pbval )

  convertYUVToRGB()

      Input:  yval, uval, vval
              &rval, &gval, &bval (<return> RGB values)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The range of valid input values is:
            Y [16 ... 235]
            U [16 ... 240]
            V [16 ... 240]
      (2) Conversion of RGB --> YUV --> RGB leaves the image unchanged.
      (3) The YUV gamut is larger than the RBG gamut; many YUV values
          will result in an invalid RGB value.  We clip individual
          r,g,b components to the range [0, 255], and do not test input.

=head2 displayHSVColorRange

PIX * displayHSVColorRange ( l_int32 hval, l_int32 sval, l_int32 vval, l_int32 huehw, l_int32 sathw, l_int32 nsamp, l_int32 factor )

  displayHSVColorRange()

      Input:  hval (hue center value; in range [0 ... 240]
              sval (saturation center value; in range [0 ... 255]
              vval (max intensity value; in range [0 ... 255]
              huehw (half-width of hue range; > 0)
              sathw (half-width of saturation range; > 0)
              nsamp (number of samplings in each half-width in hue and sat)
              factor (linear size of each color square, in pixels; > 3)
      Return: pixd (32 bpp set of color squares over input range),
                     or null on error

  Notes:
      (1) The total number of color samplings in each of the hue
          and saturation directions is 2 * nsamp + 1.

=head2 pixConvertHSVToRGB

PIX * pixConvertHSVToRGB ( PIX *pixd, PIX *pixs )

  pixConvertHSVToRGB()

      Input:  pixd (can be NULL; if not NULL, must == pixs)
              pixs
      Return: pixd always

  Notes:
      (1) For pixs = pixd, this is in-place; otherwise pixd must be NULL.
      (2) The user takes responsibility for making sure that pixs is
          in our HSV space.  The definition of our HSV space is given
          in convertRGBToHSV().
      (3) The h, s and v values are stored in the same places as
          the r, g and b values, respectively.  Here, they are explicitly
          placed in the 3 MS bytes in the pixel.

=head2 pixConvertRGBToHSV

PIX * pixConvertRGBToHSV ( PIX *pixd, PIX *pixs )

  pixConvertRGBToHSV()

      Input:  pixd (can be NULL; if not NULL, must == pixs)
              pixs
      Return: pixd always

  Notes:
      (1) For pixs = pixd, this is in-place; otherwise pixd must be NULL.
      (2) The definition of our HSV space is given in convertRGBToHSV().
      (3) The h, s and v values are stored in the same places as
          the r, g and b values, respectively.  Here, they are explicitly
          placed in the 3 MS bytes in the pixel.
      (4) Normalizing to 1 and considering the r,g,b components,
          a simple way to understand the HSV space is:
           - v = max(r,g,b)
           - s = (max - min) / max
           - h ~ (mid - min) / (max - min)  [apart from signs and constants]
      (5) Normalizing to 1, some properties of the HSV space are:
           - For gray values (r = g = b) along the continuum between
             black and white:
                s = 0  (becoming undefined as you approach black)
                h is undefined everywhere
           - Where one component is saturated and the others are zero:
                v = 1
                s = 1
                h = 0 (r = max), 1/3 (g = max), 2/3 (b = max)
           - Where two components are saturated and the other is zero:
                v = 1
                s = 1
                h = 1/2 (if r = 0), 5/6 (if g = 0), 1/6 (if b = 0)

=head2 pixConvertRGBToHue

PIX * pixConvertRGBToHue ( PIX *pixs )

  pixConvertRGBToHue()

      Input:  pixs (32 bpp RGB or 8 bpp with colormap)
      Return: pixd (8 bpp hue of HSV), or null on error

  Notes:
      (1) The conversion to HSV hue is in-lined here.
      (2) If there is a colormap, it is removed.
      (3) If you just want the hue component, this does it
          at about 10 Mpixels/sec/GHz, which is about
          2x faster than using pixConvertRGBToHSV()

=head2 pixConvertRGBToSaturation

PIX * pixConvertRGBToSaturation ( PIX *pixs )

  pixConvertRGBToSaturation()

      Input:  pixs (32 bpp RGB or 8 bpp with colormap)
      Return: pixd (8 bpp sat of HSV), or null on error

  Notes:
      (1) The conversion to HSV sat is in-lined here.
      (2) If there is a colormap, it is removed.
      (3) If you just want the saturation component, this does it
          at about 12 Mpixels/sec/GHz.

=head2 pixConvertRGBToValue

PIX * pixConvertRGBToValue ( PIX *pixs )

  pixConvertRGBToValue()

      Input:  pixs (32 bpp RGB or 8 bpp with colormap)
      Return: pixd (8 bpp max component intensity of HSV), or null on error

  Notes:
      (1) The conversion to HSV sat is in-lined here.
      (2) If there is a colormap, it is removed.
      (3) If you just want the value component, this does it
          at about 35 Mpixels/sec/GHz.

=head2 pixConvertRGBToYUV

PIX * pixConvertRGBToYUV ( PIX *pixd, PIX *pixs )

  pixConvertRGBToYUV()

      Input:  pixd (can be NULL; if not NULL, must == pixs)
              pixs
      Return: pixd always

  Notes:
      (1) For pixs = pixd, this is in-place; otherwise pixd must be NULL.
      (2) The Y, U and V values are stored in the same places as
          the r, g and b values, respectively.  Here, they are explicitly
          placed in the 3 MS bytes in the pixel.
      (3) Normalizing to 1 and considering the r,g,b components,
          a simple way to understand the YUV space is:
           - Y = weighted sum of (r,g,b)
           - U = weighted difference between Y and B
           - V = weighted difference between Y and R
      (4) Following video conventions, Y, U and V are in the range:
             Y: [16, 235]
             U: [16, 240]
             V: [16, 240]
      (5) For the coefficients in the transform matrices, see eq. 4 in
          "Frequently Asked Questions about Color" by Charles Poynton,
          http://www.poynton.com/notes/colour_and_gamma/ColorFAQ.html

=head2 pixConvertYUVToRGB

PIX * pixConvertYUVToRGB ( PIX *pixd, PIX *pixs )

  pixConvertYUVToRGB()

      Input:  pixd (can be NULL; if not NULL, must == pixs)
              pixs
      Return: pixd always

  Notes:
      (1) For pixs = pixd, this is in-place; otherwise pixd must be NULL.
      (2) The user takes responsibility for making sure that pixs is
          in YUV space.
      (3) The Y, U and V values are stored in the same places as
          the r, g and b values, respectively.  Here, they are explicitly
          placed in the 3 MS bytes in the pixel.

=head2 pixFindHistoPeaksHSV

l_int32 pixFindHistoPeaksHSV ( PIX *pixs, l_int32 type, l_int32 width, l_int32 height, l_int32 npeaks, l_float32 erasefactor, PTA **ppta, NUMA **pnatot, PIXA **ppixa )

  pixFindHistoPeaksHSV()

      Input:  pixs (32 bpp; HS, HV or SV histogram; not changed)
              type (L_HS_HISTO, L_HV_HISTO or L_SV_HISTO)
              width (half width of sliding window)
              height (half height of sliding window)
              npeaks (number of peaks to look for)
              erasefactor (ratio of erase window size to sliding window size)
              &pta (locations of maximum for each integrated peak area)
              &natot (integrated peak areas)
              &pixa (<optional return> pixa for debugging; NULL to skip)
      Return: 0 if OK, 1 on error

  Notes:
      (1) pixs is a 32 bpp histogram in a pair of HSV colorspace.  It
          should be thought of as a single sample with 32 bps (bits/sample).
      (2) After each peak is found, the peak is erased with a window
          that is centered on the peak and scaled from the sliding
          window by @erasefactor.  Typically, @erasefactor is chosen
          to be > 1.0.
      (3) Data for a maximum of @npeaks is returned in @pta and @natot.
      (4) For debugging, after the pixa is returned, display with:
          pixd = pixaDisplayTiledInRows(pixa, 32, 1000, 1.0, 0, 30, 2);

=head2 pixMakeHistoHS

PIX * pixMakeHistoHS ( PIX *pixs, l_int32 factor, NUMA **pnahue, NUMA **pnasat )

  pixMakeHistoHS()

      Input:  pixs  (HSV colorspace)
              factor (subsampling factor; integer)
              &nahue (<optional return> hue histogram)
              &nasat (<optional return> saturation histogram)
      Return: pixd (32 bpp histogram in hue and saturation), or null on error

  Notes:
      (1) pixs is a 32 bpp image in HSV colorspace; hue is in the "red"
          byte, saturation is in the "green" byte.
      (2) In pixd, hue is displayed vertically; saturation horizontally.
          The dimensions of pixd are w = 256, h = 240, and the depth
          is 32 bpp.  The value at each point is simply the number
          of pixels found at that value of hue and saturation.

=head2 pixMakeHistoHV

PIX * pixMakeHistoHV ( PIX *pixs, l_int32 factor, NUMA **pnahue, NUMA **pnaval )

  pixMakeHistoHV()

      Input:  pixs  (HSV colorspace)
              factor (subsampling factor; integer)
              &nahue (<optional return> hue histogram)
              &naval (<optional return> max intensity (value) histogram)
      Return: pixd (32 bpp histogram in hue and value), or null on error

  Notes:
      (1) pixs is a 32 bpp image in HSV colorspace; hue is in the "red"
          byte, max intensity ("value") is in the "blue" byte.
      (2) In pixd, hue is displayed vertically; intensity horizontally.
          The dimensions of pixd are w = 256, h = 240, and the depth
          is 32 bpp.  The value at each point is simply the number
          of pixels found at that value of hue and intensity.

=head2 pixMakeHistoSV

PIX * pixMakeHistoSV ( PIX *pixs, l_int32 factor, NUMA **pnasat, NUMA **pnaval )

  pixMakeHistoSV()

      Input:  pixs  (HSV colorspace)
              factor (subsampling factor; integer)
              &nasat (<optional return> sat histogram)
              &naval (<optional return> max intensity (value) histogram)
      Return: pixd (32 bpp histogram in sat and value), or null on error

  Notes:
      (1) pixs is a 32 bpp image in HSV colorspace; sat is in the "green"
          byte, max intensity ("value") is in the "blue" byte.
      (2) In pixd, sat is displayed vertically; intensity horizontally.
          The dimensions of pixd are w = 256, h = 256, and the depth
          is 32 bpp.  The value at each point is simply the number
          of pixels found at that value of saturation and intensity.

=head2 pixMakeRangeMaskHS

PIX * pixMakeRangeMaskHS ( PIX *pixs, l_int32 huecenter, l_int32 huehw, l_int32 satcenter, l_int32 sathw, l_int32 regionflag )

  pixMakeRangeMaskHS()

      Input:  pixs  (32 bpp rgb)
              huecenter (center value of hue range)
              huehw (half-width of hue range)
              satcenter (center value of saturation range)
              sathw (half-width of saturation range)
              regionflag (L_INCLUDE_REGION, L_EXCLUDE_REGION)
      Return: pixd (1 bpp mask over selected pixels), or null on error

  Notes:
      (1) The pixels are selected based on the specified ranges of
          hue and saturation.  For selection or exclusion, the pixel
          HS component values must be within both ranges.  Care must
          be taken in finding the hue range because of wrap-around.
      (2) Use @regionflag == L_INCLUDE_REGION to take only those
          pixels within the rectangular region specified in HS space.
          Use @regionflag == L_EXCLUDE_REGION to take all pixels except
          those within the rectangular region specified in HS space.

=head2 pixMakeRangeMaskHV

PIX * pixMakeRangeMaskHV ( PIX *pixs, l_int32 huecenter, l_int32 huehw, l_int32 valcenter, l_int32 valhw, l_int32 regionflag )

  pixMakeRangeMaskHV()

      Input:  pixs  (32 bpp rgb)
              huecenter (center value of hue range)
              huehw (half-width of hue range)
              valcenter (center value of max intensity range)
              valhw (half-width of max intensity range)
              regionflag (L_INCLUDE_REGION, L_EXCLUDE_REGION)
      Return: pixd (1 bpp mask over selected pixels), or null on error

  Notes:
      (1) The pixels are selected based on the specified ranges of
          hue and max intensity values.  For selection or exclusion,
          the pixel HV component values must be within both ranges.
          Care must be taken in finding the hue range because of wrap-around.
      (2) Use @regionflag == L_INCLUDE_REGION to take only those
          pixels within the rectangular region specified in HV space.
          Use @regionflag == L_EXCLUDE_REGION to take all pixels except
          those within the rectangular region specified in HV space.

=head2 pixMakeRangeMaskSV

PIX * pixMakeRangeMaskSV ( PIX *pixs, l_int32 satcenter, l_int32 sathw, l_int32 valcenter, l_int32 valhw, l_int32 regionflag )

  pixMakeRangeMaskSV()

      Input:  pixs  (32 bpp rgb)
              satcenter (center value of saturation range)
              sathw (half-width of saturation range)
              valcenter (center value of max intensity range)
              valhw (half-width of max intensity range)
              regionflag (L_INCLUDE_REGION, L_EXCLUDE_REGION)
      Return: pixd (1 bpp mask over selected pixels), or null on error

  Notes:
      (1) The pixels are selected based on the specified ranges of
          saturation and max intensity (val).  For selection or
          exclusion, the pixel SV component values must be within both ranges.
      (2) Use @regionflag == L_INCLUDE_REGION to take only those
          pixels within the rectangular region specified in SV space.
          Use @regionflag == L_EXCLUDE_REGION to take all pixels except
          those within the rectangular region specified in SV space.

=head2 pixcmapConvertHSVToRGB

l_int32 pixcmapConvertHSVToRGB ( PIXCMAP *cmap )

  pixcmapConvertHSVToRGB()

      Input:  colormap
      Return: 0 if OK; 1 on error

  Notes:
      - in-place transform
      - See convertRGBToHSV() for def'n of HSV space.
      - replaces: h --> r, s --> g, v --> b

=head2 pixcmapConvertRGBToHSV

l_int32 pixcmapConvertRGBToHSV ( PIXCMAP *cmap )

  pixcmapConvertRGBToHSV()

      Input:  colormap
      Return: 0 if OK; 1 on error

  Notes:
      - in-place transform
      - See convertRGBToHSV() for def'n of HSV space.
      - replaces: r --> h, g --> s, b --> v

=head2 pixcmapConvertRGBToYUV

l_int32 pixcmapConvertRGBToYUV ( PIXCMAP *cmap )

  pixcmapConvertRGBToYUV()

      Input:  colormap
      Return: 0 if OK; 1 on error

  Notes:
      - in-place transform
      - See convertRGBToYUV() for def'n of YUV space.
      - replaces: r --> y, g --> u, b --> v

=head2 pixcmapConvertYUVToRGB

l_int32 pixcmapConvertYUVToRGB ( PIXCMAP *cmap )

  pixcmapConvertYUVToRGB()

      Input:  colormap
      Return: 0 if OK; 1 on error

  Notes:
      - in-place transform
      - See convertRGBToYUV() for def'n of YUV space.
      - replaces: y --> r, u --> g, v --> b

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
