package Image::Leptonica::Func::pixconv;
$Image::Leptonica::Func::pixconv::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pixconv

=head1 VERSION

version 0.04

=head1 C<pixconv.c>

  pixconv.c

      These functions convert between images of different types
      without scaling.

      Conversion from 8 bpp grayscale to 1, 2, 4 and 8 bpp
           PIX        *pixThreshold8()

      Conversion from colormap to full color or grayscale
           PIX        *pixRemoveColormapGeneral()
           PIX        *pixRemoveColormap()

      Add colormap losslessly (8 to 8)
           l_int32     pixAddGrayColormap8()
           PIX        *pixAddMinimalGrayColormap8()

      Conversion from RGB color to grayscale
           PIX        *pixConvertRGBToLuminance()
           PIX        *pixConvertRGBToGray()
           PIX        *pixConvertRGBToGrayFast()
           PIX        *pixConvertRGBToGrayMinMax()
           PIX        *pixConvertRGBToGraySatBoost()

      Conversion from grayscale to colormap
           PIX        *pixConvertGrayToColormap()  -- 2, 4, 8 bpp
           PIX        *pixConvertGrayToColormap8()  -- 8 bpp only

      Colorizing conversion from grayscale to color
           PIX        *pixColorizeGray()  -- 8 bpp or cmapped

      Conversion from RGB color to colormap
           PIX        *pixConvertRGBToColormap()

      Quantization for relatively small number of colors in source
           l_int32     pixQuantizeIfFewColors()

      Conversion from 16 bpp to 8 bpp
           PIX        *pixConvert16To8()

      Conversion from grayscale to false color
           PIX        *pixConvertGrayToFalseColor()

      Unpacking conversion from 1 bpp to 2, 4, 8, 16 and 32 bpp
           PIX        *pixUnpackBinary()
           PIX        *pixConvert1To16()
           PIX        *pixConvert1To32()

      Unpacking conversion from 1 bpp to 2 bpp
           PIX        *pixConvert1To2Cmap()
           PIX        *pixConvert1To2()

      Unpacking conversion from 1 bpp to 4 bpp
           PIX        *pixConvert1To4Cmap()
           PIX        *pixConvert1To4()

      Unpacking conversion from 1, 2 and 4 bpp to 8 bpp
           PIX        *pixConvert1To8()
           PIX        *pixConvert2To8()
           PIX        *pixConvert4To8()

      Unpacking conversion from 8 bpp to 16 bpp
           PIX        *pixConvert8To16()

      Top-level conversion to 1 bpp
           PIX        *pixConvertTo1()
           PIX        *pixConvertTo1BySampling()

      Top-level conversion to 8 bpp
           PIX        *pixConvertTo8()
           PIX        *pixConvertTo8BySampling()
           PIX        *pixConvertTo8Color()

      Top-level conversion to 16 bpp
           PIX        *pixConvertTo16()

      Top-level conversion to 32 bpp (RGB)
           PIX        *pixConvertTo32()   ***
           PIX        *pixConvertTo32BySampling()   ***
           PIX        *pixConvert8To32()  ***

      Top-level conversion to 8 or 32 bpp, without colormap
           PIX        *pixConvertTo8Or32

      Conversion between 24 bpp and 32 bpp rgb
           PIX        *pixConvert24To32()
           PIX        *pixConvert32To24()

      Removal of alpha component by blending with white background
           PIX        *pixRemoveAlpha()

      Lossless depth conversion (unpacking)
           PIX        *pixConvertLossless()

      Conversion for printing in PostScript
           PIX        *pixConvertForPSWrap()

      Scaling conversion to subpixel RGB
           PIX        *pixConvertToSubpixelRGB()
           PIX        *pixConvertGrayToSubpixelRGB()
           PIX        *pixConvertColorToSubpixelRGB()

      *** indicates implicit assumption about RGB component ordering

=head1 FUNCTIONS

=head2 pixAddGrayColormap8

l_int32 pixAddGrayColormap8 ( PIX *pixs )

  pixAddGrayColormap8()

      Input:  pixs (8 bpp)
      Return: 0 if OK, 1 on error

  Notes:
      (1) If pixs has a colormap, this is a no-op.

=head2 pixAddMinimalGrayColormap8

PIX * pixAddMinimalGrayColormap8 ( PIX *pixs )

  pixAddMinimalGrayColormap8()

      Input:  pixs (8 bpp)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This generates a colormapped version of the input image
          that has the same number of colormap entries as the
          input image has unique gray levels.

=head2 pixColorizeGray

PIX * pixColorizeGray ( PIX *pixs, l_uint32 color, l_int32 cmapflag )

  pixColorizeGray()

      Input:  pixs (8 bpp gray; 2, 4 or 8 bpp colormapped)
              color (32 bit rgba pixel)
              cmapflag (1 for result to have colormap; 0 for RGB)
      Return: pixd (8 bpp colormapped or 32 bpp rgb), or null on error

  Notes:
      (1) This applies the specific color to the grayscale image.
      (2) If pixs already has a colormap, it is removed to gray
          before colorizing.

