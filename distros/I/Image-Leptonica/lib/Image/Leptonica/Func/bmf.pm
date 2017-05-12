package Image::Leptonica::Func::bmf;
$Image::Leptonica::Func::bmf::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::bmf

=head1 VERSION

version 0.04

=head1 C<bmf.c>

  bmf.c

   Acquisition and generation of bitmap fonts.

       L_BMF           *bmfCreate()
       L_BMF           *bmfDestroy()

       PIX             *bmfGetPix()
       l_int32          bmfGetWidth()
       l_int32          bmfGetBaseline()

       PIXA            *pixaGetFont()
       l_int32          pixaSaveFont()
       PIXA            *pixaGenerateFont()
       static l_int32   pixGetTextBaseline()
       static l_int32   bmfMakeAsciiTables()

   This is not a very general utility, because it only uses bitmap
   representations of a single font, Palatino-Roman, with the
   normal style.  It uses bitmaps generated for nine sizes, from
   4 to 20 pts, rendered at 300 ppi.  Generalization to different
   fonts, styles and sizes is straightforward.

   I chose Palatino-Roman is because I like it.
   The input font images were generated from a set of small
   PostScript files, such as chars-12.ps, which were rendered
   into the inputfont[] bitmap files using GhostScript.  See, for
   example, the bash script prog/ps2tiff, which will "rip" a
   PostScript file into a set of ccitt-g4 compressed tiff files.

   The set of ascii characters from 32 through 126 are the 95
   printable ascii chars.  Palatino-Roman is missing char 92, '\'.
   I have substituted '/', char 47, for 92, so that there will be
   no missing printable chars in this set.  The space is char 32,
   and I have given it a width equal to twice the width of '!'.

=head1 FUNCTIONS

=head2 bmfCreate

L_BMF * bmfCreate ( const char *dir, l_int32 size )

  bmfCreate()

      Input:  dir (directory holding pixa of character set)
              size (4, 6, 8, ... , 20)
      Return: bmf (holding the bitmap font and associated information)

  Notes:
      (1) This first tries to read a pre-computed pixa file with the
          95 ascii chars in it.  If the file is not found, it
          creates the pixa from the raw image.  It then generates all
          associated data required to use the bmf.

=head2 bmfDestroy

void bmfDestroy ( L_BMF **pbmf )

  bmfDestroy()

      Input:  &bmf (<set to null>)
      Return: void

=head2 bmfGetBaseline

l_int32 bmfGetBaseline ( L_BMF *bmf, char chr, l_int32 *pbaseline )

  bmfGetBaseline()

      Input:  bmf
              chr (should be one of the 95 supported bitmaps)
              &baseline (<return>; distance below UL corner of bitmap char)
      Return: 0 if OK, 1 on error

=head2 bmfGetPix

PIX * bmfGetPix ( L_BMF *bmf, char chr )

  bmfGetPix()

      Input:  bmf
              chr (should be one of the 95 supported printable bitmaps)
      Return: pix (clone of pix in bmf), or null on error

=head2 bmfGetWidth

l_int32 bmfGetWidth ( L_BMF *bmf, char chr, l_int32 *pw )

  bmfGetWidth()

      Input:  bmf
              chr (should be one of the 95 supported bitmaps)
              &w (<return> character width; -1 if not printable)
      Return: 0 if OK, 1 on error

=head2 pixaGenerateFont

PIXA * pixaGenerateFont ( const char *dir, l_int32 size, l_int32 *pbl0, l_int32 *pbl1, l_int32 *pbl2 )

  pixaGenerateFont()

      Input:  dir (directory holding image of character set)
              size (4, 6, 8, ... , 20, in pts at 300 ppi)
              &bl1 (<return> baseline of row 1)
              &bl2 (<return> baseline of row 2)
              &bl3 (<return> baseline of row 3)
      Return: pixa of font bitmaps for 95 characters, or null on error

  These font generation functions use 9 sets, each with bitmaps
  of 94 ascii characters, all in Palatino-Roman font.
  Each input bitmap has 3 rows of characters.  The range of
  ascii values in each row is as follows:
    row 0:  32-57   (32 is a space)
    row 1:  58-91   (92, '\', is not represented in this font)
    row 2:  93-126
  We LR flip the '/' char to generate a bitmap for the missing
  '\' character, so that we have representations of all 95
  printable chars.

  Computation of the bitmaps and baselines for a single
  font takes from 40 to 200 msec on a 2 GHz processor,
  depending on the size.  Use pixaGetFont() to read the
  generated character set directly from files that were
  produced in prog/genfonts.c using this function.

=head2 pixaGetFont

PIXA * pixaGetFont ( const char *dir, l_int32 size, l_int32 *pbl0, l_int32 *pbl1, l_int32 *pbl2 )

  pixaGetFont()

      Input:  dir (directory holding pixa of character set)
              size (4, 6, 8, ... , 20)
              &bl1 (<return> baseline of row 1)
              &bl2 (<return> baseline of row 2)
              &bl3 (<return> baseline of row 3)
      Return: pixa of font bitmaps for 95 characters, or null on error

  Notes:
      (1) This reads a pre-computed pixa file with the 95 ascii chars.

=head2 pixaSaveFont

l_int32 pixaSaveFont ( const char *indir, const char *outdir, l_int32 size )

  pixaSaveFont()

      Input:  indir (directory holding image of character set)
              outdir (directory into which the output pixa file
                      will be written)
              size (in pts, at 300 ppi)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This saves a font of a particular size.
      (2) prog/genfonts calls this function for each of the
          nine font sizes, to generate all the font pixa files.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
