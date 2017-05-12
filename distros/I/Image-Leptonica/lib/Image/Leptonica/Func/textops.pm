package Image::Leptonica::Func::textops;
$Image::Leptonica::Func::textops::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::textops

=head1 VERSION

version 0.04

=head1 C<textops.c>

  textops.c

    Font layout
       PIX             *pixAddSingleTextblock()
       PIX             *pixAddSingleTextline()
       l_int32          pixSetTextblock()
       l_int32          pixSetTextline()
       PIXA            *pixaAddTextNumber()
       PIXA            *pixaAddTextline()

    Text size estimation and partitioning
       SARRAY          *bmfGetLineStrings()
       NUMA            *bmfGetWordWidths()
       l_int32          bmfGetStringWidth()

    Text splitting
       SARRAY          *splitStringToParagraphs()
       static l_int32   stringAllWhitespace()
       static l_int32   stringLeadingWhitespace()

    This is a simple utility to put text on images.  One font and style
    is provided, with a variety of pt sizes.  For example, to put a
    line of green 10 pt text on an image, with the beginning baseline
    at (50, 50):
        L_Bmf  *bmf = bmfCreate("./fonts", 10);
        const char *textstr = "This is a funny cat";
        pixSetTextline(pixs, bmf, textstr, 0x00ff0000, 50, 50, NULL, NULL);

    The simplest interfaces for adding text to an image are
    pixAddSingleTextline() and pixAddSingleTextblock().

=head1 FUNCTIONS

=head2 bmfGetLineStrings

SARRAY * bmfGetLineStrings ( L_BMF *bmf, const char *textstr, l_int32 maxw, l_int32 firstindent, l_int32 *ph )

  bmfGetLineStrings()

      Input:  bmf
              textstr
              maxw (max width of a text line in pixels)
              firstindent (indentation of first line, in x-widths)
              &h (<return> height required to hold text bitmap)
      Return: sarray of text strings for each line, or null on error

  Notes:
      (1) Divides the input text string into an array of text strings,
          each of which will fit within maxw bits of width.

=head2 bmfGetStringWidth

l_int32 bmfGetStringWidth ( L_BMF *bmf, const char *textstr, l_int32 *pw )

  bmfGetStringWidth()

      Input:  bmf
              textstr
              &w (<return> width of text string, in pixels for the
                 font represented by the bmf)
      Return: 0 if OK, 1 on error

=head2 bmfGetWordWidths

NUMA * bmfGetWordWidths ( L_BMF *bmf, const char *textstr, SARRAY *sa )

  bmfGetWordWidths()

      Input:  bmf
              textstr
              sa (of individual words)
      Return: numa (of word lengths in pixels for the font represented
                    by the bmf), or null on error

=head2 pixAddSingleTextblock

PIX * pixAddSingleTextblock ( PIX *pixs, L_BMF *bmf, const char *textstr, l_uint32 val, l_int32 location, l_int32 *poverflow )

  pixAddSingleTextblock()

      Input:  pixs (input pix; colormap ok)
              bmf (bitmap font data)
              textstr (<optional> text string to be added)
              val (color to set the text)
              location (L_ADD_ABOVE, L_ADD_AT_TOP, L_ADD_AT_BOT, L_ADD_BELOW)
              &overflow (<optional return> 1 if text overflows
                         allocated region and is clipped; 0 otherwise)
      Return: pixd (new pix with rendered text), or null on error

  Notes:
      (1) This function paints a set of lines of text over an image.
          If @location is L_ADD_ABOVE or L_ADD_BELOW, the pix size
          is expanded with a border and rendered over the border.
      (2) @val is the pixel value to be painted through the font mask.
          It should be chosen to agree with the depth of pixs.
          If it is out of bounds, an intermediate value is chosen.
          For RGB, use hex notation: 0xRRGGBB00, where RR is the
          hex representation of the red intensity, etc.
      (3) If textstr == NULL, use the text field in the pix.
      (4) If there is a colormap, this does the best it can to use
          the requested color, or something similar to it.
      (5) Typical usage is for labelling a pix with some text data.

=head2 pixAddSingleTextline

PIX * pixAddSingleTextline ( PIX *pixs, L_BMF *bmf, const char *textstr, l_uint32 val, l_int32 location )

  pixAddSingleTextline()

      Input:  pixs (input pix; colormap ok)
              bmf (bitmap font data)
              textstr (<optional> text string to be added)
              val (color to set the text)
              location (L_ADD_ABOVE, L_ADD_BELOW, L_ADD_LEFT, L_ADD_RIGHT)
      Return: pixd (new pix with rendered text), or null on error

  Notes:
      (1) This function expands an image as required to paint a single
          line of text adjacent to the image.
      (2) @val is the pixel value to be painted through the font mask.
          It should be chosen to agree with the depth of pixs.
          If it is out of bounds, an intermediate value is chosen.
          For RGB, use hex notation: 0xRRGGBB00, where RR is the
          hex representation of the red intensity, etc.
      (3) If textstr == NULL, use the text field in the pix.
      (4) If there is a colormap, this does the best it can to use
          the requested color, or something similar to it.
      (5) Typical usage is for labelling a pix with some text data.

=head2 pixSetTextblock