=head2 pixConvert16To8

PIX * pixConvert16To8 ( PIX *pixs, l_int32 type )

  pixConvert16To8()

      Input:  pixs (16 bpp)
              type (L_LS_BYTE, L_MS_BYTE, L_CLIP_TO_255)
      Return: pixd (8 bpp), or null on error

  Notes:
      (1) For each dest pixel, use either the LSB, the MSB, or the
          min(val, 255) for each 16-bit src pixel.

=head2 pixConvert1To16

PIX * pixConvert1To16 ( PIX *pixd, PIX *pixs, l_uint16 val0, l_uint16 val1 )

  pixConvert1To16()

      Input:  pixd (<optional> 16 bpp, can be null)
              pixs (1 bpp)
              val0 (16 bit value to be used for 0s in pixs)
              val1 (16 bit value to be used for 1s in pixs)
      Return: pixd (16 bpp)

  Notes:
      (1) If pixd is null, a new pix is made.
      (2) If pixd is not null, it must be of equal width and height
          as pixs.  It is always returned.

=head2 pixConvert1To2

PIX * pixConvert1To2 ( PIX *pixd, PIX *pixs, l_int32 val0, l_int32 val1 )

  pixConvert1To2()

      Input:  pixd (<optional> 2 bpp, can be null)
              pixs (1 bpp)
              val0 (2 bit value to be used for 0s in pixs)
              val1 (2 bit value to be used for 1s in pixs)
      Return: pixd (2 bpp)

  Notes:
      (1) If pixd is null, a new pix is made.
      (2) If pixd is not null, it must be of equal width and height
          as pixs.  It is always returned.
      (3) A simple unpacking might use val0 = 0 and val1 = 3.
      (4) If you want a colormapped pixd, use pixConvert1To2Cmap().

=head2 pixConvert1To2Cmap

PIX * pixConvert1To2Cmap ( PIX *pixs )

  pixConvert1To2Cmap()

      Input:  pixs (1 bpp)
      Return: pixd (2 bpp, cmapped)

  Notes:
      (1) Input 0 is mapped to (255, 255, 255); 1 is mapped to (0, 0, 0)

=head2 pixConvert1To32

PIX * pixConvert1To32 ( PIX *pixd, PIX *pixs, l_uint32 val0, l_uint32 val1 )

  pixConvert1To32()

      Input:  pixd (<optional> 32 bpp, can be null)
              pixs (1 bpp)
              val0 (32 bit value to be used for 0s in pixs)
              val1 (32 bit value to be used for 1s in pixs)
      Return: pixd (32 bpp)

  Notes:
      (1) If pixd is null, a new pix is made.
      (2) If pixd is not null, it must be of equal width and height
          as pixs.  It is always returned.

=head2 pixConvert1To4

PIX * pixConvert1To4 ( PIX *pixd, PIX *pixs, l_int32 val0, l_int32 val1 )

  pixConvert1To4()

      Input:  pixd (<optional> 4 bpp, can be null)
              pixs (1 bpp)
              val0 (4 bit value to be used for 0s in pixs)
              val1 (4 bit value to be used for 1s in pixs)
      Return: pixd (4 bpp)

  Notes:
      (1) If pixd is null, a new pix is made.
      (2) If pixd is not null, it must be of equal width and height
          as pixs.  It is always returned.
      (3) A simple unpacking might use val0 = 0 and val1 = 15, or v.v.
      (4) If you want a colormapped pixd, use pixConvert1To4Cmap().

=head2 pixConvert1To4Cmap

PIX * pixConvert1To4Cmap ( PIX *pixs )

  pixConvert1To4Cmap()

      Input:  pixs (1 bpp)
      Return: pixd (4 bpp, cmapped)

  Notes:
      (1) Input 0 is mapped to (255, 255, 255); 1 is mapped to (0, 0, 0)

=head2 pixConvert1To8

PIX * pixConvert1To8 ( PIX *pixd, PIX *pixs, l_uint8 val0, l_uint8 val1 )

  pixConvert1To8()

      Input:  pixd (<optional> 8 bpp, can be null)
              pixs (1 bpp)
              val0 (8 bit value to be used for 0s in pixs)
              val1 (8 bit value to be used for 1s in pixs)
      Return: pixd (8 bpp)

  Notes:
      (1) If pixd is null, a new pix is made.
      (2) If pixd is not null, it must be of equal width and height
          as pixs.  It is always returned.
      (3) A simple unpacking might use val0 = 0 and val1 = 255, or v.v.
      (4) In a typical application where one wants to use a colormap
          with the dest, you can use val0 = 0, val1 = 1 to make a
          non-cmapped 8 bpp pix, and then make a colormap and set 0
          and 1 to the desired colors.  Here is an example:
             pixd = pixConvert1To8(NULL, pixs, 0, 1);
             cmap = pixCreate(8);
             pixcmapAddColor(cmap, 255, 255, 255);
             pixcmapAddColor(cmap, 0, 0, 0);
             pixSetColormap(pixd, cmap);

