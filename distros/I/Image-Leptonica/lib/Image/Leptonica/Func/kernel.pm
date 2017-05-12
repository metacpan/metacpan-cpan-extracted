package Image::Leptonica::Func::kernel;
$Image::Leptonica::Func::kernel::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::kernel

=head1 VERSION

version 0.04

=head1 C<kernel.c>

  kernel.c

      Basic operations on kernels for image convolution

         Create/destroy/copy
            L_KERNEL   *kernelCreate()
            void        kernelDestroy()
            L_KERNEL   *kernelCopy()

         Accessors:
            l_int32     kernelGetElement()
            l_int32     kernelSetElement()
            l_int32     kernelGetParameters()
            l_int32     kernelSetOrigin()
            l_int32     kernelGetSum()
            l_int32     kernelGetMinMax()

         Normalize/invert
            L_KERNEL   *kernelNormalize()
            L_KERNEL   *kernelInvert()

         Helper function
            l_float32 **create2dFloatArray()

         Serialized I/O
            L_KERNEL   *kernelRead()
            L_KERNEL   *kernelReadStream()
            l_int32     kernelWrite()
            l_int32     kernelWriteStream()

         Making a kernel from a compiled string
            L_KERNEL   *kernelCreateFromString()

         Making a kernel from a simple file format
            L_KERNEL   *kernelCreateFromFile()

         Making a kernel from a Pix
            L_KERNEL   *kernelCreateFromPix()

         Display a kernel in a pix
            PIX        *kernelDisplayInPix()

         Parse string to extract numbers
            NUMA       *parseStringForNumbers()

      Simple parametric kernels
            L_KERNEL   *makeFlatKernel()
            L_KERNEL   *makeGaussianKernel()
            L_KERNEL   *makeGaussianKernelSep()
            L_KERNEL   *makeDoGKernel()

=head1 FUNCTIONS

=head2 create2dFloatArray

l_float32 ** create2dFloatArray ( l_int32 sy, l_int32 sx )

  create2dFloatArray()

      Input:  sy (rows == height)
              sx (columns == width)
      Return: doubly indexed array (i.e., an array of sy row pointers,
              each of which points to an array of sx floats)

  Notes:
      (1) The array[sy][sx] is indexed in standard "matrix notation",
          with the row index first.

=head2 kernelCopy

L_KERNEL * kernelCopy ( L_KERNEL *kels )

  kernelCopy()

      Input:  kels (source kernel)
      Return: keld (copy of kels), or null on error

=head2 kernelCreate

L_KERNEL * kernelCreate ( l_int32 height, l_int32 width )

  kernelCreate()

      Input:  height, width
      Return: kernel, or null on error

  Notes:
      (1) kernelCreate() initializes all values to 0.
      (2) After this call, (cy,cx) and nonzero data values must be
          assigned.

=head2 kernelCreateFromFile