l_int32 pixSetTextblock ( PIX *pixs, L_BMF *bmf, const char *textstr, l_uint32 val, l_int32 x0, l_int32 y0, l_int32 wtext, l_int32 firstindent, l_int32 *poverflow )

  pixSetTextblock()

      Input:  pixs (input image)
              bmf (bitmap font data)
              textstr (block text string to be set)
              val (color to set the text)
              x0 (left edge for each line of text)
              y0 (baseline location for the first text line)
              wtext (max width of each line of generated text)
              firstindent (indentation of first line, in x-widths)
              &overflow (<optional return> 0 if text is contained in
                         input pix; 1 if it is clipped)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This function paints a set of lines of text over an image.
      (2) @val is the pixel value to be painted through the font mask.
          It should be chosen to agree with the depth of pixs.
          If it is out of bounds, an intermediate value is chosen.
          For RGB, use hex notation: 0xRRGGBB00, where RR is the
          hex representation of the red intensity, etc.
          The last two hex digits are 00 (byte value 0), assigned to
          the A component.  Note that, as usual, RGBA proceeds from
          left to right in the order from MSB to LSB (see pix.h
          for details).
      (3) If there is a colormap, this does the best it can to use
          the requested color, or something similar to it.

=head2 pixSetTextline

l_int32 pixSetTextline ( PIX *pixs, L_BMF *bmf, const char *textstr, l_uint32 val, l_int32 x0, l_int32 y0, l_int32 *pwidth, l_int32 *poverflow )

  pixSetTextline()

      Input:  pixs (input image)
              bmf (bitmap font data)
              textstr (text string to be set on the line)
              val (color to set the text)
              x0 (left edge for first char)
              y0 (baseline location for all text on line)
              &width (<optional return> width of generated text)
              &overflow (<optional return> 0 if text is contained in
                         input pix; 1 if it is clipped)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This function paints a line of text over an image.
      (2) @val is the pixel value to be painted through the font mask.
          It should be chosen to agree with the depth of pixs.
          If it is out of bounds, an intermediate value is chosen.
          For RGB, use hex notation: 0xRRGGBB00, where RR is the
          hex representation of the red intensity, etc.
          The last two hex digits are 00 (byte value 0), assigned to
          the A component.  Note that, as usual, RGBA proceeds from
          left to right in the order from MSB to LSB (see pix.h
          for details).
      (3) If there is a colormap, this does the best it can to use
          the requested color, or something similar to it.

=head2 pixaAddTextNumber

PIXA * pixaAddTextNumber ( PIXA *pixas, L_BMF *bmf, NUMA *na, l_uint32 val, l_int32 location )

  pixaAddTextNumber()

      Input:  pixas (input pixa; colormap ok)
              bmf (bitmap font data)
              numa (<optional> number array; use 1 ... n if null)
              val (color to set the text)
              location (L_ADD_ABOVE, L_ADD_BELOW, L_ADD_LEFT, L_ADD_RIGHT)
      Return: pixad (new pixa with rendered numbers), or null on error

  Notes:
      (1) Typical usage is for labelling each pix in a pixa with a number.
      (2) This function paints numbers external to each pix, in a position
          given by @location.  In all cases, the pix is expanded on
          on side and the number is painted over white in the added region.
      (3) @val is the pixel value to be painted through the font mask.
          It should be chosen to agree with the depth of pixs.
          If it is out of bounds, an intermediate value is chosen.
          For RGB, use hex notation: 0xRRGGBB00, where RR is the
          hex representation of the red intensity, etc.
      (4) If na == NULL, number each pix sequentially, starting with 1.
      (5) If there is a colormap, this does the best it can to use
          the requested color, or something similar to it.

=head2 pixaAddTextline

PIXA * pixaAddTextline ( PIXA *pixas, L_BMF *bmf, SARRAY *sa, l_uint32 val, l_int32 location )

  pixaAddTextline()

      Input:  pixas (input pixa; colormap ok)
              bmf (bitmap font data)
              sa (<optional> sarray; use text embedded in each pix if null)
              val (color to set the text)
              location (L_ADD_ABOVE, L_ADD_BELOW, L_ADD_LEFT, L_ADD_RIGHT)
      Return: pixad (new pixa with rendered text), or null on error

  Notes:
      (1) This function paints a line of text external to each pix,
          in a position given by @location.  In all cases, the pix is
          expanded as necessary to accommodate the text.
      (2) @val is the pixel value to be painted through the font mask.
          It should be chosen to agree with the depth of pixs.
          If it is out of bounds, an intermediate value is chosen.
          For RGB, use hex notation: 0xRRGGBB00, where RR is the
          hex representation of the red intensity, etc.
      (3) If sa == NULL, use the text embedded in each pix.
      (4) If sa has a smaller count than pixa, issue a warning
          but do not use any embedded text.
      (5) If there is a colormap, this does the best it can to use
          the requested color, or something similar to it.

=head2 splitStringToParagraphs

SARRAY * splitStringToParagraphs ( char *textstr, l_int32 splitflag )

  splitStringToParagraphs()

      Input:  textstring
              splitting flag (see enum in bmf.h; valid values in {1,2,3})
      Return: sarray (where each string is a paragraph of the input),
                      or null on error.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