=head2 pixConvert24To32

PIX * pixConvert24To32 ( PIX *pixs )

  pixConvert24To32()

      Input:  pixs (24 bpp rgb)
      Return: pixd (32 bpp rgb), or null on error

  Notes:
      (1) 24 bpp rgb pix are not supported in leptonica, except for a small
          number of formatted write operations.  The data is a byte array,
          with pixels in order r,g,b, and padded to 32 bit boundaries
          in each line.
      (2) Because 24 bpp rgb pix are conveniently generated by programs
          such as xpdf (which has SplashBitmaps that store the raster
          data in consecutive 24-bit rgb pixels), it is useful to provide
          24 bpp pix that simply incorporate that data.  The only things
          we can do with these are:
            (a) write them to file in png, jpeg, tiff and pnm
            (b) interconvert between 24 and 32 bpp in memory (for testing).

=head2 pixConvert2To8

PIX * pixConvert2To8 ( PIX *pixs, l_uint8 val0, l_uint8 val1, l_uint8 val2, l_uint8 val3, l_int32 cmapflag )

  pixConvert2To8()

      Input:  pixs (2 bpp)
              val0 (8 bit value to be used for 00 in pixs)
              val1 (8 bit value to be used for 01 in pixs)
              val2 (8 bit value to be used for 10 in pixs)
              val3 (8 bit value to be used for 11 in pixs)
              cmapflag (TRUE if pixd is to have a colormap; FALSE otherwise)
      Return: pixd (8 bpp), or null on error

  Notes:
      - A simple unpacking might use val0 = 0,
        val1 = 85 (0x55), val2 = 170 (0xaa), val3 = 255.
      - If cmapflag is TRUE:
          - The 8 bpp image is made with a colormap.
          - If pixs has a colormap, the input values are ignored and
            the 8 bpp image is made using the colormap
          - If pixs does not have a colormap, the input values are
            used to build the colormap.
      - If cmapflag is FALSE:
          - The 8 bpp image is made without a colormap.
          - If pixs has a colormap, the input values are ignored,
            the colormap is removed, and the values stored in the 8 bpp
            image are from the colormap.
          - If pixs does not have a colormap, the input values are
            used to populate the 8 bpp image.

=head2 pixConvert32To24

PIX * pixConvert32To24 ( PIX *pixs )

  pixConvert32To24()

      Input:  pixs (32 bpp rgb)
      Return: pixd (24 bpp rgb), or null on error

  Notes:
      (1) See pixconvert24To32().

=head2 pixConvert4To8

PIX * pixConvert4To8 ( PIX *pixs, l_int32 cmapflag )

  pixConvert4To8()

      Input:  pixs (4 bpp)
              cmapflag (TRUE if pixd is to have a colormap; FALSE otherwise)
      Return: pixd (8 bpp), or null on error

  Notes:
      - If cmapflag is TRUE:
          - pixd is made with a colormap.
          - If pixs has a colormap, it is copied and the colormap
            index values are placed in pixd.
          - If pixs does not have a colormap, a colormap with linear
            trc is built and the pixel values in pixs are placed in
            pixd as colormap index values.
      - If cmapflag is FALSE:
          - pixd is made without a colormap.
          - If pixs has a colormap, it is removed and the values stored
            in pixd are from the colormap (converted to gray).
          - If pixs does not have a colormap, the pixel values in pixs
            are used, with shift replication, to populate pixd.

=head2 pixConvert8To16

PIX * pixConvert8To16 ( PIX *pixs, l_int32 leftshift )

  pixConvert8To16()

      Input:  pixs (8 bpp; colormap removed to gray)
              leftshift (number of bits: 0 is no shift;
                         8 replicates in MSB and LSB of dest)
      Return: pixd (16 bpp), or null on error

  Notes:
      (1) For left shift of 8, the 8 bit value is replicated in both
          the MSB and the LSB of the pixels in pixd.  That way, we get
          proportional mapping, with a correct map from 8 bpp white
          (0xff) to 16 bpp white (0xffff).

=head2 pixConvert8To32

PIX * pixConvert8To32 ( PIX *pixs )

  pixConvert8To32()

      Input:  pix (8 bpp)
      Return: 32 bpp rgb pix, or null on error

  Notes:
      (1) If there is no colormap, replicates the gray value
          into the 3 MSB of the dest pixel.
      (2) Implicit assumption about RGB component ordering.

=head2 pixConvertColorToSubpixelRGB

