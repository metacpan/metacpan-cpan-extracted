package Image::Leptonica::Func::pix1;
$Image::Leptonica::Func::pix1::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pix1

=head1 VERSION

version 0.04

=head1 C<pix1.c>

  pix1.c

    The pixN.c {N = 1,2,3,4,5} files are sorted by the type of operation.
    The primary functions in these files are:

        pix1.c: constructors, destructors and field accessors
        pix2.c: pixel poking of image, pad and border pixels
        pix3.c: masking and logical ops, counting, mirrored tiling
        pix4.c: histograms, statistics, fg/bg estimation
        pix5.c: property measurements, rectangle extraction


    This file has the basic constructors, destructors and field accessors

    Pix memory management (allows custom allocator and deallocator)
          static void  *pix_malloc()
          static void   pix_free()
          void          setPixMemoryManager()

    Pix creation
          PIX          *pixCreate()
          PIX          *pixCreateNoInit()
          PIX          *pixCreateTemplate()
          PIX          *pixCreateTemplateNoInit()
          PIX          *pixCreateHeader()
          PIX          *pixClone()

    Pix destruction
          void          pixDestroy()
          static void   pixFree()

    Pix copy
          PIX          *pixCopy()
          l_int32       pixResizeImageData()
          l_int32       pixCopyColormap()
          l_int32       pixSizesEqual()
          l_int32       pixTransferAllData()
          l_int32       pixSwapAndDestroy()

    Pix accessors
          l_int32       pixGetWidth()
          l_int32       pixSetWidth()
          l_int32       pixGetHeight()
          l_int32       pixSetHeight()
          l_int32       pixGetDepth()
          l_int32       pixSetDepth()
          l_int32       pixGetDimensions()
          l_int32       pixSetDimensions()
          l_int32       pixCopyDimensions()
          l_int32       pixGetSpp()
          l_int32       pixSetSpp()
          l_int32       pixCopySpp()
          l_int32       pixGetWpl()
          l_int32       pixSetWpl()
          l_int32       pixGetRefcount()
          l_int32       pixChangeRefcount()
          l_uint32      pixGetXRes()
          l_int32       pixSetXRes()
          l_uint32      pixGetYRes()
          l_int32       pixSetYRes()
          l_int32       pixGetResolution()
          l_int32       pixSetResolution()
          l_int32       pixCopyResolution()
          l_int32       pixScaleResolution()
          l_int32       pixGetInputFormat()
          l_int32       pixSetInputFormat()
          l_int32       pixCopyInputFormat()
          char         *pixGetText()
          l_int32       pixSetText()
          l_int32       pixAddText()
          l_int32       pixCopyText()
          PIXCMAP      *pixGetColormap()
          l_int32       pixSetColormap()
          l_int32       pixDestroyColormap()
          l_uint32     *pixGetData()
          l_int32       pixSetData()
          l_uint32     *pixExtractData()
          l_int32       pixFreeData()

    Pix line ptrs
          void        **pixGetLinePtrs()

    Pix debug
          l_int32       pixPrintStreamInfo()


  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      Important notes on direct management of pix image data
  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

  Custom allocator and deallocator
  --------------------------------

  At the lowest level, you can specify the function that does the
  allocation and deallocation of the data field in the pix.
  By default, this is malloc and free.  However, by calling
  setPixMemoryManager(), custom functions can be substituted.
  When using this, keep two things in mind:

   (1) Call setPixMemoryManager() before any pix have been allocated
   (2) Destroy all pix as usual, in order to prevent leaks.

  In pixalloc.c, we provide an example custom allocator and deallocator.
  To use it, you must call pmsCreate() before any pix have been allocated
  and pmsDestroy() at the end after all pix have been destroyed.


  Direct manipulation of the pix data field
  -----------------------------------------

  Memory management of the (image) data field in the pix is
  handled differently from that in the colormap or text fields.
  For colormap and text, the functions pixSetColormap() and
  pixSetText() remove the existing heap data and insert the
  new data.  For the image data, pixSetData() just reassigns the
  data field; any existing data will be lost if there isn't
  another handle for it.

  Why is pixSetData() limited in this way?  Because the image
  data can be very large, we need flexible ways to handle it,
  particularly when you want to re-use the data in a different
  context without making a copy.  Here are some different
  things you might want to do:

  (1) Use pixCopy(pixd, pixs) where pixd is not the same size
      as pixs.  This will remove the data in pixd, allocate a
      new data field in pixd, and copy the data from pixs, leaving
      pixs unchanged.

  (2) Use pixTransferAllData(pixd, &pixs, ...) to transfer the
      data from pixs to pixd without making a copy of it.  If
      pixs is not cloned, this will do the transfer and destroy pixs.
      But if the refcount of pixs is greater than 1, it just copies
      the data and decrements the ref count.

  (3) Use pixSwapAndDestroy(pixd, &pixs) to replace pixs by an
      existing pixd.  This is similar to pixTransferAllData(), but
      simpler, in that it never makes any copies and if pixs is
      cloned, the other references are not changed by this operation.

  (4) Use pixExtractData() to extract the image data from the pix
      without copying if possible.  This could be used, for example,
      to convert from a pix to some other data structure with minimal
      heap allocation.  After the data is extracated, the pixels can
      be munged and used in another context.  However, the danger
      here is that the pix might have a refcount > 1, in which case
      a copy of the data must be made and the input pix left unchanged.
      If there are no clones, the image data can be extracted without
      a copy, and the data ptr in the pix must be nulled before
      destroying it because the pix will no longer 'own' the data.

  We have provided accessors and functions here that should be
  sufficient so that you can do anything you want without
  explicitly referencing any of the pix member fields.

  However, to avoid memory smashes and leaks when doing special operations
  on the pix data field, look carefully at the behavior of the image
  data accessors and keep in mind that when you invoke pixDestroy(),
  the pix considers itself the owner of all its heap data.

