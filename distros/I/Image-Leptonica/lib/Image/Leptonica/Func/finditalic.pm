package Image::Leptonica::Func::finditalic;
$Image::Leptonica::Func::finditalic::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::finditalic

=head1 VERSION

version 0.04

=head1 C<finditalic.c>

 finditalic.c

      l_int32   pixItalicWords()

    Locate italic words.  This is an example of the use of
    hit-miss binary morphology with binary reconstruction
    (filling from a seed into a mask).

    To see how this works, run with prog/italic.png.

=head1 FUNCTIONS

=head2 pixItalicWords

l_int32 pixItalicWords ( PIX *pixs, BOXA *boxaw, PIX *pixw, BOXA **pboxa, l_int32 debugflag )

  pixItalicWords()

      Input:  pixs (1 bpp)
              boxaw (<optional> word bounding boxes; can be NULL)
              pixw (<optional> word box mask; can be NULL)
              &boxa (<return> boxa of italic words)
              debugflag (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) You can input the bounding boxes for the words in one of
          two forms: as bounding boxes (@boxaw) or as a word mask with
          the word bounding boxes filled (@pixw).  For example,
          to compute @pixw, you can use pixWordMaskByDilation().
      (2) Alternatively, you can set both of these inputs to NULL,
          in which case the word mask is generated here.  This is
          done by dilating and closing the input image to connect
          letters within a word, while leaving the words separated.
          The parameters are chosen under the assumption that the
          input is 10 to 12 pt text, scanned at about 300 ppi.
      (3) sel_ital1 and sel_ital2 detect the right edges that are
          nearly vertical, at approximately the angle of italic
          strokes.  We use the right edge to avoid getting seeds
          from lower-case 'y'.  The typical italic slant has a smaller
          angle with the vertical than the 'W', so in most cases we
          will not trigger on the slanted lines in the 'W'.
      (4) Note that sel_ital2 is shorter than sel_ital1.  It is
          more appropriate for a typical font scanned at 200 ppi.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