L_KERNEL * kernelCreateFromFile ( const char *filename )

  kernelCreateFromFile()

      Input:  filename
      Return: kernel, or null on error

  Notes:
      (1) The file contains, in the following order:
           - Any number of comment lines starting with '#' are ignored
           - The height and width of the kernel
           - The y and x values of the kernel origin
           - The kernel data, formatted as lines of numbers (integers
             or floats) for the kernel values in row-major order,
             and with no other punctuation.
             (Note: this differs from kernelCreateFromString(),
             where each line must begin and end with a double-quote
             to tell the compiler it's part of a string.)
           - The kernel specification ends when a blank line,
             a comment line, or the end of file is reached.
      (2) All lines must be left-justified.
      (3) See kernelCreateFromString() for a description of the string
          format for the kernel data.  As an example, here are the lines
          of a valid kernel description file  In the file, all lines
          are left-justified:
                    # small 3x3 kernel
                    3 3
                    1 1
                    25.5   51    24.3
                    70.2  146.3  73.4
                    20     50.9  18.4

=head2 kernelCreateFromPix

L_KERNEL * kernelCreateFromPix ( PIX *pix, l_int32 cy, l_int32 cx )

  kernelCreateFromPix()

      Input:  pix
              cy, cx (origin of kernel)
      Return: kernel, or null on error

  Notes:
      (1) The origin must be positive and within the dimensions of the pix.

=head2 kernelCreateFromString

L_KERNEL * kernelCreateFromString ( l_int32 h, l_int32 w, l_int32 cy, l_int32 cx, const char *kdata )

  kernelCreateFromString()

      Input:  height, width
              cy, cx   (origin)
              kdata
      Return: kernel of the given size, or null on error

  Notes:
      (1) The data is an array of chars, in row-major order, giving
          space separated integers in the range [-255 ... 255].
      (2) The only other formatting limitation is that you must
          leave space between the last number in each row and
          the double-quote.  If possible, it's also nice to have each
          line in the string represent a line in the kernel; e.g.,
              static const char *kdata =
                  " 20   50   20 "
                  " 70  140   70 "
                  " 20   50   20 ";

=head2 kernelDestroy

void kernelDestroy ( L_KERNEL **pkel )

  kernelDestroy()

      Input:  &kel (<to be nulled>)
      Return: void

=head2 kernelDisplayInPix

PIX * kernelDisplayInPix ( L_KERNEL *kel, l_int32 size, l_int32 gthick )

  kernelDisplayInPix()

      Input:  kernel
              size (of grid interiors; odd; either 1 or a minimum size
                    of 17 is enforced)
              gthick (grid thickness; either 0 or a minimum size of 2
                      is enforced)
      Return: pix (display of kernel), or null on error

  Notes:
      (1) This gives a visual representation of a kernel.
      (2) There are two modes of display:
          (a) Grid lines of minimum width 2, surrounding regions
              representing kernel elements of minimum size 17,
              with a "plus" mark at the kernel origin, or
          (b) A pix without grid lines and using 1 pixel per kernel element.
      (3) For both cases, the kernel absolute value is displayed,
          normalized such that the maximum absolute value is 255.
      (4) Large 2D separable kernels should be used for convolution
          with two 1D kernels.  However, for the bilateral filter,
          the computation time is independent of the size of the
          2D content kernel.

=head2 kernelGetElement

l_int32 kernelGetElement ( L_KERNEL *kel, l_int32 row, l_int32 col, l_float32 *pval )

  kernelGetElement()

      Input:  kel
              row
              col
              &val
      Return: 0 if OK; 1 on error

=head2 kernelGetMinMax

l_int32 kernelGetMinMax ( L_KERNEL *kel, l_float32 *pmin, l_float32 *pmax )

  kernelGetMinMax()

      Input:  kernel
              &min (<optional return> minimum value)
              &max (<optional return> maximum value)
      Return: 0 if OK, 1 on error

=head2 kernelGetParameters

l_int32 kernelGetParameters ( L_KERNEL *kel, l_int32 *psy, l_int32 *psx, l_int32 *pcy, l_int32 *pcx )

  kernelGetParameters()

      Input:  kernel
              &sy, &sx, &cy, &cx (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 kernelGetSum

l_int32 kernelGetSum ( L_KERNEL *kel, l_float32 *psum )

  kernelGetSum()

      Input:  kernel
              &sum (<return> sum of all kernel values)
      Return: 0 if OK, 1 on error

=head2 kernelInvert

L_KERNEL * kernelInvert ( L_KERNEL *kels )

  kernelInvert()

      Input:  kels (source kel, to be inverted)
      Return: keld (spatially inverted, about the origin), or null on error

  Notes:
      (1) For convolution, the kernel is spatially inverted before
          a "correlation" operation is done between the kernel and the image.

=head2 kernelNormalize

L_KERNEL * kernelNormalize ( L_KERNEL *kels, l_float32 normsum )

  kernelNormalize()

      Input:  kels (source kel, to be normalized)
              normsum (desired sum of elements in keld)
      Return: keld (normalized version of kels), or null on error
                   or if sum of elements is very close to 0)

  Notes:
      (1) If the sum of kernel elements is close to 0, do not
          try to calculate the normalized kernel.  Instead,
          return a copy of the input kernel, with a warning.

=head2 kernelRead

L_KERNEL * kernelRead ( const char *fname )

  kernelRead()

      Input:  filename
      Return: kernel, or null on error

=head2 kernelReadStream

L_KERNEL * kernelReadStream ( FILE *fp )

  kernelReadStream()

      Input:  stream
      Return: kernel, or null on error

=head2 kernelSetElement

l_int32 kernelSetElement ( L_KERNEL *kel, l_int32 row, l_int32 col, l_float32 val )

  kernelSetElement()

      Input:  kernel
              row
              col
              val
      Return: 0 if OK; 1 on error

=head2 kernelSetOrigin

l_int32 kernelSetOrigin ( L_KERNEL *kel, l_int32 cy, l_int32 cx )

  kernelSetOrigin()

      Input:  kernel
              cy, cx
      Return: 0 if OK; 1 on error

=head2 kernelWrite

l_int32 kernelWrite ( const char *fname, L_KERNEL *kel )

  kernelWrite()

      Input:  fname (output file)
              kernel
      Return: 0 if OK, 1 on error

=head2 kernelWriteStream

l_int32 kernelWriteStream ( FILE *fp, L_KERNEL *kel )

  kernelWriteStream()

      Input:  stream
              kel
      Return: 0 if OK, 1 on error

=head2 makeDoGKernel

L_KERNEL * makeDoGKernel ( l_int32 halfheight, l_int32 halfwidth, l_float32 stdev, l_float32 ratio )

  makeDoGKernel()

      Input:  halfheight, halfwidth (sx = 2 * halfwidth + 1, etc)
              stdev (standard deviation of narrower gaussian)
              ratio (of stdev for wide filter to stdev for narrow one)
      Return: kernel, or null on error

  Notes:
      (1) The DoG (difference of gaussians) is a wavelet mother
          function with null total sum.  By subtracting two blurred
          versions of the image, it acts as a bandpass filter for
          frequencies passed by the narrow gaussian but stopped
          by the wide one.See:
               http://en.wikipedia.org/wiki/Difference_of_Gaussians
      (2) The kernel size (sx, sy) = (2 * halfwidth + 1, 2 * halfheight + 1).
      (3) The kernel center (cx, cy) = (halfwidth, halfheight).
      (4) The halfwidth and halfheight are typically equal, and
          are typically several times larger than the standard deviation.
      (5) The ratio is the ratio of standard deviations of the wide
          to narrow gaussian.  It must be >= 1.0; 1.0 is a no-op.
      (6) Because the kernel is a null sum, it must be invoked without
          normalization in pixConvolve().

=head2 makeFlatKernel

L_KERNEL * makeFlatKernel ( l_int32 height, l_int32 width, l_int32 cy, l_int32 cx )

  makeFlatKernel()

      Input:  height, width
              cy, cx (origin of kernel)
      Return: kernel, or null on error

  Notes:
      (1) This is the same low-pass filtering kernel that is used
          in the block convolution functions.
      (2) The kernel origin (@cy, @cx) is typically placed as near
          the center of the kernel as possible.  If height and
          width are odd, then using cy = height / 2 and
          cx = width / 2 places the origin at the exact center.
      (3) This returns a normalized kernel.

=head2 makeGaussianKernel

L_KERNEL * makeGaussianKernel ( l_int32 halfheight, l_int32 halfwidth, l_float32 stdev, l_float32 max )

  makeGaussianKernel()

      Input:  halfheight, halfwidth (sx = 2 * halfwidth + 1, etc)
              stdev (standard deviation)
              max (value at (cx,cy))
      Return: kernel, or null on error

  Notes:
      (1) The kernel size (sx, sy) = (2 * halfwidth + 1, 2 * halfheight + 1).
      (2) The kernel center (cx, cy) = (halfwidth, halfheight).
      (3) The halfwidth and halfheight are typically equal, and
          are typically several times larger than the standard deviation.
      (4) If pixConvolve() is invoked with normalization (the sum of
          kernel elements = 1.0), use 1.0 for max (or any number that's
          not too small or too large).

=head2 makeGaussianKernelSep

l_int32 makeGaussianKernelSep ( l_int32 halfheight, l_int32 halfwidth, l_float32 stdev, l_float32 max, L_KERNEL **pkelx, L_KERNEL **pkely )

  makeGaussianKernelSep()

      Input:  halfheight, halfwidth (sx = 2 * halfwidth + 1, etc)
              stdev (standard deviation)
              max (value at (cx,cy))
              &kelx (<return> x part of kernel)
              &kely (<return> y part of kernel)
      Return: 0 if OK, 1 on error

  Notes:
      (1) See makeGaussianKernel() for description of input parameters.
      (2) These kernels are constructed so that the result of both
          normalized and un-normalized convolution will be the same
          as when convolving with pixConvolve() using the full kernel.
      (3) The trick for the un-normalized convolution is to have the
          product of the two kernel elemets at (cx,cy) be equal to max,
          not max**2.  That's why the max for kely is 1.0.  If instead
          we use sqrt(max) for both, the results are slightly less
          accurate, when compared to using the full kernel in
          makeGaussianKernel().

=head2 parseStringForNumbers

NUMA * parseStringForNumbers ( const char *str, const char *seps )

  parseStringForNumbers()

      Input:  string (containing numbers; not changed)
              seps (string of characters that can be used between ints)
      Return: numa (of numbers found), or null on error

  Note:
     (1) The numbers can be ints or floats.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