=head1 FUNCTIONS

=head2 pixAddText

l_int32 pixAddText ( PIX *pix, const char *textstring )

  pixAddText()

      Input:  pix
              textstring
      Return: 0 if OK, 1 on error

  Notes:
      (1) This adds the new textstring to any existing text.
      (2) Either or both the existing text and the new text
          string can be null.

=head2 pixClone

PIX * pixClone ( PIX *pixs )

  pixClone()

      Input:  pix
      Return: same pix (ptr), or null on error

  Notes:
      (1) A "clone" is simply a handle (ptr) to an existing pix.
          It is implemented because (a) images can be large and
          hence expensive to copy, and (b) extra handles to a data
          structure need to be made with a simple policy to avoid
          both double frees and memory leaks.  Pix are reference
          counted.  The side effect of pixClone() is an increase
          by 1 in the ref count.
      (2) The protocol to be used is:
          (a) Whenever you want a new handle to an existing image,
              call pixClone(), which just bumps a ref count.
          (b) Always call pixDestroy() on all handles.  This
              decrements the ref count, nulls the handle, and
              only destroys the pix when pixDestroy() has been
              called on all handles.

=head2 pixCopy

PIX * pixCopy ( PIX *pixd, PIX *pixs )

  pixCopy()

      Input:  pixd (<optional>; can be null, or equal to pixs,
                    or different from pixs)
              pixs
      Return: pixd, or null on error

  Notes:
      (1) There are three cases:
            (a) pixd == null  (makes a new pix; refcount = 1)
            (b) pixd == pixs  (no-op)
            (c) pixd != pixs  (data copy; no change in refcount)
          If the refcount of pixd > 1, case (c) will side-effect
          these handles.
      (2) The general pattern of use is:
             pixd = pixCopy(pixd, pixs);
          This will work for all three cases.
          For clarity when the case is known, you can use:
            (a) pixd = pixCopy(NULL, pixs);
            (c) pixCopy(pixd, pixs);
      (3) For case (c), we check if pixs and pixd are the same
          size (w,h,d).  If so, the data is copied directly.
          Otherwise, the data is reallocated to the correct size
          and the copy proceeds.  The refcount of pixd is unchanged.
      (4) This operation, like all others that may involve a pre-existing
          pixd, will side-effect any existing clones of pixd.