PIX * pixConvertColorToSubpixelRGB ( PIX *pixs, l_float32 scalex, l_float32 scaley, l_int32 order )

  pixConvertColorToSubpixelRGB()

      Input:  pixs (32 bpp or colormapped)
              scalex, scaley
              order (of subpixel rgb color components in composition of pixd:
                     L_SUBPIXEL_ORDER_RGB, L_SUBPIXEL_ORDER_BGR,
                     L_SUBPIXEL_ORDER_VRGB, L_SUBPIXEL_ORDER_VBGR)

      Return: pixd (32 bpp), or null on error

  Notes:
      (1) If pixs has a colormap, it is removed to 32 bpp rgb.
          If the colormap has no color, pixConvertGrayToSubpixelRGB()
          should be called instead, because it will give the same result
          more efficiently.  The function pixConvertToSubpixelRGB()
          will do the best thing for all cases.
      (2) For horizontal subpixel splitting, the input rgb image
          is rescaled by @scaley vertically and by 3.0 times
          @scalex horizontally.  Then for each horizontal triplet
          of pixels, the r component of the final pixel is selected
          from the r component of the appropriate pixel in the triplet,
          and likewise for g and b.  Vertical subpixel splitting is
          handled similarly.

=head2 pixConvertForPSWrap

PIX * pixConvertForPSWrap ( PIX *pixs )

  pixConvertForPSWrap()

      Input:  pixs (1, 2, 4, 8, 16, 32 bpp)
      Return: pixd (1, 8, or 32 bpp), or null on error

  Notes:
      (1) For wrapping in PostScript, we convert pixs to
          1 bpp, 8 bpp (gray) and 32 bpp (RGB color).
      (2) Colormaps are removed.  For pixs with colormaps, the
          images are converted to either 8 bpp gray or 32 bpp
          RGB, depending on whether the colormap has color content.
      (3) Images without colormaps, that are not 1 bpp or 32 bpp,
          are converted to 8 bpp gray.

=head2 pixConvertGrayToColormap

PIX * pixConvertGrayToColormap ( PIX *pixs )

  pixConvertGrayToColormap()

      Input:  pixs (2, 4 or 8 bpp grayscale)
      Return: pixd (2, 4 or 8 bpp with colormap), or null on error

  Notes:
      (1) This is a simple interface for adding a colormap to a
          2, 4 or 8 bpp grayscale image without causing any
          quantization.  There is some similarity to operations
          in grayquant.c, such as pixThresholdOn8bpp(), where
          the emphasis is on quantization with an arbitrary number
          of levels, and a colormap is an option.
      (2) Returns a copy if pixs already has a colormap.
      (3) For 8 bpp src, this is a lossless transformation.
      (4) For 2 and 4 bpp src, this generates a colormap that
          assumes full coverage of the gray space, with equally spaced
          levels: 4 levels for d = 2 and 16 levels for d = 4.
      (5) In all cases, the depth of the dest is the same as the src.

=head2 pixConvertGrayToColormap8

PIX * pixConvertGrayToColormap8 ( PIX *pixs, l_int32 mindepth )

  pixConvertGrayToColormap8()

      Input:  pixs (8 bpp grayscale)
              mindepth (of pixd; valid values are 2, 4 and 8)
      Return: pixd (2, 4 or 8 bpp with colormap), or null on error

  Notes:
      (1) Returns a copy if pixs already has a colormap.
      (2) This is a lossless transformation; there is no quantization.
          We compute the number of different gray values in pixs,
          and construct a colormap that has exactly these values.
      (3) 'mindepth' is the minimum depth of pixd.  If mindepth == 8,
          pixd will always be 8 bpp.  Let the number of different
          gray values in pixs be ngray.  If mindepth == 4, we attempt
          to save pixd as a 4 bpp image, but if ngray > 16,
          pixd must be 8 bpp.  Likewise, if mindepth == 2,
          the depth of pixd will be 2 if ngray <= 4 and 4 if ngray > 4
          but <= 16.

=head2 pixConvertGrayToFalseColor

PIX * pixConvertGrayToFalseColor ( PIX *pixs, l_float32 gamma )

  pixConvertGrayToFalseColor()

      Input:  pixs (8 or 16 bpp grayscale)
              gamma factor (0.0 or 1.0 for default; > 1.0 for brighter;
                            2.0 is quite nice)
      Return: pixd (8 bpp with colormap), or null on error

  Notes:
      (1) For 8 bpp input, this simply adds a colormap to the input image.
      (2) For 16 bpp input, it first converts to 8 bpp, using the MSB,
          and then adds the colormap.
      (3) The colormap is modeled after the Matlab "jet" configuration.

=head2 pixConvertGrayToSubpixelRGB

