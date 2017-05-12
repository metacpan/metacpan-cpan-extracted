package Image::Leptonica::Func::fpix1;
$Image::Leptonica::Func::fpix1::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::fpix1

=head1 VERSION

version 0.04

=head1 C<fpix1.c>

  fpix1.c

    This file has basic constructors, destructors and field accessors
    for FPix, FPixa and DPix.  It also has uncompressed read/write.

    FPix Create/copy/destroy
          FPIX          *fpixCreate()
          FPIX          *fpixCreateTemplate()
          FPIX          *fpixClone()
          FPIX          *fpixCopy()
          l_int32        fpixResizeImageData()
          void           fpixDestroy()

    FPix accessors
          l_int32        fpixGetDimensions()
          l_int32        fpixSetDimensions()
          l_int32        fpixGetWpl()
          l_int32        fpixSetWpl()
          l_int32        fpixGetRefcount()
          l_int32        fpixChangeRefcount()
          l_int32        fpixGetResolution()
          l_int32        fpixSetResolution()
          l_int32        fpixCopyResolution()
          l_float32     *fpixGetData()
          l_int32        fpixSetData()
          l_int32        fpixGetPixel()
          l_int32        fpixSetPixel()

    FPixa Create/copy/destroy
          FPIXA         *fpixaCreate()
          FPIXA         *fpixaCopy()
          void           fpixaDestroy()

    FPixa addition
          l_int32        fpixaAddFPix()
          static l_int32 fpixaExtendArray()
          static l_int32 fpixaExtendArrayToSize()

    FPixa accessors
          l_int32        fpixaGetCount()
          l_int32        fpixaChangeRefcount()
          FPIX          *fpixaGetFPix()
          l_int32        fpixaGetFPixDimensions()
          l_int32        fpixaGetPixel()
          l_int32        fpixaSetPixel()

    DPix Create/copy/destroy
          DPIX          *dpixCreate()
          DPIX          *dpixCreateTemplate()
          DPIX          *dpixClone()
          DPIX          *dpixCopy()
          l_int32        dpixResizeImageData()
          void           dpixDestroy()

    DPix accessors
          l_int32        dpixGetDimensions()
          l_int32        dpixSetDimensions()
          l_int32        dpixGetWpl()
          l_int32        dpixSetWpl()
          l_int32        dpixGetRefcount()
          l_int32        dpixChangeRefcount()
          l_int32        dpixGetResolution()
          l_int32        dpixSetResolution()
          l_int32        dpixCopyResolution()
          l_float64     *dpixGetData()
          l_int32        dpixSetData()
          l_int32        dpixGetPixel()
          l_int32        dpixSetPixel()

    FPix serialized I/O
          FPIX          *fpixRead()
          FPIX          *fpixReadStream()
          l_int32        fpixWrite()
          l_int32        fpixWriteStream()
          FPIX          *fpixEndianByteSwap()

    DPix serialized I/O
          DPIX          *dpixRead()
          DPIX          *dpixReadStream()
          l_int32        dpixWrite()
          l_int32        dpixWriteStream()
          DPIX          *dpixEndianByteSwap()

    Print FPix (subsampled, for debugging)
          l_int32        fpixPrintStream()

=head1 FUNCTIONS

=head2 dpixClone

DPIX * dpixClone ( DPIX *dpix )

  dpixClone()

      Input:  dpix
      Return: same dpix (ptr), or null on error

  Notes:
      (1) See pixClone() for definition and usage.

=head2 dpixCopy

DPIX * dpixCopy ( DPIX *dpixd, DPIX *dpixs )

  dpixCopy()

      Input:  dpixd (<optional>; can be null, or equal to dpixs,
                    or different from dpixs)
              dpixs
      Return: dpixd, or null on error

  Notes:
      (1) There are three cases:
            (a) dpixd == null  (makes a new dpix; refcount = 1)
            (b) dpixd == dpixs  (no-op)
            (c) dpixd != dpixs  (data copy; no change in refcount)
          If the refcount of dpixd > 1, case (c) will side-effect
          these handles.
      (2) The general pattern of use is:
             dpixd = dpixCopy(dpixd, dpixs);
          This will work for all three cases.
          For clarity when the case is known, you can use:
            (a) dpixd = dpixCopy(NULL, dpixs);
            (c) dpixCopy(dpixd, dpixs);
      (3) For case (c), we check if dpixs and dpixd are the same size.
          If so, the data is copied directly.
          Otherwise, the data is reallocated to the correct size
          and the copy proceeds.  The refcount of dpixd is unchanged.
      (4) This operation, like all others that may involve a pre-existing
          dpixd, will side-effect any existing clones of dpixd.

