package Image::Leptonica::Func::ccthin;
$Image::Leptonica::Func::ccthin::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::ccthin

=head1 VERSION

version 0.04

=head1 C<ccthin.c>

  ccthin.c

     PIX    *pixThin()
     PIX    *pixThinGeneral()
     PIX    *pixThinExamples()

=head1 FUNCTIONS

=head2 pixThin

PIX * pixThin ( PIX *pixs, l_int32 type, l_int32 connectivity, l_int32 maxiters )

  pixThin()

      Input:  pixs (1 bpp)
              type (L_THIN_FG, L_THIN_BG)
              connectivity (4 or 8)
              maxiters (max number of iters allowed; use 0 to iterate
                        until completion)
      Return: pixd, or null on error

  Notes:
      (1) See "Connectivity-preserving morphological image transformations,"
          Dan S. Bloomberg, in SPIE Visual Communications and Image
          Processing, Conference 1606, pp. 320-334, November 1991,
          Boston, MA.   A web version is available at
              http://www.leptonica.com/papers/conn.pdf
      (2) We implement here two of the best iterative
          morphological thinning algorithms, for 4 c.c and 8 c.c.
          Each iteration uses a mixture of parallel operations
          (using several different 3x3 Sels) and serial operations.
          Specifically, each thinning iteration consists of
          four sequential thinnings from each of four directions.
          Each of these thinnings is a parallel composite
          operation, where the union of a set of HMTs are set
          subtracted from the input.  For 4-cc thinning, we
          use 3 HMTs in parallel, and for 8-cc thinning we use 4 HMTs.
      (3) A "good" thinning algorithm is one that generates a skeleton
          that is near the medial axis and has neither pruned
          real branches nor left extra dendritic branches.
      (4) To thin the foreground, which is the usual situation,
          use type == L_THIN_FG.  Thickening the foreground is equivalent
          to thinning the background (type == L_THIN_BG), where the
          opposite connectivity gets preserved.  For example, to thicken
          the fg using 4-connectivity, we thin the bg using Sels that
          preserve 8-connectivity.

=head2 pixThinExamples

PIX * pixThinExamples ( PIX *pixs, l_int32 type, l_int32 index, l_int32 maxiters, const char *selfile )

  pixThinExamples()

      Input:  pixs (1 bpp)
              type (L_THIN_FG, L_THIN_BG)
              index (into specific examples; valid 1-9; see notes)
              maxiters (max number of iters allowed; use 0 to iterate
                        until completion)
              selfile (<optional> filename for output sel display)
      Return: pixd, or null on error

  Notes:
      (1) See notes in pixThin().  The examples are taken from
          the paper referenced there.
      (2) Here we allow specific sets of HMTs to be used in
          parallel for thinning from each of four directions.
          One iteration consists of four such parallel thins.
      (3) The examples are indexed as follows:
          Thinning  (e.g., run to completion):
              index = 1     sel_4_1, sel_4_5, sel_4_6
              index = 2     sel_4_1, sel_4_7, sel_4_7_rot
              index = 3     sel_48_1, sel_48_1_rot, sel_48_2
              index = 4     sel_8_2, sel_8_3, sel_48_2
              index = 5     sel_8_1, sel_8_5, sel_8_6
              index = 6     sel_8_2, sel_8_3, sel_8_8, sel_8_9
              index = 7     sel_8_5, sel_8_6, sel_8_7, sel_8_7_rot
          Thickening:
              index = 8     sel_4_2, sel_4_3 (e.g,, do just a few iterations)
              index = 9     sel_8_4 (e.g., do just a few iterations)

=head2 pixThinGeneral

PIX * pixThinGeneral ( PIX *pixs, l_int32 type, SELA *sela, l_int32 maxiters )

  pixThinGeneral()

      Input:  pixs (1 bpp)
              type (L_THIN_FG, L_THIN_BG)
              sela (of Sels for parallel composite HMTs)
              maxiters (max number of iters allowed; use 0 to iterate
                        until completion)
      Return: pixd, or null on error

  Notes:
      (1) See notes in pixThin().  That function chooses among
          the best of the Sels for thinning.
      (2) This is a general function that takes a Sela of HMTs
          that are used in parallel for thinning from each
          of four directions.  One iteration consists of four
          such parallel thins.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
