package Image::Leptonica::Func::partition;
$Image::Leptonica::Func::partition::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::partition

=head1 VERSION

version 0.04

=head1 C<partition.c>

   partition.c

      Whitespace block extraction
          BOXA            *boxaGetWhiteblocks()

      Helpers
          static PARTEL   *partelCreate()
          static void      partelDestroy()
          static l_int32   partelSetSize()
          static BOXA     *boxaGenerateSubboxes()
          static BOX      *boxaSelectPivotBox()
          static l_int32   boxaCheckIfOverlapIsSmall()
          BOXA            *boxaPruneSortedOnOverlap()

=head1 FUNCTIONS

=head2 boxaGetWhiteblocks

BOXA * boxaGetWhiteblocks ( BOXA *boxas, BOX *box, l_int32 sortflag, l_int32 maxboxes, l_float32 maxoverlap, l_int32 maxperim, l_float32 fract, l_int32 maxpops )

  boxaGetWhiteblocks()

      Input:  boxas (typically, a set of bounding boxes of fg components)
              box (initial region; typically including all boxes in boxas;
                   if null, it computes the region to include all boxes
                   in boxas)
              sortflag (L_SORT_BY_WIDTH, L_SORT_BY_HEIGHT,
                        L_SORT_BY_MIN_DIMENSION, L_SORT_BY_MAX_DIMENSION,
                        L_SORT_BY_PERIMETER, L_SORT_BY_AREA)
              maxboxes (maximum number of output whitespace boxes; e.g., 100)
              maxoverlap (maximum fractional overlap of a box by any
                          of the larger boxes; e.g., 0.2)
              maxperim (maximum half-perimeter, in pixels, for which
                        pivot is selected by proximity to box centroid;
                        e.g., 200)
              fract (fraction of box diagonal that is an acceptable
                     distance from the box centroid to select the pivot;
                     e.g., 0.2)
              maxpops (maximum number of pops from the heap; use 0 as default)
      Return: boxa (of sorted whitespace boxes), or null on error

  Notes:
      (1) This uses the elegant Breuel algorithm, found in "Two
          Geometric Algorithms for Layout Analysis", 2002,
          url: "citeseer.ist.psu.edu/breuel02two.html".
          It starts with the bounding boxes (b.b.) of the connected
          components (c.c.) in a region, along with the rectangle
          representing that region.  It repeatedly divides the
          rectangle into four maximal rectangles that exclude a
          pivot rectangle, sorting them in a priority queue
          according to one of the six sort flags.  It returns a boxa
          of the "largest" set that have no intersection with boxes
          from the input boxas.
      (2) If box == NULL, the initial region is the minimal region
          that includes the origin and every box in boxas.
      (3) maxboxes is the maximum number of whitespace boxes that will
          be returned.  The actual number will depend on the image
          and the values chosen for maxoverlap and maxpops.  In many
          cases, the actual number will be 'maxboxes'.
      (4) maxoverlap allows pruning of whitespace boxes depending on
          the overlap.  To avoid all pruning, use maxoverlap = 1.0.
          To select only boxes that have no overlap with each other
          (maximal pruning), choose maxoverlap = 0.0.
          Otherwise, no box can have more than the 'maxoverlap' fraction
          of its area overlapped by any larger (in the sense of the
          sortflag) box.
      (5) Choose maxperim (actually, maximum half-perimeter) to
          represent a c.c. that is small enough so that you don't care
          about the white space that could be inside of it.  For all such
          c.c., the pivot for 'quadfurcation' of a rectangle is selected
          as having a reasonable proximity to the rectangle centroid.
      (6) Use fract in the range [0.0 ... 1.0].  Set fract = 0.0
          to choose the small box nearest the centroid as the pivot.
          If you choose fract > 0.0, it is suggested that you call
          boxaPermuteRandom() first, to permute the boxes (see usage below).
          This should reduce the search time for each of the pivot boxes.
      (7) Choose maxpops to be the maximum number of rectangles that
          are popped from the heap.  This is an indirect way to limit the
          execution time.  Use 0 for default (a fairly large number).
          At any time, you can expect the heap to contain about
          2.5 times as many boxes as have been popped off.
      (8) The output result is a sorted set of overlapping
          boxes, constrained by 'maxboxes', 'maxoverlap' and 'maxpops'.
      (9) The main defect of the method is that it abstracts out the
          actual components, retaining only the b.b. for analysis.
          Consider a component with a large b.b.  If this is chosen
          as a pivot, all white space inside is immediately taken
          out of consideration.  Furthermore, even if it is never chosen
          as a pivot, as the partitioning continues, at no time will
          any of the whitespace inside this component be part of a
          rectangle with zero overlapping boxes.  Thus, the interiors
           of all boxes are necessarily excluded from the union of
           the returned whitespace boxes.
     (10) USAGE: One way to accommodate to this weakness is to remove such
          large b.b. before starting the computation.  For example,
          if 'box' is an input image region containing 'boxa' b.b. of c.c.:

                   // Faster pivot choosing
               boxaPermuteRandom(boxa, boxa);

                   // Remove anything either large width or height
               boxat = boxaSelectBySize(boxa, maxwidth, maxheight,
                                        L_SELECT_IF_BOTH, L_SELECT_IF_LT,
                                        NULL);

               boxad = boxaGetWhiteblocks(boxat, box, type, maxboxes,
                                          maxoverlap, maxperim, fract,
                                          maxpops);

          The result will be rectangular regions of "white space" that
          extend into (and often through) the excluded components.
     (11) As a simple example, suppose you wish to find the columns on a page.
          First exclude large c.c. that may block the columns, and then call:

               boxad = boxaGetWhiteblocks(boxa, box, L_SORT_BY_HEIGHT,
                                          20, 0.15, 200, 0.2, 2000);

          to get the 20 tallest boxes with no more than 0.15 overlap
          between a box and any of the taller ones, and avoiding the
          use of any c.c. with a b.b. half perimeter greater than 200
          as a pivot.

=head2 boxaPruneSortedOnOverlap

BOXA * boxaPruneSortedOnOverlap ( BOXA *boxas, l_float32 maxoverlap )

  boxaPruneSortedOnOverlap()

      Input:  boxas (sorted by size in decreasing order)
              maxoverlap (maximum fractional overlap of a box by any
                          of the larger boxes)
      Return: boxad (pruned), or null on error

  Notes:
      (1) This selectively removes smaller boxes when they are overlapped
          by any larger box by more than the input 'maxoverlap' fraction.
      (2) To avoid all pruning, use maxoverlap = 1.0.  To select only
          boxes that have no overlap with each other (maximal pruning),
          set maxoverlap = 0.0.
      (3) If there are no boxes in boxas, returns an empty boxa.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
