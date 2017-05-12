package Image::Leptonica::Func::watershed;
$Image::Leptonica::Func::watershed::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::watershed

=head1 VERSION

version 0.04

=head1 C<watershed.c>

  watershed.c

      Top-level
            L_WSHED         *wshedCreate()
            void             wshedDestroy()
            l_int32          wshedApply()

      Helpers
            static l_int32   identifyWatershedBasin()
            static l_int32   mergeLookup()
            static l_int32   wshedGetHeight()
            static void      pushNewPixel()
            static void      popNewPixel()
            static void      pushWSPixel()
            static void      popWSPixel()
            static void      debugPrintLUT()
            static void      debugWshedMerge()

      Output
            l_int32          wshedBasins()
            PIX             *wshedRenderFill()
            PIX             *wshedRenderColors()

  The watershed function identifies the "catch basins" of the input
  8 bpp image, with respect to the specified seeds or "markers".
  The use is in segmentation, but the selection of the markers is
  critical to getting meaningful results.

  How are the markers selected?  You can't simply use the local
  minima, because a typical image has sufficient noise so that
  a useful catch basin can easily have multiple local minima.  However
  they are selected, the question for the watershed function is
  how to handle local minima that are not markers.  The reason
  this is important is because of the algorithm used to find the
  watersheds, which is roughly like this:

    (1) Identify the markers and the local minima, and enter them
        into a priority queue based on the pixel value.  Each marker
        is shrunk to a single pixel, if necessary, before the
        operation starts.
    (2) Feed the priority queue with neighbors of pixels that are
        popped off the queue.  Each of these queue pixels is labelled
        with the index value of its parent.
    (3) Each pixel is also labelled, in a 32-bit image, with the marker
        or local minimum index, from which it was originally derived.
    (4) There are actually 3 classes of labels: seeds, minima, and
        fillers.  The fillers are labels of regions that have already
        been identified as watersheds and are continuing to fill, for
        the purpose of finding higher watersheds.
    (5) When a pixel is popped that has already been labelled in the
        32-bit image and that label differs from the label of its
        parent (stored in the queue pixel), a boundary has been crossed.
        There are several cases:
         (a) Both parents are derived from markers but at least one
             is not deep enough to become a watershed.  Absorb the
             shallower basin into the deeper one, fixing the LUT to
             redirect the shallower index to the deeper one.
         (b) Both parents are derived from markers and both are deep
             enough.  Identify and save the watershed for each marker.
         (c) One parent was derived from a marker and the other from
             a minima: absorb the minima basin into the marker basin.
         (d) One parent was derived from a marker and the other is
             a filler: identify and save the watershed for the marker.
         (e) Both parents are derived from minima: merge them.
         (f) One parent is a filler and the other is derived from a
             minima: merge the minima into the filler.
    (6) The output of the watershed operation consists of:
         - a pixa of the basins
         - a pta of the markers
         - a numa of the watershed levels

  Typical usage:
      L_WShed *wshed = wshedCreate(pixs, pixseed, mindepth, 0);
      wshedApply(wshed);

      wshedBasins(wshed, &pixa, &nalevels);
        ... do something with pixa, nalevels ...
      pixaDestroy(&pixa);
      numaDestroy(&nalevels);

      Pix *pixd = wshedRenderFill(wshed);

      wshedDestroy(&wshed);

=head1 FUNCTIONS

=head2 wshedApply

l_int32 wshedApply ( L_WSHED *wshed )

  wshedApply()

      Input:  wshed (generated from wshedCreate())
      Return: 0 if OK, 1 on error

  Iportant note:
      (1) This is buggy.  It seems to locate watersheds that are
          duplicates.  The watershed extraction after complete fill
          grabs some regions belonging to existing watersheds.
          See prog/watershedtest.c for testing.

=head2 wshedBasins

l_int32 wshedBasins ( L_WSHED *wshed, PIXA **ppixa, NUMA **pnalevels )

  wshedBasins()

      Input:  wshed
              &pixa  (<optional return> mask of watershed basins)
              &nalevels   (<optional return> watershed levels)
      Return: 0 if OK, 1 on error

=head2 wshedCreate

L_WSHED * wshedCreate ( PIX *pixs, PIX *pixm, l_int32 mindepth, l_int32 debugflag )

  wshedCreate()

      Input:  pixs  (8 bpp source)
              pixm  (1 bpp 'marker' seed)
              mindepth (minimum depth; anything less is not saved)
              debugflag (1 for debug output)
      Return: WShed, or null on error

  Notes:
      (1) It is not necessary for the fg pixels in the seed image
          be at minima, or that they be isolated.  We extract a
          single pixel from each connected component, and a seed
          anywhere in a watershed will eventually label the watershed
          when the filling level reaches it.
      (2) Set mindepth to some value to ignore noise in pixs that
          can create small local minima.  Any watershed shallower
          than mindepth, even if it has a seed, will not be saved;
          It will either be incorporated in another watershed or
          eliminated.

=head2 wshedDestroy

void wshedDestroy ( L_WSHED **pwshed )

  wshedDestroy()

      Input:  &wshed (<will be set to null before returning>)
      Return: void

=head2 wshedRenderColors

PIX * wshedRenderColors ( L_WSHED *wshed )

  wshedRenderColors()

      Input:  wshed
      Return: pixd (initial image with all basins filled), or null on error

=head2 wshedRenderFill

PIX * wshedRenderFill ( L_WSHED *wshed )

  wshedRenderFill()

      Input:  wshed
      Return: pixd (initial image with all basins filled), or null on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
