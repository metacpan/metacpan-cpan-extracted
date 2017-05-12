package Image::Leptonica::Func::morphseq;
$Image::Leptonica::Func::morphseq::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::morphseq

=head1 VERSION

version 0.04

=head1 C<morphseq.c>

  morphseq.c

      Run a sequence of binary rasterop morphological operations
            PIX     *pixMorphSequence()

      Run a sequence of binary composite rasterop morphological operations
            PIX     *pixMorphCompSequence()

      Run a sequence of binary dwa morphological operations
            PIX     *pixMorphSequenceDwa()

      Run a sequence of binary composite dwa morphological operations
            PIX     *pixMorphCompSequenceDwa()

      Parser verifier for binary morphological operations
            l_int32  morphSequenceVerify()

      Run a sequence of grayscale morphological operations
            PIX     *pixGrayMorphSequence()

      Run a sequence of color morphological operations
            PIX     *pixColorMorphSequence()

=head1 FUNCTIONS

=head2 morphSequenceVerify

l_int32 morphSequenceVerify ( SARRAY *sa )

  morphSequenceVerify()

      Input:  sarray (of operation sequence)
      Return: TRUE if valid; FALSE otherwise or on error

  Notes:
      (1) This does verification of valid binary morphological
          operation sequences.
      (2) See pixMorphSequence() for notes on valid operations
          in the sequence.

=head2 pixColorMorphSequence

PIX * pixColorMorphSequence ( PIX *pixs, const char *sequence, l_int32 dispsep, l_int32 dispy )

  pixColorMorphSequence()

      Input:  pixs
              sequence (string specifying sequence)
              dispsep (controls debug display of each result in the sequence:
                       0: no output
                       > 0: gives horizontal separation in pixels between
                            successive displays
                       < 0: pdf output; abs(dispsep) is used for naming)
              dispy (if dispsep > 0, this gives the y-value of the
                     UL corner for display; otherwise it is ignored)
      Return: pixd, or null on error

  Notes:
      (1) This works on 32 bpp rgb images.
      (2) Each component is processed separately.
      (3) This runs a pipeline of operations; no branching is allowed.
      (4) This only uses brick SELs.
      (5) A new image is always produced; the input image is not changed.
      (6) This contains an interpreter, allowing sequences to be
          generated and run.
      (7) Sel sizes (width, height) must each be odd numbers.
      (8) The format of the sequence string is defined below.
      (9) Intermediate results can optionally be displayed.
      (10) The sequence string is formatted as follows:
            - An arbitrary number of operations,  each separated
              by a '+' character.  White space is ignored.
            - Each operation begins with a case-independent character
              specifying the operation:
                 d or D  (dilation)
                 e or E  (erosion)
                 o or O  (opening)
                 c or C  (closing)
            - The args to the morphological operations are bricks of hits,
              and are formatted as a.b, where a and b are horizontal and
              vertical dimensions, rsp. (each must be an odd number)
           Example valid sequences are:
             "c5.3 + o7.5"
             "D9.1"

=head2 pixGrayMorphSequence

PIX * pixGrayMorphSequence ( PIX *pixs, const char *sequence, l_int32 dispsep, l_int32 dispy )

  pixGrayMorphSequence()

      Input:  pixs
              sequence (string specifying sequence)
              dispsep (controls debug display of each result in the sequence:
                       0: no output
                       > 0: gives horizontal separation in pixels between
                            successive displays
                       < 0: pdf output; abs(dispsep) is used for naming)
              dispy (if dispsep > 0, this gives the y-value of the
                     UL corner for display; otherwise it is ignored)
      Return: pixd, or null on error

  Notes:
      (1) This works on 8 bpp grayscale images.
      (2) This runs a pipeline of operations; no branching is allowed.
      (3) This only uses brick SELs.
      (4) A new image is always produced; the input image is not changed.
      (5) This contains an interpreter, allowing sequences to be
          generated and run.
      (6) The format of the sequence string is defined below.
      (7) In addition to morphological operations, the composite
          morph/subtract tophat can be performed.
      (8) Sel sizes (width, height) must each be odd numbers.
      (9) Intermediate results can optionally be displayed
      (10) The sequence string is formatted as follows:
            - An arbitrary number of operations,  each separated
              by a '+' character.  White space is ignored.
            - Each operation begins with a case-independent character
              specifying the operation:
                 d or D  (dilation)
                 e or E  (erosion)
                 o or O  (opening)
                 c or C  (closing)
                 t or T  (tophat)
            - The args to the morphological operations are bricks of hits,
              and are formatted as a.b, where a and b are horizontal and
              vertical dimensions, rsp. (each must be an odd number)
            - The args to the tophat are w or W (for white tophat)
              or b or B (for black tophat), followed by a.b as for
              the dilation, erosion, opening and closing.
           Example valid sequences are:
             "c5.3 + o7.5"
             "c9.9 + tw9.9"

=head2 pixMorphCompSequence

PIX * pixMorphCompSequence ( PIX *pixs, const char *sequence, l_int32 dispsep )

  pixMorphCompSequence()

      Input:  pixs
              sequence (string specifying sequence)
              dispsep (controls debug display of each result in the sequence:
                       0: no output
                       > 0: gives horizontal separation in pixels between
                            successive displays
                       < 0: pdf output; abs(dispsep) is used for naming)
      Return: pixd, or null on error

  Notes:
      (1) This does rasterop morphology on binary images, using composite
          operations for extra speed on large Sels.
      (2) Safe closing is used atomically.  However, if you implement a
          closing as a sequence with a dilation followed by an
          erosion, it will not be safe, and to ensure that you have
          no boundary effects you must add a border in advance and
          remove it at the end.
      (3) For other usage details, see the notes for pixMorphSequence().
      (4) The sequence string is formatted as follows:
            - An arbitrary number of operations,  each separated
              by a '+' character.  White space is ignored.
            - Each operation begins with a case-independent character
              specifying the operation:
                 d or D  (dilation)
                 e or E  (erosion)
                 o or O  (opening)
                 c or C  (closing)
                 r or R  (rank binary reduction)
                 x or X  (replicative binary expansion)
                 b or B  (add a border of 0 pixels of this size)
            - The args to the morphological operations are bricks of hits,
              and are formatted as a.b, where a and b are horizontal and
              vertical dimensions, rsp.
            - The args to the reduction are a sequence of up to 4 integers,
              each from 1 to 4.
            - The arg to the expansion is a power of two, in the set
              {2, 4, 8, 16}.