PIX * pixConvertGrayToSubpixelRGB ( PIX *pixs, l_float32 scalex, l_float32 scaley, l_int32 order )

  pixConvertGrayToSubpixelRGB()

      Input:  pixs (8 bpp or colormapped)
              scalex, scaley
              order (of subpixel rgb color components in composition of pixd:
                     L_SUBPIXEL_ORDER_RGB, L_SUBPIXEL_ORDER_BGR,
                     L_SUBPIXEL_ORDER_VRGB, L_SUBPIXEL_ORDER_VBGR)

      Return: pixd (32 bpp), or null on error

  Notes:
      (1) If pixs has a colormap, it is removed to 8 bpp.
      (2) For horizontal subpixel splitting, the input gray image
          is rescaled by @scaley vertically and by 3.0 times
          @scalex horizontally.  Then each horizontal triplet
          of pixels is mapped back to a single rgb pixel, with the
          r, g and b values being assigned from the triplet of gray values.
          Similar operations are used for vertical subpixel splitting.
      (3) This is a form of subpixel rendering that tends to give the
          resulting text a sharper and somewhat chromatic display.
          For horizontal subpixel splitting, the observable difference
          between @order=L_SUBPIXEL_ORDER_RGB and
          @order=L_SUBPIXEL_ORDER_BGR is reduced by optical diffusers
          in the display that make the pixel color appear to emerge
          from the entire pixel.

=head2 pixConvertLossless

PIX * pixConvertLossless ( PIX *pixs, l_int32 d )

  pixConvertLossless()

      Input:  pixs (1, 2, 4, 8 bpp, not cmapped)
              d (destination depth: 2, 4 or 8)
      Return: pixd (2, 4 or 8 bpp), or null on error

  Notes:
      (1) This is a lossless unpacking (depth-increasing)
          conversion.  If ds is the depth of pixs, then
           - if d < ds, returns NULL
           - if d == ds, returns a copy
           - if d > ds, does the unpacking conversion
      (2) If pixs has a colormap, this is an error.

=head2 pixConvertRGBToColormap

PIX * pixConvertRGBToColormap ( PIX *pixs, l_int32 ditherflag )

  pixConvertRGBToColormap()

      Input:  pixs (32 bpp rgb)
              ditherflag (1 to dither, 0 otherwise)
      Return: pixd (2, 4 or 8 bpp with colormap), or null on error

  Notes:
      (1) This function has two relatively simple modes of color
          quantization:
            (a) If the image is made orthographically and has not more
                than 256 'colors' at the level 4 octcube leaves,
                it is quantized nearly exactly.  The ditherflag
                is ignored.
            (b) Most natural images have more than 256 different colors;
                in that case we use adaptive octree quantization,
                with dithering if requested.
      (2) If there are not more than 256 occupied level 4 octcubes,
          the color in the colormap that represents all pixels in
          one of those octcubes is given by the first pixel that
          falls into that octcube.
      (3) If there are more than 256 colors, we use adaptive octree
          color quantization.
      (4) Dithering gives better visual results on images where
          there is a color wash (a slow variation of color), but it
          is about twice as slow and results in significantly larger
          files when losslessly compressed (e.g., into png).

=head2 pixConvertRGBToGray

PIX * pixConvertRGBToGray ( PIX *pixs, l_float32 rwt, l_float32 gwt, l_float32 bwt )

  pixConvertRGBToGray()

      Input:  pix (32 bpp RGB)
              rwt, gwt, bwt  (non-negative; these should add to 1.0,
                              or use 0.0 for default)
      Return: 8 bpp pix, or null on error

  Notes:
      (1) Use a weighted average of the RGB values.

=head2 pixConvertRGBToGrayFast

PIX * pixConvertRGBToGrayFast ( PIX *pixs )

  pixConvertRGBToGrayFast()

      Input:  pix (32 bpp RGB)
      Return: 8 bpp pix, or null on error

  Notes:
      (1) This function should be used if speed of conversion
          is paramount, and the green channel can be used as
          a fair representative of the RGB intensity.  It is
          several times faster than pixConvertRGBToGray().
      (2) To combine RGB to gray conversion with subsampling,
          use pixScaleRGBToGrayFast() instead.

=head2 pixConvertRGBToGrayMinMax

PIX * pixConvertRGBToGrayMinMax ( PIX *pixs, l_int32 type )

  pixConvertRGBToGrayMinMax()

      Input:  pix (32 bpp RGB)
              type (L_CHOOSE_MIN or L_CHOOSE_MAX)
      Return: 8 bpp pix, or null on error

  Notes:
      (1) This chooses either the min or the max of the three
          RGB sample values.

=head2 pixConvertRGBToGraySatBoost