=head2 dpixCreate

DPIX * dpixCreate ( l_int32 width, l_int32 height )

  dpixCreate()

      Input:  width, height
      Return: dpix (with data allocated and initialized to 0),
                     or null on error

  Notes:
      (1) Makes a DPix of specified size, with the data array
          allocated and initialized to 0.

=head2 dpixCreateTemplate

DPIX * dpixCreateTemplate ( DPIX *dpixs )

  dpixCreateTemplate()

      Input:  dpixs
      Return: dpixd, or null on error

  Notes:
      (1) Makes a DPix of the same size as the input DPix, with the
          data array allocated and initialized to 0.
      (2) Copies the resolution.

=head2 dpixDestroy

void dpixDestroy ( DPIX **pdpix )

  dpixDestroy()

      Input:  &dpix <will be nulled>
      Return: void

  Notes:
      (1) Decrements the ref count and, if 0, destroys the dpix.
      (2) Always nulls the input ptr.

=head2 dpixEndianByteSwap

DPIX * dpixEndianByteSwap ( DPIX *dpixd, DPIX *dpixs )

  dpixEndianByteSwap()

      Input:  dpixd (can be equal to dpixs or NULL)
              dpixs
      Return: dpixd always

  Notes:
      (1) On big-endian hardware, this does byte-swapping on each of
          the 4-byte words in the dpix data.  On little-endians,
          the data is unchanged.  This is used for serialization
          of dpix; the data is serialized in little-endian byte
          order because most hardware is little-endian.
      (2) The operation can be either in-place or, if dpixd == NULL,
          a new dpix is made.  If not in-place, caller must catch
          the returned pointer.

=head2 dpixGetDimensions