=head2 pixCopyColormap

l_int32 pixCopyColormap ( PIX *pixd, PIX *pixs )

  pixCopyColormap()

      Input:  src and dest Pix
      Return: 0 if OK, 1 on error

  Notes:
      (1) This always destroys any colormap in pixd (except if
          the operation is a no-op.

=head2 pixCopyDimensions

l_int32 pixCopyDimensions ( PIX *pixd, PIX *pixs )

  pixCopyDimensions()

      Input:  pixd
              pixd
      Return: 0 if OK, 1 on error

=head2 pixCopySpp

l_int32 pixCopySpp ( PIX *pixd, PIX *pixs )

  pixCopySpp()

      Input:  pixd
              pixs
      Return: 0 if OK, 1 on error

=head2 pixCreate

PIX * pixCreate ( l_int32 width, l_int32 height, l_int32 depth )

  pixCreate()

      Input:  width, height, depth
      Return: pixd (with data allocated and initialized to 0),
                    or null on error

=head2 pixCreateHeader

PIX * pixCreateHeader ( l_int32 width, l_int32 height, l_int32 depth )

  pixCreateHeader()

      Input:  width, height, depth
      Return: pixd (with no data allocated), or null on error

  Notes:
      (1) It is assumed that all 32 bit pix have 3 spp.  If there is
          a valid alpha channel, this will be set to 4 spp later.
      (2) If the number of bytes to be allocated is larger than the
          maximum value in an int32, we can get overflow, resulting
          in a smaller amount of memory actually being allocated.
          Later, an attempt to access memory that wasn't allocated will
          cause a crash.  So to avoid crashing a program (or worse)
          with bad (or malicious) input, this is where we limit the
          requested allocation of image data in a typesafe way.

=head2 pixCreateNoInit

PIX * pixCreateNoInit ( l_int32 width, l_int32 height, l_int32 depth )

  pixCreateNoInit()

      Input:  width, height, depth
      Return: pixd (with data allocated but not initialized),
                    or null on error

  Notes:
      (1) Must set pad bits to avoid reading unitialized data, because
          some optimized routines (e.g., pixConnComp()) read from pad bits.

=head2 pixCreateTemplate

PIX * pixCreateTemplate ( PIX *pixs )

  pixCreateTemplate()

      Input:  pixs
      Return: pixd, or null on error

  Notes:
      (1) Makes a Pix of the same size as the input Pix, with the
          data array allocated and initialized to 0.
      (2) Copies the other fields, including colormap if it exists.

=head2 pixCreateTemplateNoInit

PIX * pixCreateTemplateNoInit ( PIX *pixs )

  pixCreateTemplateNoInit()

      Input:  pixs
      Return: pixd, or null on error

  Notes:
      (1) Makes a Pix of the same size as the input Pix, with
          the data array allocated but not initialized to 0.
      (2) Copies the other fields, including colormap if it exists.

=head2 pixDestroy

void pixDestroy ( PIX **ppix )

  pixDestroy()

      Input:  &pix <will be nulled>
      Return: void

  Notes:
      (1) Decrements the ref count and, if 0, destroys the pix.
      (2) Always nulls the input ptr.

=head2 pixDestroyColormap

l_int32 pixDestroyColormap ( PIX *pix )

  pixDestroyColormap()

      Input:  pix
      Return: 0 if OK, 1 on error

=head2 pixExtractData

l_uint32 * pixExtractData ( PIX *pixs )

  pixExtractData()

  Notes:
      (1) This extracts the pix image data for use in another context.
          The caller still needs to use pixDestroy() on the input pix.
      (2) If refcount == 1, the data is extracted and the
          pix->data ptr is set to NULL.
      (3) If refcount > 1, this simply returns a copy of the data,
          using the pix allocator, and leaving the input pix unchanged.

=head2 pixFreeData

l_int32 pixFreeData ( PIX *pix )

  pixFreeData()

  Notes:
      (1) This frees the data and sets the pix data ptr to null.
          It should be used before pixSetData() in the situation where
          you want to free any existing data before doing
          a subsequent assignment with pixSetData().

=head2 pixGetData

l_uint32 * pixGetData ( PIX *pix )

  pixGetData()

  Notes:
      (1) This gives a new handle for the data.  The data is still
          owned by the pix, so do not call FREE() on it.

=head2 pixGetDimensions

l_int32 pixGetDimensions ( PIX *pix, l_int32 *pw, l_int32 *ph, l_int32 *pd )

  pixGetDimensions()

      Input:  pix
              &w, &h, &d (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 pixGetLinePtrs

void ** pixGetLinePtrs ( PIX *pix, l_int32 *psize )

  pixGetLinePtrs()

      Input:  pix
              &size (<optional return> array size, which is the pix height)
      Return: array of line ptrs, or null on error

  Notes:
      (1) This is intended to be used for fast random pixel access.
          For example, for an 8 bpp image,
              val = GET_DATA_BYTE(lines8[i], j);
          is equivalent to, but much faster than,
              pixGetPixel(pix, j, i, &val);
      (2) How much faster?  For 1 bpp, it's from 6 to 10x faster.
          For 8 bpp, it's an amazing 30x faster.  So if you are
          doing random access over a substantial part of the image,
          use this line ptr array.
      (3) When random access is used in conjunction with a stack,
          queue or heap, the overall computation time depends on
          the operations performed on each struct that is popped
          or pushed, and whether we are using a priority queue (O(logn))
          or a queue or stack (O(1)).  For example, for maze search,
          the overall ratio of time for line ptrs vs. pixGet/Set* is
             Maze type     Type                   Time ratio
               binary      queue                     0.4
               gray        heap (priority queue)     0.6
      (4) Because this returns a void** and the accessors take void*,
          the compiler cannot check the pointer types.  It is
          strongly recommended that you adopt a naming scheme for
          the returned ptr arrays that indicates the pixel depth.
          (This follows the original intent of Simonyi's "Hungarian"
          application notation, where naming is used proactively
          to make errors visibly obvious.)  By doing this, you can
          tell by inspection if the correct accessor is used.
          For example, for an 8 bpp pixg:
              void **lineg8 = pixGetLinePtrs(pixg, NULL);
              val = GET_DATA_BYTE(lineg8[i], j);  // fast access; BYTE, 8
              ...
              FREE(lineg8);  // don't forget this
      (5) These are convenient for accessing bytes sequentially in an
          8 bpp grayscale image.  People who write image processing code
          on 8 bpp images are accustomed to grabbing pixels directly out
          of the raster array.  Note that for little endians, you first
          need to reverse the byte order in each 32-bit word.
          Here's a typical usage pattern:
              pixEndianByteSwap(pix);   // always safe; no-op on big-endians
              l_uint8 **lineptrs = (l_uint8 **)pixGetLinePtrs(pix, NULL);
              pixGetDimensions(pix, &w, &h, NULL);
              for (i = 0; i < h; i++) {
                  l_uint8 *line = lineptrs[i];
                  for (j = 0; j < w; j++) {
                      val = line[j];
                      ...
                  }
              }
              pixEndianByteSwap(pix);  // restore big-endian order
              FREE(lineptrs);
          This can be done even more simply as follows:
              l_uint8 **lineptrs = pixSetupByteProcessing(pix, &w, &h);
              for (i = 0; i < h; i++) {
                  l_uint8 *line = lineptrs[i];
                  for (j = 0; j < w; j++) {
                      val = line[j];
                      ...
                  }
              }
              pixCleanupByteProcessing(pix, lineptrs);

=head2 pixGetResolution

l_int32 pixGetResolution ( PIX *pix, l_int32 *pxres, l_int32 *pyres )

  pixGetResolution()

      Input:  pix
              &xres, &yres (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 pixGetText

char * pixGetText ( PIX *pix )

  pixGetText()

      Input:  pix
      Return: ptr to existing text string

  Notes:
      (1) The text string belongs to the pix.  The caller must
          NOT free it!

=head2 pixPrintStreamInfo

l_int32 pixPrintStreamInfo ( FILE *fp, PIX *pix, const char *text )

  pixPrintStreamInfo()

      Input:  fp (file stream)
              pix
              text (<optional> identifying string; can be null)
      Return: 0 if OK, 1 on error

=head2 pixResizeImageData

l_int32 pixResizeImageData ( PIX *pixd, PIX *pixs )

  pixResizeImageData()

      Input:  pixd (gets new uninitialized buffer for image data)
              pixs (determines the size of the buffer; not changed)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This removes any existing image data from pixd and
          allocates an uninitialized buffer that will hold the
          amount of image data that is in pixs.

=head2 pixSetColormap

l_int32 pixSetColormap ( PIX *pix, PIXCMAP *colormap )

  pixSetColormap()

      Input:  pix
              colormap (to be assigned)
      Return: 0 if OK, 1 on error.

  Notes:
      (1) Unlike with the pix data field, pixSetColormap() destroys
          any existing colormap before assigning the new one.
          Because colormaps are not ref counted, it is important that
          the new colormap does not belong to any other pix.

=head2 pixSetData

l_int32 pixSetData ( PIX *pix, l_uint32 *data )

  pixSetData()

  Notes:
      (1) This does not free any existing data.  To free existing
          data, use pixFreeData() before pixSetData().

=head2 pixSetDimensions

l_int32 pixSetDimensions ( PIX *pix, l_int32 w, l_int32 h, l_int32 d )

  pixSetDimensions()

      Input:  pix
              w, h, d (use 0 to skip the setting for any of these)
      Return: 0 if OK, 1 on error

=head2 pixSetResolution

l_int32 pixSetResolution ( PIX *pix, l_int32 xres, l_int32 yres )

  pixSetResolution()

      Input:  pix
              xres, yres (use 0 to skip the setting for either of these)
      Return: 0 if OK, 1 on error

=head2 pixSetSpp

l_int32 pixSetSpp ( PIX *pix, l_int32 spp )

  pixSetSpp()
      Input:  pix
              spp (1, 3 or 4)
      Return: 0 if OK, 1 on error

  Notes:
      (1) For a 32 bpp pix, this can be used to ignore the
          alpha sample (spp == 3) or to use it (spp == 4).
          For example, to write a spp == 4 image without the alpha
          sample (as an rgb pix), call pixSetSpp(pix, 3) and
          then write it out as a png.

=head2 pixSetText

l_int32 pixSetText ( PIX *pix, const char *textstring )

  pixSetText()

      Input:  pix
              textstring (can be null)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This removes any existing textstring and puts a copy of
          the input textstring there.

=head2 pixSizesEqual

l_int32 pixSizesEqual ( PIX *pix1, PIX *pix2 )

  pixSizesEqual()

      Input:  two pix
      Return: 1 if the two pix have same {h, w, d}; 0 otherwise.

=head2 pixSwapAndDestroy

l_int32 pixSwapAndDestroy ( PIX **ppixd, PIX **ppixs )

  pixSwapAndDestroy()

      Input:  &pixd (<optional, return> input pixd can be null,
                     and it must be different from pixs)
              &pixs (will be nulled after the swap)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Simple operation to change the handle name safely.
          After this operation, the original image in pixd has
          been destroyed, pixd points to what was pixs, and
          the input pixs ptr has been nulled.
      (2) This works safely whether or not pixs and pixd are cloned.
          If pixs is cloned, the other handles still point to
          the original image, with the ref count reduced by 1.
      (3) Usage example:
            Pix *pix1 = pixRead("...");
            Pix *pix2 = function(pix1, ...);
            pixSwapAndDestroy(&pix1, &pix2);
            pixDestroy(&pix1);  // holds what was in pix2
          Example with clones ([] shows ref count of image generated
                               by the function):
            Pix *pixs = pixRead("...");
            Pix *pix1 = pixClone(pixs);
            Pix *pix2 = function(pix1, ...);   [1]
            Pix *pix3 = pixClone(pix2);   [1] --> [2]
            pixSwapAndDestroy(&pix1, &pix2);
            pixDestroy(&pixs);  // still holds read image
            pixDestroy(&pix1);  // holds what was in pix2  [2] --> [1]
            pixDestroy(&pix3);  // holds what was in pix2  [1] --> [0]

=head2 pixTransferAllData

l_int32 pixTransferAllData ( PIX *pixd, PIX **ppixs, l_int32 copytext, l_int32 copyformat )

  pixTransferAllData()

      Input:  pixd (must be different from pixs)
              &pixs (will be nulled if refcount goes to 0)
              copytext (1 to copy the text field; 0 to skip)
              copyformat (1 to copy the informat field; 0 to skip)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This does a complete data transfer from pixs to pixd,
          followed by the destruction of pixs (refcount permitting).
      (2) If the refcount of pixs is 1, pixs is destroyed.  Otherwise,
          the data in pixs is copied (rather than transferred) to pixd.
      (3) This operation, like all others with a pre-existing pixd,
          will side-effect any existing clones of pixd.  The pixd
          refcount does not change.
      (4) When might you use this?  Suppose you have an in-place Pix
          function (returning void) with the typical signature:
              void function-inplace(PIX *pix, ...)
          where "..." are non-pointer input parameters, and suppose
          further that you sometimes want to return an arbitrary Pix
          in place of the input Pix.  There are two ways you can do this:
          (a) The straightforward way is to change the function
              signature to take the address of the Pix ptr:
                  void function-inplace(PIX **ppix, ...) {
                      PIX *pixt = function-makenew(*ppix);
                      pixDestroy(ppix);
                      *ppix = pixt;
                      return;
                  }
              Here, the input and returned pix are different, as viewed
              by the calling function, and the inplace function is
              expected to destroy the input pix to avoid a memory leak.
          (b) Keep the signature the same and use pixTransferAllData()
              to return the new Pix in the input Pix struct:
                  void function-inplace(PIX *pix, ...) {
                      PIX *pixt = function-makenew(pix);
                      pixTransferAllData(pix, &pixt, 0, 0);
                               // pixDestroy() is called on pixt
                      return;
                  }
              Here, the input and returned pix are the same, as viewed
              by the calling function, and the inplace function must
              never destroy the input pix, because the calling function
              maintains an unchanged handle to it.

=head2 setPixMemoryManager

void setPixMemoryManager ( void * (  ( *allocator ) ( size_t ) ), void  (  ( *deallocator ) ( void * ) ) )

  setPixMemoryManager()

      Input: allocator (<optional>; use null to skip)
             deallocator (<optional>; use null to skip)
      Return: void

  Notes:
      (1) Use this to change the alloc and/or dealloc functions;
          e.g., setPixMemoryManager(my_malloc, my_free).
      (2) The C99 standard (section 6.7.5.3, par. 8) says:
            A declaration of a parameter as "function returning type"
            shall be adjusted to "pointer to function returning type"
          so that it can be in either of these two forms:
            (a) type (function-ptr(type, ...))
            (b) type ((*function-ptr)(type, ...))
          because form (a) is implictly converted to form (b), as in the
          definition of struct PixMemoryManager above.  So, for example,
          we should be able to declare either of these:
            (a) void *(allocator(size_t))
            (b) void *((*allocator)(size_t))
          However, MSVC++ only accepts the second version.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