PIX * pixConvertRGBToGraySatBoost ( PIX *pixs, l_int32 refval )

  pixConvertRGBToGraySatBoost()

      Input:  pixs (32 bpp rgb)
              refval (between 1 and 255; typ. less than 128)
      Return: pixd (8 bpp), or null on error

  Notes:
      (1) This returns the max component value, boosted by
          the saturation. The maximum boost occurs where
          the maximum component value is equal to some reference value.
          This particular weighting is due to Dany Qumsiyeh.
      (2) For gray pixels (zero saturation), this returns
          the intensity of any component.
      (3) For fully saturated pixels ('fullsat'), this rises linearly
          with the max value and has a slope equal to 255 divided
          by the reference value; for a max value greater than
          the reference value, it is clipped to 255.
      (4) For saturation values in between, the output is a linear
          combination of (2) and (3), weighted by saturation.
          It falls between these two curves, and does not exceed 255.
      (5) This can be useful for distinguishing an object that has nonzero
          saturation from a gray background.  For this, the refval
          should be chosen near the expected value of the background,
          to achieve maximum saturation boost there.

=head2 pixConvertRGBToLuminance

PIX * pixConvertRGBToLuminance ( PIX *pixs )

  pixConvertRGBToLuminance()

      Input:  pix (32 bpp RGB)
      Return: 8 bpp pix, or null on error

  Notes:
      (1) Use a standard luminance conversion.

=head2 pixConvertTo1

PIX * pixConvertTo1 ( PIX *pixs, l_int32 threshold )

  pixConvertTo1()

      Input:  pixs (1, 2, 4, 8, 16 or 32 bpp)
              threshold (for final binarization, relative to 8 bpp)
      Return: pixd (1 bpp), or null on error

  Notes:
      (1) This is a top-level function, with simple default values
          used in pixConvertTo8() if unpacking is necessary.
      (2) Any existing colormap is removed.
      (3) If the input image has 1 bpp and no colormap, the operation is
          lossless and a copy is returned.

=head2 pixConvertTo16

PIX * pixConvertTo16 ( PIX *pixs )

  pixConvertTo16()

      Input:  pixs (1, 8 bpp)
      Return: pixd (16 bpp), or null on error

  Usage: Top-level function, with simple default values for unpacking.
      1 bpp:  val0 = 0xffff, val1 = 0
      8 bpp:  replicates the 8 bit value in both the MSB and LSB
              of the 16 bit pixel.

=head2 pixConvertTo1BySampling

PIX * pixConvertTo1BySampling ( PIX *pixs, l_int32 factor, l_int32 threshold )

  pixConvertTo1BySampling()

      Input:  pixs (1, 2, 4, 8, 16 or 32 bpp)
              factor (submsampling factor; integer >= 1)
              threshold (for final binarization, relative to 8 bpp)
      Return: pixd (1 bpp), or null on error

  Notes:
      (1) This is a fast, quick/dirty, top-level converter.
      (2) See pixConvertTo1() for default values.

=head2 pixConvertTo32

PIX * pixConvertTo32 ( PIX *pixs )

  pixConvertTo32()

      Input:  pixs (1, 2, 4, 8, 16 or 32 bpp)
      Return: pixd (32 bpp), or null on error

  Usage: Top-level function, with simple default values for unpacking.
      1 bpp:  val0 = 255, val1 = 0
              and then replication into R, G and B components
      2 bpp:  if colormapped, use the colormap values; otherwise,
              use val0 = 0, val1 = 0x55, val2 = 0xaa, val3 = 255
              and replicate gray into R, G and B components
      4 bpp:  if colormapped, use the colormap values; otherwise,
              replicate 2 nybs into a byte, and then into R,G,B components
      8 bpp:  if colormapped, use the colormap values; otherwise,
              replicate gray values into R, G and B components
      16 bpp: replicate MSB into R, G and B components
      24 bpp: unpack the pixels, maintaining word alignment on each scanline
      32 bpp: makes a copy

  Notes:
      (1) Never returns a clone of pixs.
      (2) Implicit assumption about RGB component ordering.

=head2 pixConvertTo32BySampling

PIX * pixConvertTo32BySampling ( PIX *pixs, l_int32 factor )

  pixConvertTo32BySampling()

      Input:  pixs (1, 2, 4, 8, 16 or 32 bpp)
              factor (submsampling factor; integer >= 1)
      Return: pixd (32 bpp), or null on error

  Notes:
      (1) This is a fast, quick/dirty, top-level converter.
      (2) See pixConvertTo32() for default values.

=head2 pixConvertTo8

PIX * pixConvertTo8 ( PIX *pixs, l_int32 cmapflag )

  pixConvertTo8()

      Input:  pixs (1, 2, 4, 8, 16 or 32 bpp)
              cmapflag (TRUE if pixd is to have a colormap; FALSE otherwise)
      Return: pixd (8 bpp), or null on error

  Notes:
      (1) This is a top-level function, with simple default values
          for unpacking.
      (2) The result, pixd, is made with a colormap if specified.
          It is always a new image -- never a clone.  For example,
          if d == 8, and cmapflag matches the existence of a cmap
          in pixs, the operation is lossless and it returns a copy.
      (3) The default values used are:
          - 1 bpp: val0 = 255, val1 = 0
          - 2 bpp: 4 bpp:  even increments over dynamic range
          - 8 bpp: lossless if cmap matches cmapflag
          - 16 bpp: use most significant byte
      (4) If 32 bpp RGB, this is converted to gray.  If you want
          to do color quantization, you must specify the type
          explicitly, using the color quantization code.

