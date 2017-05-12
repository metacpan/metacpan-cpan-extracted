package Image::Leptonica::Func::sel2;
$Image::Leptonica::Func::sel2::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::sel2

=head1 VERSION

version 0.04

=head1 C<sel2.c>

  sel2.c

      Contains definitions of simple structuring elements

          SELA    *selaAddBasic()
               Linear horizontal and vertical
               Square
               Diagonals

          SELA    *selaAddHitMiss()
               Isolated foreground pixel
               Horizontal and vertical edges
               Slanted edge
               Corners

          SELA    *selaAddDwaLinear()
          SELA    *selaAddDwaCombs()
          SELA    *selaAddCrossJunctions()
          SELA    *selaAddTJunctions()

=head1 FUNCTIONS

=head2 selaAddBasic

SELA * selaAddBasic ( SELA *sela )

  selaAddBasic()

      Input:  sela (<optional>)
      Return: sela with additional sels, or null on error

  Notes:
      (1) Adds the following sels:
            - all linear (horiz, vert) brick sels that are
              necessary for decomposable sels up to size 63
            - square brick sels up to size 10
            - 4 diagonal sels

=head2 selaAddCrossJunctions

SELA * selaAddCrossJunctions ( SELA *sela, l_float32 hlsize, l_float32 mdist, l_int32 norient, l_int32 debugflag )

  selaAddCrossJunctions()

      Input:  sela (<optional>)
              hlsize (length of each line of hits from origin)
              mdist (distance of misses from the origin)
              norient (number of orientations; max of 8)
              debugflag (1 for debug output)
      Return: sela with additional sels, or null on error

  Notes:
      (1) Adds hitmiss Sels for the intersection of two lines.
          If the lines are very thin, they must be nearly orthogonal
          to register.
      (2) The number of Sels generated is equal to @norient.
      (3) If @norient == 2, this generates 2 Sels of crosses, each with
          two perpendicular lines of hits.  One Sel has horizontal and
          vertical hits; the other has hits along lines at +-45 degrees.
          Likewise, if @norient == 3, this generates 3 Sels of crosses
          oriented at 30 degrees with each other.
      (4) It is suggested that @hlsize be chosen at least 1 greater
          than @mdist.  Try values of (@hlsize, @mdist) such as
          (6,5), (7,6), (8,7), (9,7), etc.

=head2 selaAddDwaCombs

SELA * selaAddDwaCombs ( SELA *sela )

  selaAddDwaCombs()

      Input:  sela (<optional>)
      Return: sela with additional sels, or null on error

  Notes:
      (1) Adds all comb (horizontal, vertical) Sels that are
          used in composite linear morphological operations
          up to 63 pixels in length, which are the sizes over
          which dwa code can be generated.

=head2 selaAddDwaLinear

SELA * selaAddDwaLinear ( SELA *sela )

  selaAddDwaLinear()

      Input:  sela (<optional>)
      Return: sela with additional sels, or null on error

  Notes:
      (1) Adds all linear (horizontal, vertical) sels from
          2 to 63 pixels in length, which are the sizes over
          which dwa code can be generated.

=head2 selaAddHitMiss

SELA * selaAddHitMiss ( SELA *sela )

  selaAddHitMiss()

      Input:  sela  (<optional>)
      Return: sela with additional sels, or null on error

=head2 selaAddTJunctions

SELA * selaAddTJunctions ( SELA *sela, l_float32 hlsize, l_float32 mdist, l_int32 norient, l_int32 debugflag )

  selaAddTJunctions()

      Input:  sela (<optional>)
              hlsize (length of each line of hits from origin)
              mdist (distance of misses from the origin)
              norient (number of orientations; max of 8)
              debugflag (1 for debug output)
      Return: sela with additional sels, or null on error

  Notes:
      (1) Adds hitmiss Sels for the T-junction of two lines.
          If the lines are very thin, they must be nearly orthogonal
          to register.
      (2) The number of Sels generated is 4 * @norient.
      (3) It is suggested that @hlsize be chosen at least 1 greater
          than @mdist.  Try values of (@hlsize, @mdist) such as
          (6,5), (7,6), (8,7), (9,7), etc.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