l_int32 dpixGetDimensions ( DPIX *dpix, l_int32 *pw, l_int32 *ph )

  dpixGetDimensions()

      Input:  dpix
              &w, &h (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 dpixGetPixel

l_int32 dpixGetPixel ( DPIX *dpix, l_int32 x, l_int32 y, l_float64 *pval )

  dpixGetPixel()

      Input:  dpix
              (x,y) pixel coords
              &val (<return> pixel value)
      Return: 0 if OK; 1 on error

=head2 dpixRead

DPIX * dpixRead ( const char *filename )

  dpixRead()

      Input:  filename
      Return: dpix, or null on error

=head2 dpixReadStream

DPIX * dpixReadStream ( FILE *fp )

  dpixReadStream()

      Input:  stream
      Return: dpix, or null on error

=head2 dpixResizeImageData

l_int32 dpixResizeImageData ( DPIX *dpixd, DPIX *dpixs )

  dpixResizeImageData()

      Input:  dpixd, dpixs
      Return: 0 if OK, 1 on error

=head2 dpixSetDimensions

l_int32 dpixSetDimensions ( DPIX *dpix, l_int32 w, l_int32 h )

  dpixSetDimensions()

      Input:  dpix
              w, h
      Return: 0 if OK, 1 on error

=head2 dpixSetPixel

l_int32 dpixSetPixel ( DPIX *dpix, l_int32 x, l_int32 y, l_float64 val )

  dpixSetPixel()

      Input:  dpix
              (x,y) pixel coords
              val (pixel value)
      Return: 0 if OK; 1 on error

=head2 dpixWrite

l_int32 dpixWrite ( const char *filename, DPIX *dpix )

  dpixWrite()

      Input:  filename
              dpix
      Return: 0 if OK, 1 on error

=head2 dpixWriteStream

l_int32 dpixWriteStream ( FILE *fp, DPIX *dpix )

  dpixWriteStream()

      Input:  stream (opened for "wb")
              dpix
      Return: 0 if OK, 1 on error

=head2 fpixClone

FPIX * fpixClone ( FPIX *fpix )

  fpixClone()

      Input:  fpix
      Return: same fpix (ptr), or null on error

  Notes:
      (1) See pixClone() for definition and usage.

=head2 fpixCopy

FPIX * fpixCopy ( FPIX *fpixd, FPIX *fpixs )

  fpixCopy()

      Input:  fpixd (<optional>; can be null, or equal to fpixs,
                    or different from fpixs)
              fpixs
      Return: fpixd, or null on error

  Notes:
      (1) There are three cases:
            (a) fpixd == null  (makes a new fpix; refcount = 1)
            (b) fpixd == fpixs  (no-op)
            (c) fpixd != fpixs  (data copy; no change in refcount)
          If the refcount of fpixd > 1, case (c) will side-effect
          these handles.
      (2) The general pattern of use is:
             fpixd = fpixCopy(fpixd, fpixs);
          This will work for all three cases.
          For clarity when the case is known, you can use:
            (a) fpixd = fpixCopy(NULL, fpixs);
            (c) fpixCopy(fpixd, fpixs);
      (3) For case (c), we check if fpixs and fpixd are the same size.
          If so, the data is copied directly.
          Otherwise, the data is reallocated to the correct size
          and the copy proceeds.  The refcount of fpixd is unchanged.
      (4) This operation, like all others that may involve a pre-existing
          fpixd, will side-effect any existing clones of fpixd.

=head2 fpixCreate

FPIX * fpixCreate ( l_int32 width, l_int32 height )

  fpixCreate()

      Input:  width, height
      Return: fpixd (with data allocated and initialized to 0),
                     or null on error

  Notes:
      (1) Makes a FPix of specified size, with the data array
          allocated and initialized to 0.

=head2 fpixCreateTemplate

FPIX * fpixCreateTemplate ( FPIX *fpixs )

  fpixCreateTemplate()

      Input:  fpixs
      Return: fpixd, or null on error

  Notes:
      (1) Makes a FPix of the same size as the input FPix, with the
          data array allocated and initialized to 0.
      (2) Copies the resolution.

=head2 fpixDestroy

void fpixDestroy ( FPIX **pfpix )

  fpixDestroy()

      Input:  &fpix <will be nulled>
      Return: void

  Notes:
      (1) Decrements the ref count and, if 0, destroys the fpix.
      (2) Always nulls the input ptr.

=head2 fpixEndianByteSwap

FPIX * fpixEndianByteSwap ( FPIX *fpixd, FPIX *fpixs )

  fpixEndianByteSwap()

      Input:  fpixd (can be equal to fpixs or NULL)
              fpixs
      Return: fpixd always

  Notes:
      (1) On big-endian hardware, this does byte-swapping on each of
          the 4-byte floats in the fpix data.  On little-endians,
          the data is unchanged.  This is used for serialization
          of fpix; the data is serialized in little-endian byte
          order because most hardware is little-endian.
      (2) The operation can be either in-place or, if fpixd == NULL,
          a new fpix is made.  If not in-place, caller must catch
          the returned pointer.

=head2 fpixGetDimensions

l_int32 fpixGetDimensions ( FPIX *fpix, l_int32 *pw, l_int32 *ph )

  fpixGetDimensions()

      Input:  fpix
              &w, &h (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 fpixGetPixel

l_int32 fpixGetPixel ( FPIX *fpix, l_int32 x, l_int32 y, l_float32 *pval )

  fpixGetPixel()

      Input:  fpix
              (x,y) pixel coords
              &val (<return> pixel value)
      Return: 0 if OK; 1 on error

=head2 fpixPrintStream

l_int32 fpixPrintStream ( FILE *fp, FPIX *fpix, l_int32 factor )

  fpixPrintStream()

      Input:  stream
              fpix
              factor (subsampled)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Subsampled printout of fpix for debugging.

=head2 fpixRead

FPIX * fpixRead ( const char *filename )

  fpixRead()

      Input:  filename
      Return: fpix, or null on error

=head2 fpixReadStream

FPIX * fpixReadStream ( FILE *fp )

  fpixReadStream()

      Input:  stream
      Return: fpix, or null on error

=head2 fpixResizeImageData

l_int32 fpixResizeImageData ( FPIX *fpixd, FPIX *fpixs )

  fpixResizeImageData()

      Input:  fpixd, fpixs
      Return: 0 if OK, 1 on error

  Notes:
      (1) If the data sizes differ, this destroys the existing
          data in fpixd and allocates a new, uninitialized, data array
          of the same size as the data in fpixs.  Otherwise, this
          doesn't do anything.

=head2 fpixSetDimensions

l_int32 fpixSetDimensions ( FPIX *fpix, l_int32 w, l_int32 h )

  fpixSetDimensions()

      Input:  fpix
              w, h
      Return: 0 if OK, 1 on error

=head2 fpixSetPixel

l_int32 fpixSetPixel ( FPIX *fpix, l_int32 x, l_int32 y, l_float32 val )

  fpixSetPixel()

      Input:  fpix
              (x,y) pixel coords
              val (pixel value)
      Return: 0 if OK; 1 on error

=head2 fpixWrite

l_int32 fpixWrite ( const char *filename, FPIX *fpix )

  fpixWrite()

      Input:  filename
              fpix
      Return: 0 if OK, 1 on error

=head2 fpixWriteStream

l_int32 fpixWriteStream ( FILE *fp, FPIX *fpix )

  fpixWriteStream()

      Input:  stream (opened for "wb")
              fpix
      Return: 0 if OK, 1 on error

=head2 fpixaAddFPix

l_int32 fpixaAddFPix ( FPIXA *fpixa, FPIX *fpix, l_int32 copyflag )

  fpixaAddFPix()

      Input:  fpixa
              fpix  (to be added)
              copyflag (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK; 1 on error

=head2 fpixaChangeRefcount

l_int32 fpixaChangeRefcount ( FPIXA *fpixa, l_int32 delta )

  fpixaChangeRefcount()

      Input:  fpixa
      Return: 0 if OK, 1 on error

=head2 fpixaCopy

FPIXA * fpixaCopy ( FPIXA *fpixa, l_int32 copyflag )

  fpixaCopy()

      Input:  fpixas
              copyflag:
                L_COPY makes a new fpixa and copies each fpix
                L_CLONE gives a new ref-counted handle to the input fpixa
                L_COPY_CLONE makes a new fpixa with clones of all fpix
      Return: new fpixa, or null on error

=head2 fpixaCreate

FPIXA * fpixaCreate ( l_int32 n )

  fpixaCreate()

      Input:  n  (initial number of ptrs)
      Return: fpixa, or null on error

=head2 fpixaDestroy

void fpixaDestroy ( FPIXA **pfpixa )

  fpixaDestroy()

      Input:  &fpixa (<can be nulled>)
      Return: void

  Notes:
      (1) Decrements the ref count and, if 0, destroys the fpixa.
      (2) Always nulls the input ptr.

=head2 fpixaGetCount

l_int32 fpixaGetCount ( FPIXA *fpixa )

  fpixaGetCount()

      Input:  fpixa
      Return: count, or 0 if no pixa

=head2 fpixaGetFPix

FPIX * fpixaGetFPix ( FPIXA *fpixa, l_int32 index, l_int32 accesstype )

  fpixaGetFPix()

      Input:  fpixa
              index  (to the index-th fpix)
              accesstype  (L_COPY or L_CLONE)
      Return: fpix, or null on error

=head2 fpixaGetFPixDimensions

l_int32 fpixaGetFPixDimensions ( FPIXA *fpixa, l_int32 index, l_int32 *pw, l_int32 *ph )

  fpixaGetFPixDimensions()

      Input:  fpixa
              index  (to the index-th box)
              &w, &h (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 fpixaGetPixel

l_int32 fpixaGetPixel ( FPIXA *fpixa, l_int32 index, l_int32 x, l_int32 y, l_float32 *pval )

  fpixaGetPixel()

      Input:  fpixa
              index (into fpixa array)
              (x,y) pixel coords
              &val (<return> pixel value)
      Return: 0 if OK; 1 on error

=head2 fpixaSetPixel

l_int32 fpixaSetPixel ( FPIXA *fpixa, l_int32 index, l_int32 x, l_int32 y, l_float32 val )

  fpixaSetPixel()

      Input:  fpixa
              index (into fpixa array)
              (x,y) pixel coords
              val (pixel value)
      Return: 0 if OK; 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
