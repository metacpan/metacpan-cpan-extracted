package Image::Leptonica::Func::colormap;
$Image::Leptonica::Func::colormap::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::colormap

=head1 VERSION

version 0.04

=head1 C<colormap.c>

  colormap.c

      Colormap creation, copy, destruction, addition
           PIXCMAP    *pixcmapCreate()
           PIXCMAP    *pixcmapCreateRandom()
           PIXCMAP    *pixcmapCreateLinear()
           PIXCMAP    *pixcmapCopy()
           void        pixcmapDestroy()
           l_int32     pixcmapAddColor()
           l_int32     pixcmapAddRGBA()
           l_int32     pixcmapAddNewColor()
           l_int32     pixcmapAddNearestColor()
           l_int32     pixcmapUsableColor()
           l_int32     pixcmapAddBlackOrWhite()
           l_int32     pixcmapSetBlackAndWhite()
           l_int32     pixcmapGetCount()
           l_int32     pixcmapGetDepth()
           l_int32     pixcmapGetMinDepth()
           l_int32     pixcmapGetFreeCount()
           l_int32     pixcmapClear()

      Colormap random access and test
           l_int32     pixcmapGetColor()
           l_int32     pixcmapGetColor32()
           l_int32     pixcmapGetRGBA()
           l_int32     pixcmapGetRGBA32()
           l_int32     pixcmapResetColor()
           l_int32     pixcmapGetIndex()
           l_int32     pixcmapHasColor()
           l_int32     pixcmapIsOpaque()
           l_int32     pixcmapCountGrayColors()
           l_int32     pixcmapGetRankIntensity()
           l_int32     pixcmapGetNearestIndex()
           l_int32     pixcmapGetNearestGrayIndex()
           l_int32     pixcmapGetComponentRange()
           l_int32     pixcmapGetExtremeValue()

      Colormap conversion
           PIXCMAP    *pixcmapGrayToColor()
           PIXCMAP    *pixcmapColorToGray()

      Colormap I/O
           l_int32     pixcmapReadStream()
           l_int32     pixcmapWriteStream()

      Extract colormap arrays and serialization
           l_int32     pixcmapToArrays()
           l_int32     pixcmapToRGBTable()
           l_int32     pixcmapSerializeToMemory()
           PIXCMAP    *pixcmapDeserializeFromMemory()
           char       *pixcmapConvertToHex()

      Colormap transforms
           l_int32     pixcmapGammaTRC()
           l_int32     pixcmapContrastTRC()
           l_int32     pixcmapShiftIntensity()
           l_int32     pixcmapShiftByComponent()

=head1 FUNCTIONS

=head2 pixcmapAddBlackOrWhite

l_int32 pixcmapAddBlackOrWhite ( PIXCMAP *cmap, l_int32 color, l_int32 *pindex )

  pixcmapAddBlackOrWhite()

      Input:  cmap
              color (0 for black, 1 for white)
              &index (<optional return> index of color; can be null)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This only adds color if not already there.
      (2) The alpha component is 255 (opaque)
      (3) This sets index to the requested color.
      (4) If there is no room in the colormap, returns the index
          of the closest color.

=head2 pixcmapAddColor

l_int32 pixcmapAddColor ( PIXCMAP *cmap, l_int32 rval, l_int32 gval, l_int32 bval )

  pixcmapAddColor()

      Input:  cmap
              rval, gval, bval (colormap entry to be added; each number
                                is in range [0, ... 255])
      Return: 0 if OK, 1 on error

  Notes:
      (1) This always adds the color if there is room.
      (2) The alpha component is 255 (opaque)

=head2 pixcmapAddNearestColor

l_int32 pixcmapAddNearestColor ( PIXCMAP *cmap, l_int32 rval, l_int32 gval, l_int32 bval, l_int32 *pindex )

  pixcmapAddNearestColor()

      Input:  cmap
              rval, gval, bval (colormap entry to be added; each number
                                is in range [0, ... 255])
              &index (<return> index of color)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This only adds color if not already there.
      (2) The alpha component is 255 (opaque)
      (3) If it's not in the colormap and there is no room to add
          another color, this returns the index of the nearest color.

=head2 pixcmapAddNewColor

