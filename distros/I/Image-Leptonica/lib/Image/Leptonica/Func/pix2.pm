package Image::Leptonica::Func::pix2;
$Image::Leptonica::Func::pix2::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pix2

=head1 VERSION

version 0.04

=head1 C<pix2.c>

  pix2.c

    This file has these basic operations:

      (1) Get and set: individual pixels, full image, rectangular region,
          pad pixels, border pixels, and color components for RGB
      (2) Add and remove border pixels
      (3) Endian byte swaps
      (4) Simple method for byte-processing images (instead of words)

      Pixel poking
           l_int32     pixGetPixel()
           l_int32     pixSetPixel()
           l_int32     pixGetRGBPixel()
           l_int32     pixSetRGBPixel()
           l_int32     pixGetRandomPixel()
           l_int32     pixClearPixel()
           l_int32     pixFlipPixel()
           void        setPixelLow()

      Find black or white value
           l_int32     pixGetBlackOrWhiteVal()

      Full image clear/set/set-to-arbitrary-value
           l_int32     pixClearAll()
           l_int32     pixSetAll()
           l_int32     pixSetAllGray()
           l_int32     pixSetAllArbitrary()
           l_int32     pixSetBlackOrWhite()
           l_int32     pixSetComponentArbitrary()

      Rectangular region clear/set/set-to-arbitrary-value/blend
           l_int32     pixClearInRect()
           l_int32     pixSetInRect()
           l_int32     pixSetInRectArbitrary()
           l_int32     pixBlendInRect()

      Set pad bits
           l_int32     pixSetPadBits()
           l_int32     pixSetPadBitsBand()

      Assign border pixels
           l_int32     pixSetOrClearBorder()
           l_int32     pixSetBorderVal()
           l_int32     pixSetBorderRingVal()
           l_int32     pixSetMirroredBorder()
           PIX        *pixCopyBorder()

      Add and remove border
           PIX        *pixAddBorder()
           PIX        *pixAddBlackOrWhiteBorder()
           PIX        *pixAddBorderGeneral()
           PIX        *pixRemoveBorder()
           PIX        *pixRemoveBorderGeneral()
           PIX        *pixRemoveBorderToSize()
           PIX        *pixAddMirroredBorder()
           PIX        *pixAddRepeatedBorder()
           PIX        *pixAddMixedBorder()
           PIX        *pixAddContinuedBorder()

      Helper functions using alpha
           l_int32     pixShiftAndTransferAlpha()
           PIX        *pixDisplayLayersRGBA()

      Color sample setting and extraction
           PIX        *pixCreateRGBImage()
           PIX        *pixGetRGBComponent()
           l_int32     pixSetRGBComponent()
           PIX        *pixGetRGBComponentCmap()
           l_int32     pixCopyRGBComponent()
           l_int32     composeRGBPixel()
           l_int32     composeRGBAPixel()
           void        extractRGBValues()
           void        extractRGBAValues()
           l_int32     extractMinMaxComponent()
           l_int32     pixGetRGBLine()

      Conversion between big and little endians
           PIX        *pixEndianByteSwapNew()
           l_int32     pixEndianByteSwap()
           l_int32     lineEndianByteSwap()
           PIX        *pixEndianTwoByteSwapNew()
           l_int32     pixEndianTwoByteSwap()

      Extract raster data as binary string
           l_int32     pixGetRasterData()

      Test alpha component opaqueness
           l_int32     pixAlphaIsOpaque

      Setup helpers for 8 bpp byte processing
           l_uint8   **pixSetupByteProcessing()
           l_int32     pixCleanupByteProcessing()

      Setting parameters for antialias masking with alpha transforms
           void        l_setAlphaMaskBorder()

      *** indicates implicit assumption about RGB component ordering

=head1 FUNCTIONS

=head2 composeRGBAPixel

l_int32 composeRGBAPixel ( l_int32 rval, l_int32 gval, l_int32 bval, l_int32 aval, l_uint32 *ppixel )

  composeRGBAPixel()

      Input:  rval, gval, bval, aval
              &pixel  (<return> 32-bit pixel)
      Return: 0 if OK; 1 on error

  Notes:
      (1) All channels are 8 bits: the input values must be between
          0 and 255.  For speed, this is not enforced by masking
          with 0xff before shifting.

=head2 composeRGBPixel

l_int32 composeRGBPixel ( l_int32 rval, l_int32 gval, l_int32 bval, l_uint32 *ppixel )

  composeRGBPixel()

      Input:  rval, gval, bval
              &pixel  (<return> 32-bit pixel)
      Return: 0 if OK; 1 on error

  Notes:
      (1) All channels are 8 bits: the input values must be between
          0 and 255.  For speed, this is not enforced by masking
          with 0xff before shifting.
      (2) A slower implementation uses macros:
            SET_DATA_BYTE(ppixel, COLOR_RED, rval);
            SET_DATA_BYTE(ppixel, COLOR_GREEN, gval);
            SET_DATA_BYTE(ppixel, COLOR_BLUE, bval);

