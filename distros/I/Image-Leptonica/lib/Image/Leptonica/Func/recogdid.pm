package Image::Leptonica::Func::recogdid;
$Image::Leptonica::Func::recogdid::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::recogdid

=head1 VERSION

version 0.04

=head1 C<recogdid.c>

  recogdid.c

      Top-level identification
         l_int32           recogDecode()

      Generate decoding arrays
         l_int32           recogMakeDecodingArrays()
         static l_int32    recogMakeDecodingArray()

      Dynamic programming for best path
         l_int32           recogRunViterbi()
         l_int32           recogRescoreDidResult()
         static PIX       *recogShowPath()

      Create/destroy temporary DID data
         l_int32           recogCreateDid()
         l_int32           recogDestroyDid()

      Various helpers
         l_int32           recogDidExists()
         L_RDID           *recogGetDid()
         static l_int32    recogGetWindowedArea()
         l_int32           recogSetChannelParams()
         static l_int32    recogTransferRchToDid()

  See recogbasic.c for examples of training a recognizer, which is
  required before it can be used for document image decoding.

  Gary Kopec pioneered this hidden markov approach to "Document Image
  Decoding" (DID) in the early 1990s.  It is based on estimation
  using a generative model of the image generation process, and
  provides the most likely decoding of an image if the model is correct.
  Given the model, it finds the maximum a posteriori (MAP) "message"
  given the observed image.  The model describes how to generate
  an image from a message, and the MAP message is derived from the
  observed image using Bayes' theorem.  This approach can also be used
  to build the model, using the iterative expectation/maximization
  method from labelled but errorful data.

  In a little more detail: The model comprises three things: the ideal
  printed character templates, the independent bit-flip noise model, and
  the character setwidths.  When a character is printed, the setwidth
  is the distance in pixels that you move forward before being able
  to print the next character.  It is typically slightly less than the
  width of the character template: if too small, an extra character can be
  hallucinated; if too large, it will not be able to match the next
  character template on the line.  The model assumes that the probabilities
  of bit flip depend only on the assignment of the pixel to background
  or template foreground.  The multilevel templates have different
  bit flip probabilities for each level.  Because a character image
  is composed of many pixels, each of which can be independently flipped,
  the actual probability of seeing any rendering is exceedingly small,
  being composed of the product of the probabilities for each pixel.
  The log likelihood is used both to avoid numeric underflow and,
  more importantly, because it results in a summation of independent
  pixel probabilities.  That summation can be shown, in Kopec's
  original paper, to consist of a sum of two terms: (a) the number of
  fg pixels in the bit-and of the observed image with the ideal
  template and (b) the number of fg pixels in the template.  Each
  has a coefficient that depends only on the bit-flip probabilities
  for the fg and bg.  A beautiful result, and computationally simple!
  One nice feature of this approach is that the result of the decoding
  is not very sensitive to the values  used for the bit flip probabilities.

  The procedure for finding the best decoding (MAP) for a given image goes
  under several names: Viterbi, dynamic programming, hidden markov model.
  It is called a "hidden markov model" because the templates are assumed
  to be printed serially and we don't know what they are -- the identity
  of the templates must be inferred from the observed image.
  The possible decodings form a dense trellis over the pixel positions,
  where at each pixel position you have the possibility of having any
  of the characters printed there (with some reference point) or having
  a single pixel wide space inserted there.  Thus, before the trellis
  can be traversed, we must do the work of finding the log probability,
  at each pixel location, that each of the templates was printed there.
  Armed with those arrays of data, the dynamic programming procedure
  moves from left to right, one pixel at a time, recursively finding
  the path with the highest log probability that gets to that pixel
  position (and noting which template was printed to arrive there).
  After reaching the right side of the image, we can simply backtrack
  along the path, jumping over each template that lies on the highest
  scoring path.  This best path thus only goes through a few of the
  pixel positions.

  There are two refinements to the original Kopec paper.  In the first,
  one uses multiple, non-overlapping fg templates, each with its own
  bit flip probability.  This makes sense, because the probability
  that a fg boundary pixel flips to bg is greater than that of a fg
  pixel not on the boundary.  And the flip probability of a fg boundary
  pixel is smaller than that of a bg boundary pixel, which in turn
  is greater than that of a bg pixel not on a boundary (the latter
  is taken to be the true background).  Then the simplest realistic
  multiple template model has three templates that are not background.

  In the second refinement, a heuristic (strict upper bound) is used
  iteratively in the Viterbi process to compute the log probabilities.
  Using the heuristic, you find the best path, and then score all nodes
  on that path with the actual probability, which is guaranteed to
  be a smaller number.  You run this iteratively, rescoring just the best
  found path each time.  After each rescoring, the path may change because
  the local scores have been reduced.  However, the process converges
  rapidly, and when it doesn't change, it must be the best path because
  it is properly scored (even if neighboring paths are heuristically
  scored).  The heuristic score is found column-wise by assuming
  that all the fg pixels in the template are on fg pixels in the image --
  we just take the minimum of the number of pixels in the template
  and image column.  This can easily give a 10-fold reduction in
  computation because the heuristic score can be computed much faster
  than the exact score.

  For reference, the classic paper on the approach by Kopec is:
  * "Document Image Decoding Using Markov Source Models", IEEE Trans.
    PAMI, Vol 16, No. 6, June 1994, pp 602-617.
  A refinement of the method for multilevel templates by Kopec is:
  * "Multilevel Character Templates for Document Image Decoding",
    Proc. SPIE 3027, Document Recognition IV, p. 168ff, 1997.
  Further refinements for more efficient decoding are given in these
  two papers, which are both stored on leptonica.org:
  * "Document Image Decoding using Iterated Complete Path Search", Minka,
    Bloomberg and Popat, Proc. SPIE Vol 4307, p. 250-258, Document
    Recognition and Retrieval VIII, San Jose, CA 2001.
  * "Document Image Decoding using Iterated Complete Path Search with
    Subsampled Heuristic Scoring", Bloomberg, Minka and Popat, ICDAR 2001,
    p. 344-349, Sept. 2001, Seattle.