l_int32 pixcmapAddNewColor ( PIXCMAP *cmap, l_int32 rval, l_int32 gval, l_int32 bval, l_int32 *pindex )

  pixcmapAddNewColor()

      Input:  cmap
              rval, gval, bval (colormap entry to be added; each number
                                is in range [0, ... 255])
              &index (<return> index of color)
      Return: 0 if OK, 1 on error; 2 if unable to add color

  Notes:
      (1) This only adds color if not already there.
      (2) The alpha component is 255 (opaque)
      (3) This returns the index of the new (or existing) color.
      (4) Returns 2 with a warning if unable to add this color;
          the caller should check the return value.

=head2 pixcmapAddRGBA

l_int32 pixcmapAddRGBA ( PIXCMAP *cmap, l_int32 rval, l_int32 gval, l_int32 bval, l_int32 aval )

  pixcmapAddRGBA()

      Input:  cmap
              rval, gval, bval, aval (colormap entry to be added;
                                      each number is in range [0, ... 255])
      Return: 0 if OK, 1 on error

  Notes:
      (1) This always adds the color if there is room.

=head2 pixcmapClear

l_int32 pixcmapClear ( PIXCMAP *cmap )

  pixcmapClear()

      Input:  cmap
      Return: 0 if OK, 1 on error

  Note: this removes the colors by setting the count to 0.

=head2 pixcmapColorToGray

PIXCMAP * pixcmapColorToGray ( PIXCMAP *cmaps, l_float32 rwt, l_float32 gwt, l_float32 bwt )

  pixcmapColorToGray()

      Input:  cmap
              rwt, gwt, bwt  (non-negative; these should add to 1.0)
      Return: cmap (gray), or null on error

  Notes:
      (1) This creates a gray colormap from an arbitrary colormap.
      (2) In use, attach the output gray colormap to the pix
          (or a copy of it) that provided the input colormap.

=head2 pixcmapContrastTRC

l_int32 pixcmapContrastTRC ( PIXCMAP *cmap, l_float32 factor )

  pixcmapContrastTRC()

      Input:  colormap
              factor (generally between 0.0 (no enhancement)
                      and 1.0, but can be larger than 1.0)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is an in-place transform
      (2) See pixContrastTRC() and numaContrastTRC() in enhance.c
          for description and use of transform

=head2 pixcmapConvertToHex

char * pixcmapConvertToHex ( l_uint8 *data, l_int32 ncolors )

  pixcmapConvertToHex()

      Input:  data  (binary serialized data)
              ncolors (in colormap)
      Return: hexdata (bracketed, space-separated ascii hex string),
                       or null on error.

  Notes:
      (1) The number of bytes in @data is 3 * ncolors.
      (2) Output is in form:
             < r0g0b0 r1g1b1 ... rngnbn >
          where r0, g0, b0 ... are each 2 bytes of hex ascii
      (3) This is used in pdf files to express the colormap as an
          array in ascii (human-readable) format.

=head2 pixcmapCopy

PIXCMAP * pixcmapCopy ( PIXCMAP *cmaps )

  pixcmapCopy()

      Input:  cmaps
      Return: cmapd, or null on error

=head2 pixcmapCountGrayColors

l_int32 pixcmapCountGrayColors ( PIXCMAP *cmap, l_int32 *pngray )

  pixcmapCountGrayColors()

      Input:  cmap
              &ngray (<return> number of gray colors)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This counts the unique gray colors, including black and white.

=head2 pixcmapCreate

PIXCMAP * pixcmapCreate ( l_int32 depth )

  pixcmapCreate()

      Input:  depth (bpp, of pix)
      Return: cmap, or null on error

=head2 pixcmapCreateLinear

PIXCMAP * pixcmapCreateLinear ( l_int32 d, l_int32 nlevels )

  pixcmapCreateLinear()

      Input:  d (depth of pix for this colormap; 1, 2, 4 or 8)
              nlevels (valid in range [2, 2^d])
      Return: cmap, or null on error

  Notes:
      (1) Colormap has equally spaced gray color values
          from black (0, 0, 0) to white (255, 255, 255).

=head2 pixcmapCreateRandom