=head2 extractMinMaxComponent

l_int32 extractMinMaxComponent ( l_uint32 pixel, l_int32 type )

  extractMinMaxComponent()

      Input:  pixel (32 bpp RGB)
              type (L_CHOOSE_MIN or L_CHOOSE_MAX)
      Return: component (in range [0 ... 255], or null on error

=head2 extractRGBAValues

void extractRGBAValues ( l_uint32 pixel, l_int32 *prval, l_int32 *pgval, l_int32 *pbval, l_int32 *paval )

  extractRGBAValues()

      Input:  pixel (32 bit)
              &rval (<optional return> red component)
              &gval (<optional return> green component)
              &bval (<optional return> blue component)
              &aval (<optional return> alpha component)
      Return: void

=head2 extractRGBValues

void extractRGBValues ( l_uint32 pixel, l_int32 *prval, l_int32 *pgval, l_int32 *pbval )

  extractRGBValues()

      Input:  pixel (32 bit)
              &rval (<optional return> red component)
              &gval (<optional return> green component)
              &bval (<optional return> blue component)
      Return: void

  Notes:
      (1) A slower implementation uses macros:
             *prval = GET_DATA_BYTE(&pixel, COLOR_RED);
             *pgval = GET_DATA_BYTE(&pixel, COLOR_GREEN);
             *pbval = GET_DATA_BYTE(&pixel, COLOR_BLUE);

=head2 l_setAlphaMaskBorder

void l_setAlphaMaskBorder ( l_float32 val1, l_float32 val2 )

  l_setAlphaMaskBorder()

      Input:  val1, val2 (in [0.0 ... 1.0])
      Return: void

  Notes:
      (1) This sets the opacity values used to generate the two outer
          boundary rings in the alpha mask associated with geometric
          transforms such as pixRotateWithAlpha().
      (2) The default values are val1 = 0.0 (completely transparent
          in the outermost ring) and val2 = 0.5 (half transparent
          in the second ring).  When the image is blended, this
          completely removes the outer ring (shrinking the image by
          2 in each direction), and alpha-blends with 0.5 the second ring.
          Using val1 = 0.25 and val2 = 0.75 gives a slightly more
          blurred border, with no perceptual difference at screen resolution.
      (3) The actual mask values are found by multiplying these
          normalized opacity values by 255.

=head2 lineEndianByteSwap

l_int32 lineEndianByteSwap ( l_uint32 *datad, l_uint32 *datas, l_int32 wpl )

  lineEndianByteSwap()

      Input   datad (dest byte array data, reordered on little-endians)
              datas (a src line of pix data)
              wpl (number of 32 bit words in the line)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is used on little-endian platforms to swap
          the bytes within each word in the line of image data.
          Bytes 0 <==> 3 and 1 <==> 2 are swapped in the dest
          byte array data8d, relative to the pix data in datas.
      (2) The bytes represent 8 bit pixel values.  They are swapped
          for little endians so that when the dest array (char *)datad
          is addressed by bytes, the pixels are chosen sequentially
          from left to right in the image.

=head2 pixAddBlackOrWhiteBorder

PIX * pixAddBlackOrWhiteBorder ( PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot, l_int32 op )

  pixAddBlackOrWhiteBorder()

      Input:  pixs (all depths; colormap ok)
              left, right, top, bot  (number of pixels added)
              op (L_GET_BLACK_VAL, L_GET_WHITE_VAL)
      Return: pixd (with the added exterior pixels), or null on error

  Notes:
      (1) See pixGetBlackOrWhiteVal() for possible side effect (adding
          a color to a colormap).
      (2) The only complication is that pixs may have a colormap.
          There are two ways to add the black or white border:
          (a) As done here (simplest, most efficient)
          (b) l_int32 ws, hs, d;
              pixGetDimensions(pixs, &ws, &hs, &d);
              Pix *pixd = pixCreate(ws + left + right, hs + top + bot, d);
              PixColormap *cmap = pixGetColormap(pixs);
              if (cmap != NULL)
                  pixSetColormap(pixd, pixcmapCopy(cmap));
              pixSetBlackOrWhite(pixd, L_SET_WHITE);  // uses cmap
              pixRasterop(pixd, left, top, ws, hs, PIX_SET, pixs, 0, 0);

=head2 pixAddBorder

PIX * pixAddBorder ( PIX *pixs, l_int32 npix, l_uint32 val )

  pixAddBorder()

      Input:  pixs (all depths; colormap ok)
              npix (number of pixels to be added to each side)
              val  (value of added border pixels)
      Return: pixd (with the added exterior pixels), or null on error

  Notes:
      (1) See pixGetBlackOrWhiteVal() for values of black and white pixels.

=head2 pixAddBorderGeneral

PIX * pixAddBorderGeneral ( PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot, l_uint32 val )

  pixAddBorderGeneral()

      Input:  pixs (all depths; colormap ok)
              left, right, top, bot  (number of pixels added)
              val   (value of added border pixels)
      Return: pixd (with the added exterior pixels), or null on error

  Notes:
      (1) For binary images:
             white:  val = 0
             black:  val = 1
          For grayscale images:
             white:  val = 2 ** d - 1
             black:  val = 0
          For rgb color images:
             white:  val = 0xffffff00
             black:  val = 0
          For colormapped images, set val to the appropriate colormap index.
      (2) If the added border is either black or white, you can use
             pixAddBlackOrWhiteBorder()
          The black and white values for all images can be found with
             pixGetBlackOrWhiteVal()
          which, if pixs is cmapped, may add an entry to the colormap.
          Alternatively, if pixs has a colormap, you can find the index
          of the pixel whose intensity is closest to white or black:
             white: pixcmapGetRankIntensity(cmap, 1.0, &index);
             black: pixcmapGetRankIntensity(cmap, 0.0, &index);
          and use that for val.

=head2 pixAddContinuedBorder

PIX * pixAddContinuedBorder ( PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  pixAddContinuedBorder()

      Input:  pixs
              left, right, top, bot (pixels on each side to be added)
      Return: pixd, or null on error

  Notes:
      (1) This adds pixels on each side whose values are equal to
          the value on the closest boundary pixel.

=head2 pixAddMirroredBorder

PIX * pixAddMirroredBorder ( PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  pixAddMirroredBorder()

      Input:  pixs (all depths; colormap ok)
              left, right, top, bot (number of pixels added)
      Return: pixd, or null on error

  Notes:
      (1) This applies what is effectively mirror boundary conditions.
          For the added border pixels in pixd, the pixels in pixs
          near the border are mirror-copied into the border region.
      (2) This is useful for avoiding special operations near
          boundaries when doing image processing operations
          such as rank filters and convolution.  In use, one first
          adds mirrored pixels to each side of the image.  The number
          of pixels added on each side is half the filter dimension.
          Then the image processing operations proceed over a
          region equal to the size of the original image, and
          write directly into a dest pix of the same size as pixs.
      (3) The general pixRasterop() is used for an in-place operation here
          because there is no overlap between the src and dest rectangles.

=head2 pixAddMixedBorder

PIX * pixAddMixedBorder ( PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  pixAddMixedBorder()

      Input:  pixs (all depths; colormap ok)
              left, right, top, bot (number of pixels added)
      Return: pixd, or null on error

  Notes:
      (1) This applies mirrored boundary conditions horizontally
          and repeated b.c. vertically.
      (2) It is specifically used for avoiding special operations
          near boundaries when convolving a hue-saturation histogram
          with a given window size.  The repeated b.c. are used
          vertically for hue, and the mirrored b.c. are used
          horizontally for saturation.  The number of pixels added
          on each side is approximately (but not quite) half the
          filter dimension.  The image processing operations can
          then proceed over a region equal to the size of the original
          image, and write directly into a dest pix of the same
          size as pixs.
      (3) The general pixRasterop() can be used for an in-place
          operation here because there is no overlap between the
          src and dest rectangles.

=head2 pixAddRepeatedBorder

PIX * pixAddRepeatedBorder ( PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  pixAddRepeatedBorder()

      Input:  pixs (all depths; colormap ok)
              left, right, top, bot (number of pixels added)
      Return: pixd, or null on error

  Notes:
      (1) This applies a repeated border, as if the central part of
          the image is tiled over the plane.  So, for example, the
          pixels in the left border come from the right side of the image.
      (2) The general pixRasterop() is used for an in-place operation here
          because there is no overlap between the src and dest rectangles.

=head2 pixAlphaIsOpaque

l_int32 pixAlphaIsOpaque ( PIX *pix, l_int32 *popaque )

  pixAlphaIsOpaque()

      Input:  pix (32 bpp, spp == 4)
              &opaque (<return> 1 if spp == 4 and all alpha component
                       values are 255 (opaque); 0 otherwise)
      Return: 0 if OK, 1 on error
      Notes:
          (1) On error, opaque is returned as 0 (FALSE).

=head2 pixBlendInRect

l_int32 pixBlendInRect ( PIX *pixs, BOX *box, l_uint32 val, l_float32 fract )

  pixBlendInRect()

      Input:  pixs (32 bpp rgb)
              box (<optional> in which all pixels will be blended)
              val  (blend value; 0xrrggbb00)
              fract (fraction of color to be blended with each pixel in pixs)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This is an in-place function.  It blends the input color @val
          with the pixels in pixs in the specified rectangle.
          If no rectangle is specified, it blends over the entire image.

=head2 pixCleanupByteProcessing

l_int32 pixCleanupByteProcessing ( PIX *pix, l_uint8 **lineptrs )

  pixCleanupByteProcessing()

      Input:  pix (8 bpp, no colormap)
              lineptrs (ptrs to the beginning of each raster line of data)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This must be called after processing that was initiated
          by pixSetupByteProcessing() has finished.

=head2 pixClearAll

l_int32 pixClearAll ( PIX *pix )

  pixClearAll()

      Input:  pix (all depths; use cmapped with caution)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Clears all data to 0.  For 1 bpp, this is white; for grayscale
          or color, this is black.
      (2) Caution: for colormapped pix, this sets the color to the first
          one in the colormap.  Be sure that this is the intended color!

=head2 pixClearInRect

l_int32 pixClearInRect ( PIX *pix, BOX *box )

  pixClearInRect()

      Input:  pix (all depths; can be cmapped)
              box (in which all pixels will be cleared)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Clears all data in rect to 0.  For 1 bpp, this is white;
          for grayscale or color, this is black.
      (2) Caution: for colormapped pix, this sets the color to the first
          one in the colormap.  Be sure that this is the intended color!

=head2 pixClearPixel

l_int32 pixClearPixel ( PIX *pix, l_int32 x, l_int32 y )

  pixClearPixel()

      Input:  pix
              (x,y) pixel coords
      Return: 0 if OK; 1 on error.

=head2 pixCopyBorder

PIX * pixCopyBorder ( PIX *pixd, PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  pixCopyBorder()

      Input:  pixd (all depths; colormap ok; can be NULL)
              pixs (same depth and size as pixd)
              left, right, top, bot (number of pixels to copy)
      Return: pixd, or null on error if pixd is not defined

  Notes:
      (1) pixd can be null, but otherwise it must be the same size
          and depth as pixs.  Always returns pixd.
      (1) This is useful in situations where by setting a few border
          pixels we can avoid having to copy all pixels in pixs into
          pixd as an initialization step for some operation.

=head2 pixCopyRGBComponent

l_int32 pixCopyRGBComponent ( PIX *pixd, PIX *pixs, l_int32 comp )

  pixCopyRGBComponent()

      Input:  pixd (32 bpp)
              pixs (32 bpp)
              comp (one of the set: {COLOR_RED, COLOR_GREEN,
                                     COLOR_BLUE, L_ALPHA_CHANNEL})
      Return: 0 if OK; 1 on error

  Notes:
      (1) The two images are registered to the UL corner.  The sizes
          are usually the same, and a warning is issued if they differ.

=head2 pixCreateRGBImage

PIX * pixCreateRGBImage ( PIX *pixr, PIX *pixg, PIX *pixb )

  pixCreateRGBImage()

      Input:  8 bpp red pix
              8 bpp green pix
              8 bpp blue pix
      Return: 32 bpp pix, interleaved with 4 samples/pixel,
              or null on error

  Notes:
      (1) the 4th byte, sometimes called the "alpha channel",
          and which is often used for blending between different
          images, is left with 0 value.
      (2) see Note (4) in pix.h for details on storage of
          8-bit samples within each 32-bit word.
      (3) This implementation, setting the r, g and b components
          sequentially, is much faster than setting them in parallel
          by constructing an RGB dest pixel and writing it to dest.
          The reason is there are many more cache misses when reading
          from 3 input images simultaneously.

=head2 pixDisplayLayersRGBA

PIX * pixDisplayLayersRGBA ( PIX *pixs, l_uint32 val, l_int32 maxw )

  pixDisplayLayersRGBA()

      Input:  pixs (cmap or 32 bpp rgba)
              val (32 bit unsigned color to use as background)
              maxw (max output image width; 0 for no scaling)
      Return: pixd (showing various image views), or null on error

  Notes:
      (1) Use @val == 0xffffff00 for white background.
      (2) Three views are given:
           - the image with a fully opaque alpha
           - the alpha layer
           - the image as it would appear with a white background.

=head2 pixEndianByteSwap

l_int32 pixEndianByteSwap ( PIX *pixs )

  pixEndianByteSwap()

      Input:  pixs
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is used on little-endian platforms to swap
          the bytes within a word; bytes 0 and 3 are swapped,
          and bytes 1 and 2 are swapped.
      (2) This is required for little-endians in situations
          where we convert from a serialized byte order that is
          in raster order, as one typically has in file formats,
          to one with MSB-to-the-left in each 32-bit word, or v.v.
          See pix.h for a description of the canonical format
          (MSB-to-the left) that is used for both little-endian
          and big-endian platforms.   For big-endians, the
          MSB-to-the-left word order has the bytes in raster
          order when serialized, so no byte flipping is required.

=head2 pixEndianByteSwapNew

PIX * pixEndianByteSwapNew ( PIX *pixs )

  pixEndianByteSwapNew()

      Input:  pixs
      Return: pixd, or null on error

  Notes:
      (1) This is used to convert the data in a pix to a
          serialized byte buffer in raster order, and, for RGB,
          in order RGBA.  This requires flipping bytes within
          each 32-bit word for little-endian platforms, because the
          words have a MSB-to-the-left rule, whereas byte raster-order
          requires the left-most byte in each word to be byte 0.
          For big-endians, no swap is necessary, so this returns a clone.
      (2) Unlike pixEndianByteSwap(), which swaps the bytes in-place,
          this returns a new pix (or a clone).  We provide this
          because often when serialization is done, the source
          pix needs to be restored to canonical little-endian order,
          and this requires a second byte swap.  In such a situation,
          it is twice as fast to make a new pix in big-endian order,
          use it, and destroy it.

=head2 pixEndianTwoByteSwap

l_int32 pixEndianTwoByteSwap ( PIX *pixs )

  pixEndianTwoByteSwap()

      Input:  pixs
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is used on little-endian platforms to swap the
          2-byte entities within a 32-bit word.
      (2) This is equivalent to a full byte swap, as performed
          by pixEndianByteSwap(), followed by byte swaps in
          each of the 16-bit entities separately.

=head2 pixEndianTwoByteSwapNew

PIX * pixEndianTwoByteSwapNew ( PIX *pixs )

  pixEndianTwoByteSwapNew()

      Input:  pixs
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is used on little-endian platforms to swap the
          2-byte entities within a 32-bit word.
      (2) This is equivalent to a full byte swap, as performed
          by pixEndianByteSwap(), followed by byte swaps in
          each of the 16-bit entities separately.
      (3) Unlike pixEndianTwoByteSwap(), which swaps the shorts in-place,
          this returns a new pix (or a clone).  We provide this
          to avoid having to swap twice in situations where the input
          pix must be restored to canonical little-endian order.

=head2 pixFlipPixel

l_int32 pixFlipPixel ( PIX *pix, l_int32 x, l_int32 y )

  pixFlipPixel()

      Input:  pix
              (x,y) pixel coords
      Return: 0 if OK; 1 on error

=head2 pixGetBlackOrWhiteVal

l_int32 pixGetBlackOrWhiteVal ( PIX *pixs, l_int32 op, l_uint32 *pval )

  pixGetBlackOrWhiteVal()

      Input:  pixs (all depths; cmap ok)
              op (L_GET_BLACK_VAL, L_GET_WHITE_VAL)
              &val (<return> pixel value)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Side effect.  For a colormapped image, if the requested
          color is not present and there is room to add it in the cmap,
          it is added and the new index is returned.  If there is no room,
          the index of the closest color in intensity is returned.

=head2 pixGetPixel

l_int32 pixGetPixel ( PIX *pix, l_int32 x, l_int32 y, l_uint32 *pval )

  pixGetPixel()

      Input:  pix
              (x,y) pixel coords
              &val (<return> pixel value)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This returns the value in the data array.  If the pix is
          colormapped, it returns the colormap index, not the rgb value.
      (2) Because of the function overhead and the parameter checking,
          this is much slower than using the GET_DATA_*() macros directly.
          Speed on a 1 Mpixel RGB image, using a 3 GHz machine:
            * pixGet/pixSet: ~25 Mpix/sec
            * GET_DATA/SET_DATA: ~350 MPix/sec
          If speed is important and you're doing random access into
          the pix, use pixGetLinePtrs() and the array access macros.

=head2 pixGetRGBComponent

PIX * pixGetRGBComponent ( PIX *pixs, l_int32 comp )

  pixGetRGBComponent()

      Input:  pixs (32 bpp, or colormapped)
              comp (one of {COLOR_RED, COLOR_GREEN, COLOR_BLUE,
                    L_ALPHA_CHANNEL})
      Return: pixd (the selected 8 bpp component image of the
                    input 32 bpp image) or null on error

  Notes:
      (1) Three calls to this function generate the r, g and b 8 bpp
          component images.  This is much faster than generating the
          three images in parallel, by extracting a src pixel and setting
          the pixels of each component image from it.  The reason is
          there are many more cache misses when writing to three
          output images simultaneously.

=head2 pixGetRGBComponentCmap

PIX * pixGetRGBComponentCmap ( PIX *pixs, l_int32 comp )

  pixGetRGBComponentCmap()

      Input:  pixs  (colormapped)
              comp  (one of the set: {COLOR_RED, COLOR_GREEN, COLOR_BLUE})
      Return: pixd  (the selected 8 bpp component image of the
                     input cmapped image), or null on error

  Notes:
      (1) In leptonica, we do not support alpha in colormaps.

=head2 pixGetRGBLine

l_int32 pixGetRGBLine ( PIX *pixs, l_int32 row, l_uint8 *bufr, l_uint8 *bufg, l_uint8 *bufb )

  pixGetRGBLine()

      Input:  pixs  (32 bpp)
              row
              bufr  (array of red samples; size w bytes)
              bufg  (array of green samples; size w bytes)
              bufb  (array of blue samples; size w bytes)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This puts rgb components from the input line in pixs
          into the given buffers.

=head2 pixGetRGBPixel

l_int32 pixGetRGBPixel ( PIX *pix, l_int32 x, l_int32 y, l_int32 *prval, l_int32 *pgval, l_int32 *pbval )

  pixGetRGBPixel()

      Input:  pix (32 bpp rgb, not colormapped)
              (x,y) pixel coords
              &rval (<optional return> red component)
              &gval (<optional return> green component)
              &bval (<optional return> blue component)
      Return: 0 if OK; 1 on error

=head2 pixGetRandomPixel

l_int32 pixGetRandomPixel ( PIX *pix, l_uint32 *pval, l_int32 *px, l_int32 *py )

  pixGetRandomPixel()

      Input:  pix (any depth; can be colormapped)
              &val (<return> pixel value)
              &x (<optional return> x coordinate chosen; can be null)
              &y (<optional return> y coordinate chosen; can be null)
      Return: 0 if OK; 1 on error

  Notes:
      (1) If the pix is colormapped, it returns the rgb value.

=head2 pixGetRasterData

l_int32 pixGetRasterData ( PIX *pixs, l_uint8 **pdata, size_t *pnbytes )

  pixGetRasterData()

      Input:  pixs (1, 8, 32 bpp)
              &data (<return> raster data in memory)
              &nbytes (<return> number of bytes in data string)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This returns the raster data as a byte string, padded to the
          byte.  For 1 bpp, the first pixel is the MSbit in the first byte.
          For rgb, the bytes are in (rgb) order.  This is the format
          required for flate encoding of pixels in a PostScript file.

=head2 pixRemoveBorder

PIX * pixRemoveBorder ( PIX *pixs, l_int32 npix )

  pixRemoveBorder()

      Input:  pixs (all depths; colormap ok)
              npix (number to be removed from each of the 4 sides)
      Return: pixd (with pixels removed around border), or null on error

=head2 pixRemoveBorderGeneral

PIX * pixRemoveBorderGeneral ( PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  pixRemoveBorderGeneral()

      Input:  pixs (all depths; colormap ok)
              left, right, top, bot  (number of pixels added)
      Return: pixd (with pixels removed around border), or null on error

=head2 pixRemoveBorderToSize

PIX * pixRemoveBorderToSize ( PIX *pixs, l_int32 wd, l_int32 hd )

  pixRemoveBorderToSize()

      Input:  pixs (all depths; colormap ok)
              wd  (target width; use 0 if only removing from height)
              hd  (target height; use 0 if only removing from width)
      Return: pixd (with pixels removed around border), or null on error

  Notes:
      (1) Removes pixels as evenly as possible from the sides of the
          image, leaving the central part.
      (2) Returns clone if no pixels requested removed, or the target
          sizes are larger than the image.

=head2 pixSetAll

l_int32 pixSetAll ( PIX *pix )

  pixSetAll()

      Input:  pix (all depths; use cmapped with caution)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Sets all data to 1.  For 1 bpp, this is black; for grayscale
          or color, this is white.
      (2) Caution: for colormapped pix, this sets the pixel value to the
          maximum value supported by the colormap: 2^d - 1.  However, this
          color may not be defined, because the colormap may not be full.

=head2 pixSetAllArbitrary

l_int32 pixSetAllArbitrary ( PIX *pix, l_uint32 val )

  pixSetAllArbitrary()

      Input:  pix (all depths; use cmapped with caution)
              val  (value to set all pixels)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Caution!  For colormapped pix, @val is used as an index
          into a colormap.  Be sure that index refers to the intended color.
          If the color is not in the colormap, you should first add it
          and then call this function.

=head2 pixSetAllGray

l_int32 pixSetAllGray ( PIX *pix, l_int32 grayval )

  pixSetAllGray()

      Input:  pix (all depths, cmap ok)
              grayval (in range 0 ... 255)
      Return: 0 if OK; 1 on error

  Notes:
      (1) N.B.  For all images, @grayval == 0 represents black and
          @grayval == 255 represents white.
      (2) For depth < 8, we do our best to approximate the gray level.
          For 1 bpp images, any @grayval < 128 is black; >= 128 is white.
          For 32 bpp images, each r,g,b component is set to @grayval,
          and the alpha component is preserved.
      (3) If pix is colormapped, it adds the gray value, replicated in
          all components, to the colormap if it's not there and there
          is room.  If the colormap is full, it finds the closest color in
          L2 distance of components.  This index is written to all pixels.

=head2 pixSetBlackOrWhite

l_int32 pixSetBlackOrWhite ( PIX *pixs, l_int32 op )

  pixSetBlackOrWhite()

      Input:  pixs (all depths; cmap ok)
              op (L_SET_BLACK, L_SET_WHITE)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Function for setting all pixels in an image to either black
          or white.
      (2) If pixs is colormapped, it adds black or white to the
          colormap if it's not there and there is room.  If the colormap
          is full, it finds the closest color in intensity.
          This index is written to all pixels.

=head2 pixSetBorderRingVal

l_int32 pixSetBorderRingVal ( PIX *pixs, l_int32 dist, l_uint32 val )

  pixSetBorderRingVal()

      Input:  pixs (any depth; cmap OK)
              dist (distance from outside; must be > 0; first ring is 1)
              val (value to set at each border pixel)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The rings are single-pixel-wide rectangular sets of
          pixels at a given distance from the edge of the pix.
          This sets all pixels in a given ring to a value.

=head2 pixSetBorderVal

l_int32 pixSetBorderVal ( PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot, l_uint32 val )

  pixSetBorderVal()

      Input:  pixs (8, 16 or 32 bpp)
              left, right, top, bot (amount to set)
              val (value to set at each border pixel)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The border region is defined to be the region in the
          image within a specific distance of each edge.  Here, we
          allow the pixels within a specified distance of each
          edge to be set independently.  This sets the pixels
          in the border region to the given input value.
      (2) For efficiency, use pixSetOrClearBorder() if
          you're setting the border to either black or white.
      (3) If d != 32, the input value should be masked off
          to the appropriate number of least significant bits.
      (4) The code is easily generalized for 2 or 4 bpp.

=head2 pixSetComponentArbitrary

l_int32 pixSetComponentArbitrary ( PIX *pix, l_int32 comp, l_int32 val )

  pixSetComponentArbitrary()

      Input:  pix (32 bpp)
              comp (COLOR_RED, COLOR_GREEN, COLOR_BLUE, L_ALPHA_CHANNEL)
              val  (value to set this component)
      Return: 0 if OK; 1 on error

  Notes:
      (1) For example, this can be used to set the alpha component to opaque:
              pixSetComponentArbitrary(pix, L_ALPHA_CHANNEL, 255)

=head2 pixSetInRect

l_int32 pixSetInRect ( PIX *pix, BOX *box )

  pixSetInRect()

      Input:  pix (all depths, can be cmapped)
              box (in which all pixels will be set)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Sets all data in rect to 1.  For 1 bpp, this is black;
          for grayscale or color, this is white.
      (2) Caution: for colormapped pix, this sets the pixel value to the
          maximum value supported by the colormap: 2^d - 1.  However, this
          color may not be defined, because the colormap may not be full.

=head2 pixSetInRectArbitrary

l_int32 pixSetInRectArbitrary ( PIX *pix, BOX *box, l_uint32 val )

  pixSetInRectArbitrary()

      Input:  pix (all depths; can be cmapped)
              box (in which all pixels will be set to val)
              val  (value to set all pixels)
      Return: 0 if OK; 1 on error

  Notes:
      (1) For colormapped pix, be sure the value is the intended
          one in the colormap.
      (2) Caution: for colormapped pix, this sets each pixel in the
          rect to the color at the index equal to val.  Be sure that
          this index exists in the colormap and that it is the intended one!

=head2 pixSetMirroredBorder

l_int32 pixSetMirroredBorder ( PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot )

  pixSetMirroredBorder()

      Input:  pixs (all depths; colormap ok)
              left, right, top, bot (number of pixels to set)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This applies what is effectively mirror boundary conditions
          to a border region in the image.  It is in-place.
      (2) This is useful for setting pixels near the border to a
          value representative of the near pixels to the interior.
      (3) The general pixRasterop() is used for an in-place operation here
          because there is no overlap between the src and dest rectangles.

=head2 pixSetOrClearBorder

l_int32 pixSetOrClearBorder ( PIX *pixs, l_int32 left, l_int32 right, l_int32 top, l_int32 bot, l_int32 op )

  pixSetOrClearBorder()

      Input:  pixs (all depths)
              left, right, top, bot (amount to set or clear)
              operation (PIX_SET or PIX_CLR)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The border region is defined to be the region in the
          image within a specific distance of each edge.  Here, we
          allow the pixels within a specified distance of each
          edge to be set independently.  This either sets or
          clears all pixels in the border region.
      (2) For binary images, use PIX_SET for black and PIX_CLR for white.
      (3) For grayscale or color images, use PIX_SET for white
          and PIX_CLR for black.

=head2 pixSetPadBits

l_int32 pixSetPadBits ( PIX *pix, l_int32 val )

  pixSetPadBits()

      Input:  pix (1, 2, 4, 8, 16, 32 bpp)
              val  (0 or 1)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The pad bits are the bits that expand each scanline to a
          multiple of 32 bits.  They are usually not used in
          image processing operations.  When boundary conditions
          are important, as in seedfill, they must be set properly.
      (2) This sets the value of the pad bits (if any) in the last
          32-bit word in each scanline.
      (3) For 32 bpp pix, there are no pad bits, so this is a no-op.

=head2 pixSetPadBitsBand

l_int32 pixSetPadBitsBand ( PIX *pix, l_int32 by, l_int32 bh, l_int32 val )

  pixSetPadBitsBand()

      Input:  pix (1, 2, 4, 8, 16, 32 bpp)
              by  (starting y value of band)
              bh  (height of band)
              val  (0 or 1)
      Return: 0 if OK; 1 on error

  Notes:
      (1) The pad bits are the bits that expand each scanline to a
          multiple of 32 bits.  They are usually not used in
          image processing operations.  When boundary conditions
          are important, as in seedfill, they must be set properly.
      (2) This sets the value of the pad bits (if any) in the last
          32-bit word in each scanline, within the specified
          band of raster lines.
      (3) For 32 bpp pix, there are no pad bits, so this is a no-op.

=head2 pixSetPixel

l_int32 pixSetPixel ( PIX *pix, l_int32 x, l_int32 y, l_uint32 val )

  pixSetPixel()

      Input:  pix
              (x,y) pixel coords
              val (value to be inserted)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Warning: the input value is not checked for overflow with respect
          the the depth of @pix, and the sign bit (if any) is ignored.
          * For d == 1, @val > 0 sets the bit on.
          * For d == 2, 4, 8 and 16, @val is masked to the maximum allowable
            pixel value, and any (invalid) higher order bits are discarded.
      (2) See pixGetPixel() for information on performance.

=head2 pixSetRGBComponent

l_int32 pixSetRGBComponent ( PIX *pixd, PIX *pixs, l_int32 comp )

  pixSetRGBComponent()

      Input:  pixd  (32 bpp)
              pixs  (8 bpp)
              comp  (one of the set: {COLOR_RED, COLOR_GREEN,
                                      COLOR_BLUE, L_ALPHA_CHANNEL})
      Return: 0 if OK; 1 on error

  Notes:
      (1) This places the 8 bpp pixel in pixs into the
          specified component (properly interleaved) in pixd,
      (2) The two images are registered to the UL corner; the sizes
          need not be the same, but a warning is issued if they differ.

=head2 pixSetRGBPixel

l_int32 pixSetRGBPixel ( PIX *pix, l_int32 x, l_int32 y, l_int32 rval, l_int32 gval, l_int32 bval )

  pixSetRGBPixel()

      Input:  pix (32 bpp rgb)
              (x,y) pixel coords
              rval (red component)
              gval (green component)
              bval (blue component)
      Return: 0 if OK; 1 on error

=head2 pixSetupByteProcessing

l_uint8 ** pixSetupByteProcessing ( PIX *pix, l_int32 *pw, l_int32 *ph )

  pixSetupByteProcessing()

      Input:  pix (8 bpp, no colormap)
              &w (<optional return> width)
              &h (<optional return> height)
      Return: line ptr array, or null on error

  Notes:
      (1) This is a simple helper for processing 8 bpp images with
          direct byte access.  It can swap byte order within each word.
      (2) After processing, you must call pixCleanupByteProcessing(),
          which frees the lineptr array and restores byte order.
      (3) Usage:
              l_uint8 **lineptrs = pixSetupByteProcessing(pix, &w, &h);
              for (i = 0; i < h; i++) {
                  l_uint8 *line = lineptrs[i];
                  for (j = 0; j < w; j++) {
                      val = line[j];
                      ...
                  }
              }
              pixCleanupByteProcessing(pix, lineptrs);

=head2 pixShiftAndTransferAlpha

l_int32 pixShiftAndTransferAlpha ( PIX *pixd, PIX *pixs, l_float32 shiftx, l_float32 shifty )

  pixShiftAndTransferAlpha()

      Input:  pixd  (32 bpp)
              pixs  (32 bpp)
              shiftx, shifty
      Return: 0 if OK; 1 on error

=head2 setPixelLow

void setPixelLow ( l_uint32 *line, l_int32 x, l_int32 depth, l_uint32 val )

  setPixelLow()

      Input:  line (ptr to beginning of line),
              x (pixel location in line)
              depth (bpp)
              val (to be inserted)
      Return: void

  Notes:
      (1) Caution: input variables are not checked!

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