=head2 pixConvertTo8BySampling

PIX * pixConvertTo8BySampling ( PIX *pixs, l_int32 factor, l_int32 cmapflag )

  pixConvertTo8BySampling()

      Input:  pixs (1, 2, 4, 8, 16 or 32 bpp)
              factor (submsampling factor; integer >= 1)
              cmapflag (TRUE if pixd is to have a colormap; FALSE otherwise)
      Return: pixd (8 bpp), or null on error

  Notes:
      (1) This is a fast, quick/dirty, top-level converter.
      (2) See pixConvertTo8() for default values.

=head2 pixConvertTo8Color

PIX * pixConvertTo8Color ( PIX *pixs, l_int32 dither )

  pixConvertTo8Color()

      Input:  pixs (1, 2, 4, 8, 16 or 32 bpp)
              dither (1 to dither if necessary; 0 otherwise)
      Return: pixd (8 bpp, cmapped), or null on error

  Notes:
      (1) This is a top-level function, with simple default values
          for unpacking.
      (2) The result, pixd, is always made with a colormap.
      (3) If d == 8, the operation is lossless and it returns a copy.
      (4) The default values used for increasing depth are:
          - 1 bpp: val0 = 255, val1 = 0
          - 2 bpp: 4 bpp:  even increments over dynamic range
      (5) For 16 bpp, use the most significant byte.
      (6) For 32 bpp RGB, use octcube quantization with optional dithering.

=head2 pixConvertTo8Or32

PIX * pixConvertTo8Or32 ( PIX *pixs, l_int32 copyflag, l_int32 warnflag )

  pixConvertTo8Or32()

      Input:  pixs (1, 2, 4, 8, 16, with or without colormap; or 32 bpp rgb)
              copyflag (use 0 to return clone if pixs does not need to
                         be changed; 1 to return a copy in those situations)
              warnflag (1 to issue warning if colormap is removed; else 0)
      Return: pixd (8 bpp grayscale or 32 bpp rgb), or null on error

  Notes:
      (1) If there is a colormap, the colormap is removed to 8 or 32 bpp,
          depending on whether the colors in the colormap are all gray.
      (2) If the input is either rgb or 8 bpp without a colormap,
          this returns either a clone or a copy, depending on @copyflag.
      (3) Otherwise, the pix is converted to 8 bpp grayscale.
          In all cases, pixd does not have a colormap.

=head2 pixConvertToSubpixelRGB

PIX * pixConvertToSubpixelRGB ( PIX *pixs, l_float32 scalex, l_float32 scaley, l_int32 order )

  pixConvertToSubpixelRGB()

      Input:  pixs (8 bpp grayscale, 32 bpp rgb, or colormapped)
              scalex, scaley (anisotropic scaling permitted between
                              source and destination)
              order (of subpixel rgb color components in composition of pixd:
                     L_SUBPIXEL_ORDER_RGB, L_SUBPIXEL_ORDER_BGR,
                     L_SUBPIXEL_ORDER_VRGB, L_SUBPIXEL_ORDER_VBGR)

      Return: pixd (32 bpp), or null on error

  Notes:
      (1) If pixs has a colormap, it is removed based on its contents
          to either 8 bpp gray or rgb.
      (2) For horizontal subpixel splitting, the input image
          is rescaled by @scaley vertically and by 3.0 times
          @scalex horizontally.  Then each horizontal triplet
          of pixels is mapped back to a single rgb pixel, with the
          r, g and b values being assigned based on the pixel triplet.
          For gray triplets, the r, g, and b values are set equal to
          the three gray values.  For color triplets, the r, g and b
          values are set equal to the components from the appropriate
          subpixel.  Vertical subpixel splitting is handled similarly.
      (3) See pixConvertGrayToSubpixelRGB() and
          pixConvertColorToSubpixelRGB() for further details.

=head2 pixQuantizeIfFewColors

l_int32 pixQuantizeIfFewColors ( PIX *pixs, l_int32 maxcolors, l_int32 mingraycolors, l_int32 octlevel, PIX **ppixd )

  pixQuantizeIfFewColors()

      Input:  pixs (8 bpp gray or 32 bpp rgb)
              maxcolors (max number of colors allowed to be returned
                         from pixColorsForQuantization(); use 0 for default)
              mingraycolors (min number of gray levels that a grayscale
                             image is quantized to; use 0 for default)
              octlevel (for octcube quantization: 3 or 4)
              &pixd (2, 4 or 8 bpp quantized; null if too many colors)
      Return: 0 if OK, 1 on error or if pixs can't be quantized into
              a small number of colors.

  Notes:
      (1) This is a wrapper that tests if the pix can be quantized
          with good quality using a small number of colors.  If so,
          it does the quantization, defining a colormap and using
          pixels whose value is an index into the colormap.
      (2) If the image has color, it is quantized with 8 bpp pixels.
          If the image is essentially grayscale, the pixels are
          either 4 or 8 bpp, depending on the size of the required
          colormap.
      (3) @octlevel = 3 works well for most images.  However, for best
          quality, at a cost of more colors in the colormap, use
          @octlevel = 4.
      (4) If the image already has a colormap, it returns a clone.