PIXCMAP * pixcmapCreateRandom ( l_int32 depth, l_int32 hasblack, l_int32 haswhite )

  pixcmapCreateRandom()

      Input:  depth (bpp, of pix; 2, 4 or 8)
              hasblack (1 if the first color is black; 0 if no black)
              haswhite (1 if the last color is white; 0 if no white)
      Return: cmap, or null on error

  Notes:
      (1) This sets up a colormap with random colors,
          where the first color is optionally black, the last color
          is optionally white, and the remaining colors are
          chosen randomly.
      (2) The number of randomly chosen colors is:
               2^(depth) - haswhite - hasblack
      (3) Because rand() is seeded, it might disrupt otherwise
          deterministic results if also used elsewhere in a program.
      (4) rand() is not threadsafe, and will generate garbage if run
          on multiple threads at once -- though garbage is generally
          what you want from a random number generator!
      (5) Modern rand()s have equal randomness in low and high order
          bits, but older ones don't.  Here, we're just using rand()
          to choose colors for output.

=head2 pixcmapDeserializeFromMemory

PIXCMAP * pixcmapDeserializeFromMemory ( l_uint8 *data, l_int32 cpc, l_int32 ncolors )

  pixcmapDeserializeFromMemory()

      Input:  data (binary string, 3 or 4 bytes per color)
              cpc (components/color: 3 for rgb, 4 for rgba)
              ncolors
      Return: cmap, or null on error

=head2 pixcmapDestroy

void pixcmapDestroy ( PIXCMAP **pcmap )

  pixcmapDestroy()

      Input:  &cmap (<set to null>)
      Return: void

=head2 pixcmapGammaTRC

l_int32 pixcmapGammaTRC ( PIXCMAP *cmap, l_float32 gamma, l_int32 minval, l_int32 maxval )

  pixcmapGammaTRC()

      Input:  colormap
              gamma (gamma correction; must be > 0.0)
              minval  (input value that gives 0 for output; can be < 0)
              maxval  (input value that gives 255 for output; can be > 255)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is an in-place transform
      (2) See pixGammaTRC() and numaGammaTRC() in enhance.c
          for description and use of transform

=head2 pixcmapGetColor

l_int32 pixcmapGetColor ( PIXCMAP *cmap, l_int32 index, l_int32 *prval, l_int32 *pgval, l_int32 *pbval )

  pixcmapGetColor()

      Input:  cmap
              index
              &rval, &gval, &bval (<return> each color value)
      Return: 0 if OK, 1 if not accessable (caller should check)

=head2 pixcmapGetColor32

l_int32 pixcmapGetColor32 ( PIXCMAP *cmap, l_int32 index, l_uint32 *pval32 )

  pixcmapGetColor32()

      Input:  cmap
              index
              &val32 (<return> 32-bit rgb color value)
      Return: 0 if OK, 1 if not accessable (caller should check)

  Notes:
      (1) The returned alpha channel value is 0.

=head2 pixcmapGetComponentRange

l_int32 pixcmapGetComponentRange ( PIXCMAP *cmap, l_int32 color, l_int32 *pminval, l_int32 *pmaxval )

  pixcmapGetComponentRange()

      Input:  cmap
              color (L_SELECT_RED, L_SELECT_GREEN or L_SELECT_BLUE)
              &minval (<optional return> minimum value of component)
              &maxval (<optional return> minimum value of component)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Returns for selected components the extreme value
          (either min or max) of the color component that is
          found in the colormap.

=head2 pixcmapGetCount

l_int32 pixcmapGetCount ( PIXCMAP *cmap )

  pixcmapGetCount()

      Input:  cmap
      Return: count, or 0 on error

=head2 pixcmapGetDepth

l_int32 pixcmapGetDepth ( PIXCMAP *cmap )

  pixcmapGetDepth()

      Input:  cmap
      Return: depth, or 0 on error

=head2 pixcmapGetExtremeValue

l_int32 pixcmapGetExtremeValue ( PIXCMAP *cmap, l_int32 type, l_int32 *prval, l_int32 *pgval, l_int32 *pbval )

  pixcmapGetExtremeValue()

      Input:  cmap
              type (L_SELECT_MIN or L_SELECT_MAX)
              &rval (<optional return> red component)
              &gval (<optional return> green component)
              &bval (<optional return> blue component)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Returns for selected components the extreme value
          (either min or max) of the color component that is
          found in the colormap.

=head2 pixcmapGetFreeCount

l_int32 pixcmapGetFreeCount ( PIXCMAP *cmap )

  pixcmapGetFreeCount()

      Input:  cmap
      Return: free entries, or 0 on error

=head2 pixcmapGetIndex

