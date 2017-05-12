package Image::Leptonica::Func::regutils;
$Image::Leptonica::Func::regutils::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::regutils

=head1 VERSION

version 0.04

=head1 C<regutils.c>

  regutils.c

       Regression test utilities
           l_int32    regTestSetup()
           l_int32    regTestCleanup()
           l_int32    regTestCompareValues()
           l_int32    regTestCompareStrings()
           l_int32    regTestComparePix()
           l_int32    regTestCompareSimilarPix()
           l_int32    regTestCheckFile()
           l_int32    regTestCompareFiles()
           l_int32    regTestWritePixAndCheck()

       Static function
           char      *getRootNameFromArgv0()

  See regutils.h for how to use this.  Here is a minimal setup:

  main(int argc, char **argv) {
  ...
  L_REGPARAMS  *rp;

      if (regTestSetup(argc, argv, &rp))
          return 1;
      ...
      regTestWritePixAndCheck(rp, pix, IFF_PNG);  // 0
      ...
      return regTestCleanup(rp);
  }

=head1 FUNCTIONS

=head2 regTestCheckFile

l_int32 regTestCheckFile ( L_REGPARAMS *rp, const char *localname )

  regTestCheckFile()

      Input:  rp (regtest parameters)
              localname (name of output file from reg test)
      Return: 0 if OK, 1 on error (a failure in comparison is not an error)

  Notes:
      (1) This function does one of three things, depending on the mode:
           * "generate": makes a "golden" file as a copy @localname.
           * "compare": compares @localname contents with the golden file
           * "display": makes the @localname file but does no comparison
      (2) The canonical format of the golden filenames is:
            /tmp/golden/<root of main name>_golden.<index>.<ext of localname>
          e.g.,
             /tmp/golden/maze_golden.0.png
          It is important to add an extension to the local name, because
          the extension is added to the name of the golden file.

=head2 regTestCleanup

l_int32 regTestCleanup ( L_REGPARAMS *rp )

  regTestCleanup()

      Input:  rp (regression test parameters)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This copies anything written to the temporary file to the
          output file /tmp/reg_results.txt.

=head2 regTestCompareFiles

l_int32 regTestCompareFiles ( L_REGPARAMS *rp, l_int32 index1, l_int32 index2 )

  regTestCompareFiles()

      Input:  rp (regtest parameters)
              index1 (of one output file from reg test)
              index2 (of another output file from reg test)
      Return: 0 if OK, 1 on error (a failure in comparison is not an error)

  Notes:
      (1) This only does something in "compare" mode.
      (2) The canonical format of the golden filenames is:
            /tmp/golden/<root of main name>_golden.<index>.<ext of localname>
          e.g.,
            /tmp/golden/maze_golden.0.png

=head2 regTestComparePix

l_int32 regTestComparePix ( L_REGPARAMS *rp, PIX *pix1, PIX *pix2 )

  regTestComparePix()

      Input:  rp (regtest parameters)
              pix1, pix2 (to be tested for equality)
      Return: 0 if OK, 1 on error (a failure in comparison is not an error)

  Notes:
      (1) This function compares two pix for equality.  On failure,
          this writes to stderr.

=head2 regTestCompareSimilarPix

l_int32 regTestCompareSimilarPix ( L_REGPARAMS *rp, PIX *pix1, PIX *pix2, l_int32 mindiff, l_float32 maxfract, l_int32 printstats )

  regTestCompareSimilarPix()

      Input:  rp (regtest parameters)
              pix1, pix2 (to be tested for near equality)
              mindiff (minimum pixel difference to be counted; > 0)
              maxfract (maximum fraction of pixels allowed to have
                        diff greater than or equal to mindiff)
              printstats (use 1 to print normalized histogram to stderr)
      Return: 0 if OK, 1 on error (a failure in similarity comparison
              is not an error)

  Notes:
      (1) This function compares two pix for near equality.  On failure,
          this writes to stderr.
      (2) The pix are similar if the fraction of non-conforming pixels
          does not exceed @maxfract.  Pixels are non-conforming if
          the difference in pixel values equals or exceeds @mindiff.
          Typical values might be @mindiff = 15 and @maxfract = 0.01.
      (3) The input images must have the same size and depth.  The
          pixels for comparison are typically subsampled from the images.
      (4) Normally, use @printstats = 0.  In debugging mode, to see
          the relation between @mindiff and the minimum value of
          @maxfract for success, set this to 1.

=head2 regTestCompareStrings

l_int32 regTestCompareStrings ( L_REGPARAMS *rp, l_uint8 *string1, size_t bytes1, l_uint8 *string2, size_t bytes2 )

  regTestCompareStrings()

      Input:  rp (regtest parameters)
              string1 (typ. the expected string)
              bytes1 (size of string1)
              string2 (typ. the computed string)
              bytes2 (size of string2)
      Return: 0 if OK, 1 on error (a failure in comparison is not an error)

=head2 regTestCompareValues

l_int32 regTestCompareValues ( L_REGPARAMS *rp, l_float32 val1, l_float32 val2, l_float32 delta )

  regTestCompareValues()

      Input:  rp (regtest parameters)
              val1 (typ. the golden value)
              val2 (typ. the value computed)
              delta (allowed max absolute difference)
      Return: 0 if OK, 1 on error (a failure in comparison is not an error)

=head2 regTestWritePixAndCheck

l_int32 regTestWritePixAndCheck ( L_REGPARAMS *rp, PIX *pix, l_int32 format )

  regTestWritePixAndCheck()

      Input:  rp (regtest parameters)
              pix (to be written)
              format (of output pix)
      Return: 0 if OK, 1 on error (a failure in comparison is not an error)

  Notes:
      (1) This function makes it easy to write the pix in a numbered
          sequence of files, and either to:
             (a) write the golden file ("generate" arg to regression test)
             (b) make a local file and "compare" with the golden file
             (c) make a local file and "display" the results
      (3) The canonical format of the local filename is:
            /tmp/<root of main name>.<count>.<format extension string>
          e.g., for scale_reg,
            /tmp/scale.0.png

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