=head2 pixRemoveAlpha

PIX * pixRemoveAlpha ( PIX *pixs )

  pixRemoveAlpha()

      Input:  pixs (any depth)
      Return: pixd (if 32 bpp rgba, pixs blended over a white background;
                    a clone of pixs otherwise), and null on error

  Notes:
      (1) This is a wrapper on pixAlphaBlendUniform()

=head2 pixRemoveColormap

PIX * pixRemoveColormap ( PIX *pixs, l_int32 type )

  pixRemoveColormap()

      Input:  pixs (see restrictions below)
              type (REMOVE_CMAP_TO_BINARY,
                    REMOVE_CMAP_TO_GRAYSCALE,
                    REMOVE_CMAP_TO_FULL_COLOR,
                    REMOVE_CMAP_WITH_ALPHA,
                    REMOVE_CMAP_BASED_ON_SRC)
      Return: pixd (without colormap), or null on error

  Notes:
      (1) If pixs does not have a colormap, a clone is returned.
      (2) Otherwise, the input pixs is restricted to 1, 2, 4 or 8 bpp.
      (3) Use REMOVE_CMAP_TO_BINARY only on 1 bpp pix.
      (4) For grayscale conversion from RGB, use a weighted average
          of RGB values, and always return an 8 bpp pix, regardless
          of whether the input pixs depth is 2, 4 or 8 bpp.
      (5) REMOVE_CMAP_BASED_ON_SRC and REMOVE_CMAP_TO_FULL_COLOR
          ignore the alpha components.  For 32-bit pixel output,
          the alpha byte is set to 0 and spp = 3.

=head2 pixRemoveColormapGeneral

PIX * pixRemoveColormapGeneral ( PIX *pixs, l_int32 type, l_int32 ifnocmap )

  pixRemoveColormapGeneral()

      Input:  pixs (any depth, with or without colormap)
              type (REMOVE_CMAP_TO_BINARY,
                    REMOVE_CMAP_TO_GRAYSCALE,
                    REMOVE_CMAP_TO_FULL_COLOR,
                    REMOVE_CMAP_WITH_ALPHA,
                    REMOVE_CMAP_BASED_ON_SRC)
              ifnocmap (L_CLONE, L_COPY)
      Return: pixd (always a new pix; without colormap), or null on error

  Notes:
      (1) Convenience function that allows choice between returning
          a clone or a copy if pixs does not have a colormap.
      (2) See pixRemoveColormap().

=head2 pixThreshold8

PIX * pixThreshold8 ( PIX *pixs, l_int32 d, l_int32 nlevels, l_int32 cmapflag )

  pixThreshold8()

      Input:  pix (8 bpp grayscale)
              d (destination depth: 1, 2, 4 or 8)
              nlevels (number of levels to be used for colormap)
              cmapflag (1 if makes colormap; 0 otherwise)
      Return: pixd (thresholded with standard dest thresholds),
              or null on error

  Notes:
      (1) This uses, by default, equally spaced "target" values
          that depend on the number of levels, with thresholds
          halfway between.  For N levels, with separation (N-1)/255,
          there are N-1 fixed thresholds.
      (2) For 1 bpp destination, the number of levels can only be 2
          and if a cmap is made, black is (0,0,0) and white
          is (255,255,255), which is opposite to the convention
          without a colormap.
      (3) For 1, 2 and 4 bpp, the nlevels arg is used if a colormap
          is made; otherwise, we take the most significant bits
          from the src that will fit in the dest.
      (4) For 8 bpp, the input pixs is quantized to nlevels.  The
          dest quantized with that mapping, either through a colormap
          table or directly with 8 bit values.
      (5) Typically you should not use make a colormap for 1 bpp dest.
      (6) This is not dithering.  Each pixel is treated independently.

=head2 pixUnpackBinary

PIX * pixUnpackBinary ( PIX *pixs, l_int32 depth, l_int32 invert )

  pixUnpackBinary()

      Input:  pixs (1 bpp)
              depth (of destination: 2, 4, 8, 16 or 32 bpp)
              invert (0:  binary 0 --> grayscale 0
                          binary 1 --> grayscale 0xff...
                      1:  binary 0 --> grayscale 0xff...
                          binary 1 --> grayscale 0)
      Return: pixd (2, 4, 8, 16 or 32 bpp), or null on error

  Notes:
      (1) This function calls special cases of pixConvert1To*(),
          for 2, 4, 8, 16 and 32 bpp destinations.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
