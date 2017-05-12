package Image::Leptonica::Func::fhmtauto;
$Image::Leptonica::Func::fhmtauto::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::fhmtauto

=head1 VERSION

version 0.04

=head1 C<fhmtauto.c>

  fhmtauto.c

    Main function calls:
       l_int32             fhmtautogen()
       l_int32             fhmtautogen1()
       l_int32             fhmtautogen2()

    Static helpers:
       static SARRAY      *sarrayMakeWplsCode()
       static SARRAY      *sarrayMakeInnerLoopDWACode()
       static char        *makeBarrelshiftString()

    This automatically generates dwa code for the hit-miss transform.
    Here's a road map for how it all works.

    (1) You generate an array (a SELA) of hit-miss transform SELs.
        This can be done in several ways, including
           (a) calling the function selaAddHitMiss() for
               pre-compiled SELs
           (b) generating the SELA in code in line
           (c) reading in a SELA from file, using selaRead()
               or various other formats.

    (2) You call fhmtautogen1() and fhmtautogen2() on this SELA.
        This uses the text files hmttemplate1.txt and
        hmttemplate2.txt for building up the source code.  See the file
        prog/fhmtautogen.c for an example of how this is done.
        The output is written to files named fhmtgen.*.c
        and fhmtgenlow.*.c, where "*" is an integer that you
        input to this function.  That integer labels both
        the output files, as well as all the functions that
        are generated.  That way, using different integers,
        you can invoke fhmtautogen() any number of times
        to get functions that all have different names so that
        they can be linked into one program.

    (3) You copy the generated source code back to your src
        directory for compilation.  Put their names in the
        Makefile, regnerate the prototypes, and recompile
        the libraries.  Look at the Makefile to see how I've
        included fhmtgen.1.c and fhmtgenlow.1.c.  These files
        provide the high-level interfaces for the hmt, and
        the low-level interfaces to do the actual work.

    (4) In an application, you now use this interface.  Again
        for the example files generated, using integer "1":

           PIX   *pixHMTDwa_1(PIX *pixd, PIX *pixs, char *selname);

              or

           PIX   *pixFHMTGen_1(PIX *pixd, PIX *pixs, char *selname);

        where the selname is one of the set that were defined
        as the name field of sels.  This set is listed at the
        beginning of the file fhmtgen.1.c.
        As an example, see the file prog/fmtauto_reg.c, which
        verifies the correctness of the implementation by
        comparing the dwa result with that of full-image
        rasterops.

=head1 FUNCTIONS

=head2 fhmtautogen

l_int32 fhmtautogen ( SELA *sela, l_int32 fileindex, const char *filename )

  fhmtautogen()

      Input:  sela
              fileindex
              filename (<optional>; can be null)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This function generates all the code for implementing
          dwa morphological operations using all the sels in the sela.
      (2) See fhmtautogen1() and fhmtautogen2() for details.

=head2 fhmtautogen1

l_int32 fhmtautogen1 ( SELA *sela, l_int32 fileindex, const char *filename )

  fhmtautogen1()

      Input:  sel array
              fileindex
              filename (<optional>; can be null)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This function uses hmttemplate1.txt to create a
          top-level file that contains two functions that carry
          out the hit-miss transform for any of the sels in
          the input sela.
      (2) The fileindex parameter is inserted into the output
          filename, as described below.
      (3) If filename == NULL, the output file is fhmtgen.<n>.c,
          where <n> is equal to the 'fileindex' parameter.
      (4) If filename != NULL, the output file is <filename>.<n>.c.
      (5) Each sel must have at least one hit.  A sel with only misses
          generates code that will abort the operation if it is called.

=head2 fhmtautogen2

l_int32 fhmtautogen2 ( SELA *sela, l_int32 fileindex, const char *filename )

  fhmtautogen2()

      Input:  sel array
              fileindex
              filename (<optional>; can be null)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This function uses hmttemplate2.txt to create a
          low-level file that contains the low-level functions for
          implementing the hit-miss transform for every sel
          in the input sela.
      (2) The fileindex parameter is inserted into the output
          filename, as described below.
      (3) If filename == NULL, the output file is fhmtgenlow.<n>.c,
          where <n> is equal to the 'fileindex' parameter.
      (4) If filename != NULL, the output file is <filename>low.<n>.c.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