=head1 FUNCTIONS

=head2 recogCreateDid

l_int32 recogCreateDid ( L_RECOG *recog, PIX *pixs )

  recogCreateDid()

      Input:  recog
              pixs (of 1 bpp image to match)
      Return: 0 if OK, 1 on error

=head2 recogDecode

l_int32 recogDecode ( L_RECOG *recog, PIX *pixs, l_int32 nlevels, PIX **ppixdb )

  recogDecode()

      Input:  recog (with LUT's pre-computed)
              pixs (typically of multiple touching characters, 1 bpp)
              nlevels (of templates; 2 for now)
              &pixdb (<optional return> debug result; can be null)
      Return: 0 if OK, 1 on error

=head2 recogDestroyDid

l_int32 recogDestroyDid ( L_RECOG *recog )

  recogDestroyDid()

      Input:  recog
      Return: 0 if OK, 1 on error

  Notes:
      (1) As the signature indicates, this is owned by the recog, and can
          only be destroyed using this function.

=head2 recogDidExists

l_int32 recogDidExists ( L_RECOG *recog )

  recogDidExists()

      Input:  recog
      Return: 1 if recog->did exists; 0 if not or on error.

=head2 recogGetDid

L_RDID * recogGetDid ( L_RECOG *recog )

  recogGetDid()

      Input:  recog
      Return: did (still owned by the recog), or null on error

  Notes:
      (1) This also makes sure the arrays are defined.

=head2 recogMakeDecodingArrays

l_int32 recogMakeDecodingArrays ( L_RECOG *recog, PIX *pixs, l_int32 debug )

  recogMakeDecodingArrays()

      Input:  recog (with LUT's pre-computed)
              pixs (typically of multiple touching characters, 1 bpp)
              debug (1 for debug output; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Generates the bit-and sum arrays for each character template
          along pixs.  These are used in the dynamic programming step.
      (2) Previous arrays are destroyed and the new arrays are allocated.
      (3) The values are saved in the scoring arrays at the left edge
          of the template.  They are used in the viterbi process
          at the setwidth position (which is near the RHS of the template
          as it is positioned on pixs) in the generated trellis.

=head2 recogRunViterbi

l_int32 recogRunViterbi ( L_RECOG *recog, PIX **ppixdb )

  recogRunViterbi()

      Input:  recog (with LUT's pre-computed)
              &pixdb (<optional return> debug result; can be null)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is recursive, in that
          (a) we compute the score successively at all pixel positions x,
          (b) to compute the score at x in the trellis, for each
              template we look backwards to (x - setwidth) to get the
              score if that template were to be printed with its
              setwidth location at x.  We save at x the template and
              score that maximizes the sum of the score at (x - setwidth)
              and the log-likelihood for the template to be printed with
              its LHS there.

=head2 recogSetChannelParams

l_int32 recogSetChannelParams ( L_RECOG *recog, l_int32 nlevels )

  recogSetChannelParams()

      Input:  recog
              nlevels
      Return: 0 if OK, 1 on error

  Notes:
      (1) This converts the independent bit-flip probabilities in the
          "channel" into log-likelihood coefficients on image sums.
          These coefficients are only defined for the non-background
          template levels.  Thus for nlevels = 2 (one fg, one bg),
          only beta[1] and gamma[1] are used.  For nlevels = 4 (three
          fg templates), we use beta[1-3] and gamma[1-3].

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