=head2 pixMorphCompSequenceDwa

PIX * pixMorphCompSequenceDwa ( PIX *pixs, const char *sequence, l_int32 dispsep )

  pixMorphCompSequenceDwa()

      Input:  pixs
              sequence (string specifying sequence)
              dispsep (controls debug display of each result in the sequence:
                       0: no output
                       > 0: gives horizontal separation in pixels between
                            successive displays
                       < 0: pdf output; abs(dispsep) is used for naming)
      Return: pixd, or null on error

  Notes:
      (1) This does dwa morphology on binary images, using brick Sels.
      (2) This runs a pipeline of operations; no branching is allowed.
      (3) It implements all brick Sels that have dimensions up to 63
          on each side, using a composite (linear + comb) when useful.
      (4) A new image is always produced; the input image is not changed.
      (5) This contains an interpreter, allowing sequences to be
          generated and run.
      (6) See pixMorphSequence() for further information about usage.

=head2 pixMorphSequence

PIX * pixMorphSequence ( PIX *pixs, const char *sequence, l_int32 dispsep )

  pixMorphSequence()

      Input:  pixs
              sequence (string specifying sequence)
              dispsep (controls debug display of each result in the sequence:
                       0: no output
                       > 0: gives horizontal separation in pixels between
                            successive displays
                       < 0: pdf output; abs(dispsep) is used for naming)
      Return: pixd, or null on error

  Notes:
      (1) This does rasterop morphology on binary images.
      (2) This runs a pipeline of operations; no branching is allowed.
      (3) This only uses brick Sels, which are created on the fly.
          In the future this will be generalized to extract Sels from
          a Sela by name.
      (4) A new image is always produced; the input image is not changed.
      (5) This contains an interpreter, allowing sequences to be
          generated and run.
      (6) The format of the sequence string is defined below.
      (7) In addition to morphological operations, rank order reduction
          and replicated expansion allow operations to take place
          downscaled by a power of 2.
      (8) Intermediate results can optionally be displayed.
      (9) Thanks to Dar-Shyang Lee, who had the idea for this and
          built the first implementation.
      (10) The sequence string is formatted as follows:
            - An arbitrary number of operations,  each separated
              by a '+' character.  White space is ignored.
            - Each operation begins with a case-independent character
              specifying the operation:
                 d or D  (dilation)
                 e or E  (erosion)
                 o or O  (opening)
                 c or C  (closing)
                 r or R  (rank binary reduction)
                 x or X  (replicative binary expansion)
                 b or B  (add a border of 0 pixels of this size)
            - The args to the morphological operations are bricks of hits,
              and are formatted as a.b, where a and b are horizontal and
              vertical dimensions, rsp.
            - The args to the reduction are a sequence of up to 4 integers,
              each from 1 to 4.
            - The arg to the expansion is a power of two, in the set
              {2, 4, 8, 16}.
      (11) An example valid sequence is:
               "b32 + o1.3 + C3.1 + r23 + e2.2 + D3.2 + X4"
           In this example, the following operation sequence is carried out:
             * b32: Add a 32 pixel border around the input image
             * o1.3: Opening with vert sel of length 3 (e.g., 1 x 3)
             * C3.1: Closing with horiz sel of length 3  (e.g., 3 x 1)
             * r23: Two successive 2x2 reductions with rank 2 in the first
                    and rank 3 in the second.  The result is a 4x reduced pix.
             * e2.2: Erosion with a 2x2 sel (origin will be at x,y: 0,0)
             * d3.2: Dilation with a 3x2 sel (origin will be at x,y: 1,0)
             * X4: 4x replicative expansion, back to original resolution
      (12) The safe closing is used.  However, if you implement a
           closing as separable dilations followed by separable erosions,
           it will not be safe.  For that situation, you need to add
           a sufficiently large border as the first operation in
           the sequence.  This will be removed automatically at the
           end.  There are two cautions:
              - When computing what is sufficient, remember that if
                reductions are carried out, the border is also reduced.
              - The border is removed at the end, so if a border is
                added at the beginning, the result must be at the
                same resolution as the input!

=head2 pixMorphSequenceDwa

PIX * pixMorphSequenceDwa ( PIX *pixs, const char *sequence, l_int32 dispsep )

  pixMorphSequenceDwa()

      Input:  pixs
              sequence (string specifying sequence)
              dispsep (controls debug display of each result in the sequence:
                       0: no output
                       > 0: gives horizontal separation in pixels between
                            successive displays
                       < 0: pdf output; abs(dispsep) is used for naming)
      Return: pixd, or null on error

  Notes:
      (1) This does dwa morphology on binary images.
      (2) This runs a pipeline of operations; no branching is allowed.
      (3) This only uses brick Sels that have been pre-compiled with
          dwa code.
      (4) A new image is always produced; the input image is not changed.
      (5) This contains an interpreter, allowing sequences to be
          generated and run.
      (6) See pixMorphSequence() for further information about usage.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