l_int32 pixcmapGetIndex ( PIXCMAP *cmap, l_int32 rval, l_int32 gval, l_int32 bval, l_int32 *pindex )

  pixcmapGetIndex()

      Input:  cmap
              rval, gval, bval (colormap colors to search for; each number
                                is in range [0, ... 255])
              &index (<return>)
      Return: 0 if found, 1 if not found (caller must check)

=head2 pixcmapGetMinDepth

l_int32 pixcmapGetMinDepth ( PIXCMAP *cmap, l_int32 *pmindepth )

  pixcmapGetMinDepth()

      Input:  cmap
              &mindepth (<return> minimum depth to support the colormap)
      Return: 0 if OK, 1 on error

  Notes:
      (1) On error, &mindepth is returned as 0.

=head2 pixcmapGetNearestGrayIndex

l_int32 pixcmapGetNearestGrayIndex ( PIXCMAP *cmap, l_int32 val, l_int32 *pindex )

  pixcmapGetNearestGrayIndex()

      Input:  cmap
              val (gray value to search for; in range [0, ... 255])
              &index (<return> the index of the nearest color)
      Return: 0 if OK, 1 on error (caller must check)

  Notes:
      (1) This should be used on gray colormaps.  It uses only the
          green value of the colormap.
      (2) Returns the index of the exact color if possible, otherwise the
          index of the color closest to the target color.

=head2 pixcmapGetNearestIndex

l_int32 pixcmapGetNearestIndex ( PIXCMAP *cmap, l_int32 rval, l_int32 gval, l_int32 bval, l_int32 *pindex )

  pixcmapGetNearestIndex()

      Input:  cmap
              rval, gval, bval (colormap colors to search for; each number
                                is in range [0, ... 255])
              &index (<return> the index of the nearest color)
      Return: 0 if OK, 1 on error (caller must check)

  Notes:
      (1) Returns the index of the exact color if possible, otherwise the
          index of the color closest to the target color.
      (2) Nearest color is that which is the least sum-of-squares distance
          from the target color.

=head2 pixcmapGetRGBA

l_int32 pixcmapGetRGBA ( PIXCMAP *cmap, l_int32 index, l_int32 *prval, l_int32 *pgval, l_int32 *pbval, l_int32 *paval )

  pixcmapGetRGBA()

      Input:  cmap
              index
              &rval, &gval, &bval, &aval (<return> each color value)
      Return: 0 if OK, 1 if not accessable (caller should check)

=head2 pixcmapGetRGBA32

l_int32 pixcmapGetRGBA32 ( PIXCMAP *cmap, l_int32 index, l_uint32 *pval32 )

  pixcmapGetRGBA32()

      Input:  cmap
              index
              &val32 (<return> 32-bit rgba color value)
      Return: 0 if OK, 1 if not accessable (caller should check)

=head2 pixcmapGetRankIntensity

l_int32 pixcmapGetRankIntensity ( PIXCMAP *cmap, l_float32 rankval, l_int32 *pindex )

  pixcmapGetRankIntensity()

      Input:  cmap
              rankval (0.0 for darkest, 1.0 for lightest color)
              &index (<return> the index into the colormap that
                      corresponds to the rank intensity color)
      Return: 0 if OK, 1 on error

=head2 pixcmapGrayToColor

PIXCMAP * pixcmapGrayToColor ( l_uint32 color )

  pixcmapGrayToColor()

      Input:  color
      Return: cmap, or null on error

  Notes:
      (1) This creates a colormap that maps from gray to
          a specific color.  In the mapping, each component
          is faded to white, depending on the gray value.
      (2) In use, this is simply attached to a grayscale pix
          to give it the input color.

=head2 pixcmapHasColor

l_int32 pixcmapHasColor ( PIXCMAP *cmap, l_int32 *pcolor )

  pixcmapHasColor()

      Input:  cmap
              &color (<return> TRUE if cmap has color; FALSE otherwise)
      Return: 0 if OK, 1 on error

=head2 pixcmapIsOpaque

l_int32 pixcmapIsOpaque ( PIXCMAP *cmap, l_int32 *popaque )

  pixcmapIsOpaque()

      Input:  cmap
              &opaque (<return> TRUE if fully opaque: all entries are 255)
      Return: 0 if OK, 1 on error

=head2 pixcmapReadStream

