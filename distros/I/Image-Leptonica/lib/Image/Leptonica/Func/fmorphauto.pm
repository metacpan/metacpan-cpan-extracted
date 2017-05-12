package Image::Leptonica::Func::fmorphauto;
$Image::Leptonica::Func::fmorphauto::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::fmorphauto

=head1 VERSION

version 0.04

=head1 C<fmorphauto.c>

  fmorphauto.c

    Main function calls:
       l_int32             fmorphautogen()
       l_int32             fmorphautogen1()
       l_int32             fmorphautogen2()

    Static helpers:
       static SARRAY      *sarrayMakeWplsCode()
       static SARRAY      *sarrayMakeInnerLoopDWACode()
       static char        *makeBarrelshiftString()


    This automatically generates dwa code for erosion and dilation.
    Here's a road map for how it all works.

    (1) You generate an array (a SELA) of structuring elements (SELs).
        This can be done in several ways, including
           (a) calling the function selaAddBasic() for
               pre-compiled SELs
           (b) generating the SELA in code in line
           (c) reading in a SELA from file, using selaRead() or
               various other formats.

    (2) You call fmorphautogen1() and fmorphautogen2() on this SELA.
        These use the text files morphtemplate1.txt and
        morphtemplate2.txt for building up the source code.  See the file
        prog/fmorphautogen.c for an example of how this is done.
        The output is written to files named fmorphgen.*.c
        and fmorphgenlow.*.c, where "*" is an integer that you
        input to this function.  That integer labels both
        the output files, as well as all the functions that
        are generated.  That way, using different integers,
        you can invoke fmorphautogen() any number of times
        to get functions that all have different names so that
        they can be linked into one program.

    (3) You copy the generated source files back to your src
        directory for compilation.  Put their names in the
        Makefile, regenerate the prototypes, and recompile
        the library.  Look at the Makefile to see how I've
        included morphgen.1.c and fmorphgenlow.1.c.  These files
        provide the high-level interfaces for erosion, dilation,
        opening and closing, and the low-level interfaces to
        do the actual work, for all 58 SELs in the SEL array.

    (4) In an application, you now use this interface.  Again
        for the example files in the library, using integer "1":

            PIX   *pixMorphDwa_1(PIX *pixd, PIX, *pixs,
                                 l_int32 operation, char *selname);

                 or

            PIX   *pixFMorphopGen_1(PIX *pixd, PIX *pixs,
                                    l_int32 operation, char *selname);

        where the operation is one of {L_MORPH_DILATE, L_MORPH_ERODE.
        L_MORPH_OPEN, L_MORPH_CLOSE}, and the selname is one
        of the set that were defined as the name field of sels.
        This set is listed at the beginning of the file fmorphgen.1.c.
        For examples of use, see the file prog/binmorph_reg1.c, which
        verifies the consistency of the various implementations by
        comparing the dwa result with that of full-image rasterops.

=head1 FUNCTIONS

=head2 fmorphautogen

l_int32 fmorphautogen ( SELA *sela, l_int32 fileindex, const char *filename )

  fmorphautogen()

      Input:  sela
              fileindex
              filename (<optional>; can be null)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This function generates all the code for implementing
          dwa morphological operations using all the sels in the sela.
      (2) See fmorphautogen1() and fmorphautogen2() for details.

=head2 fmorphautogen1

l_int32 fmorphautogen1 ( SELA *sela, l_int32 fileindex, const char *filename )

  fmorphautogen1()

      Input:  sela
              fileindex
              filename (<optional>; can be null)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This function uses morphtemplate1.txt to create a
          top-level file that contains two functions.  These
          functions will carry out dilation, erosion,
          opening or closing for any of the sels in the input sela.
      (2) The fileindex parameter is inserted into the output
          filename, as described below.
      (3) If filename == NULL, the output file is fmorphgen.<n>.c,
          where <n> is equal to the 'fileindex' parameter.
      (4) If filename != NULL, the output file is <filename>.<n>.c.

=head2 fmorphautogen2

l_int32 fmorphautogen2 ( SELA *sela, l_int32 fileindex, const char *filename )

  fmorphautogen2()

      Input:  sela
              fileindex
              filename (<optional>; can be null)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This function uses morphtemplate2.txt to create a
          low-level file that contains the low-level functions for
          implementing dilation and erosion for every sel
          in the input sela.
      (2) The fileindex parameter is inserted into the output
          filename, as described below.
      (3) If filename == NULL, the output file is fmorphgenlow.<n>.c,
          where <n> is equal to the 'fileindex' parameter.
      (4) If filename != NULL, the output file is <filename>low.<n>.c.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