PIXCMAP * pixcmapReadStream ( FILE *fp )

  pixcmapReadStream()

      Input:  stream
      Return: cmap, or null on error

=head2 pixcmapResetColor

l_int32 pixcmapResetColor ( PIXCMAP *cmap, l_int32 index, l_int32 rval, l_int32 gval, l_int32 bval )

  pixcmapResetColor()

      Input:  cmap
              index
              rval, gval, bval (colormap entry to be reset; each number
                                is in range [0, ... 255])
      Return: 0 if OK, 1 if not accessable (caller should check)

  Notes:
      (1) This resets sets the color of an entry that has already
          been set and included in the count of colors.
      (2) The alpha component is 255 (opaque)

=head2 pixcmapSerializeToMemory

l_int32 pixcmapSerializeToMemory ( PIXCMAP *cmap, l_int32 cpc, l_int32 *pncolors, l_uint8 **pdata )

  pixcmapSerializeToMemory()

      Input:  colormap
              cpc (components/color: 3 for rgb, 4 for rgba)
              &ncolors (<return> number of colors in table)
              &data (<return> binary string, cpc bytes per color)
      Return: 0 if OK; 1 on error

  Notes:
      (1) When serializing to store in a pdf, use @cpc = 3.

=head2 pixcmapSetBlackAndWhite

l_int32 pixcmapSetBlackAndWhite ( PIXCMAP *cmap, l_int32 setblack, l_int32 setwhite )

  pixcmapSetBlackAndWhite()

      Input:  cmap
              setblack (0 for no operation; 1 to set darkest color to black)
              setwhite (0 for no operation; 1 to set lightest color to white)
      Return: 0 if OK, 1 on error

=head2 pixcmapShiftByComponent

l_int32 pixcmapShiftByComponent ( PIXCMAP *cmap, l_uint32 srcval, l_uint32 dstval )

  pixcmapShiftByComponent()

      Input:  colormap
              srcval (source color: 0xrrggbb00)
              dstval (target color: 0xrrggbb00)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is an in-place transform
      (2) It implements pixelShiftByComponent() for each color.
          The mapping is specified by srcval and dstval.
      (3) If a component decreases, the component in the colormap
          decreases by the same ratio.  Likewise for increasing, except
          all ratios are taken with respect to the distance from 255.

=head2 pixcmapShiftIntensity

l_int32 pixcmapShiftIntensity ( PIXCMAP *cmap, l_float32 fraction )

  pixcmapShiftIntensity()

      Input:  colormap
              fraction (between -1.0 and +1.0)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is an in-place transform
      (2) It does a proportional shift of the intensity for each color.
      (3) If fraction < 0.0, it moves all colors towards (0,0,0).
          This darkens the image.
          If fraction > 0.0, it moves all colors towards (255,255,255)
          This fades the image.
      (4) The equivalent transform can be accomplished with pixcmapGammaTRC(),
          but it is considerably more difficult (see numaGammaTRC()).

=head2 pixcmapToArrays

l_int32 pixcmapToArrays ( PIXCMAP *cmap, l_int32 **prmap, l_int32 **pgmap, l_int32 **pbmap, l_int32 **pamap )

  pixcmapToArrays()

      Input:  colormap
              &rmap, &gmap, &bmap  (<return> colormap arrays)
              &amap (<optional return> alpha array)
      Return: 0 if OK; 1 on error

=head2 pixcmapToRGBTable

l_int32 pixcmapToRGBTable ( PIXCMAP *cmap, l_uint32 **ptab, l_int32 *pncolors )

  pixcmapToRGBTable()

      Input:  colormap
              &tab (<return> table of rgba values for the colormap)
              &ncolors (<optional return> size of table)
      Return: 0 if OK; 1 on error

=head2 pixcmapUsableColor

l_int32 pixcmapUsableColor ( PIXCMAP *cmap, l_int32 rval, l_int32 gval, l_int32 bval, l_int32 *pusable )

  pixcmapUsableColor()

      Input:  cmap
              rval, gval, bval (colormap entry to be added; each number
                                is in range [0, ... 255])
              usable (<return> 1 if usable; 0 if not)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This checks if the color already exists or if there is
          room to add it.  It makes no change in the colormap.

=head2 pixcmapWriteStream

l_int32 pixcmapWriteStream ( FILE *fp, PIXCMAP *cmap )

  pixcmapWriteStream()

      Input:  stream, cmap
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
