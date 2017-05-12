package Image::Leptonica::Func::maze;
$Image::Leptonica::Func::maze::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::maze

=head1 VERSION

version 0.04

=head1 C<maze.c>

  maze.c

      This is a game with a pedagogical slant.  A maze is represented
      by a binary image.  The ON pixels (fg) are walls.  The goal is
      to navigate on OFF pixels (bg), using Manhattan steps
      (N, S, E, W), between arbitrary start and end positions.
      The problem is thus to find the shortest route between two points
      in a binary image that are 4-connected in the bg.  This is done
      with a breadth-first search, implemented with a queue.
      We also use a queue of pointers to generate the maze (image).

          PIX             *generateBinaryMaze()
          static MAZEEL   *mazeelCreate()

          PIX             *pixSearchBinaryMaze()
          static l_int32   localSearchForBackground()

      Generalizing a maze to a grayscale image, the search is
      now for the "shortest" or least cost path, for some given
      cost function.

          PIX             *pixSearchGrayMaze()


      Elegant method for finding largest white (or black) rectangle
      in an image.

          l_int32          pixFindLargestRectangle()

=head1 FUNCTIONS

=head2 generateBinaryMaze

PIX * generateBinaryMaze ( l_int32 w, l_int32 h, l_int32 xi, l_int32 yi, l_float32 wallps, l_float32 ranis )

  generateBinaryMaze()

      Input:  w, h  (size of maze)
              xi, yi  (initial location)
              wallps (probability that a pixel to the side is ON)
              ranis (ratio of prob that pixel in forward direction
                     is a wall to the probability that pixel in
                     side directions is a wall)
      Return: pix, or null on error

  Notes:
      (1) We have two input probability factors that determine the
          density of walls and average length of straight passages.
          When ranis < 1.0, you are more likely to generate a wall
          to the side than going forward.  Enter 0.0 for either if
          you want to use the default values.
      (2) This is a type of percolation problem, and exhibits
          different phases for different parameters wallps and ranis.
          For larger values of these parameters, regions in the maze
          are not explored because the maze generator walls them
          off and cannot get through.  The boundary between the
          two phases in this two-dimensional parameter space goes
          near these values:
                wallps       ranis
                0.35         1.00
                0.40         0.85
                0.45         0.70
                0.50         0.50
                0.55         0.40
                0.60         0.30
                0.65         0.25
                0.70         0.19
                0.75         0.15
                0.80         0.11
      (3) Because there is a considerable amount of overhead in calling
          pixGetPixel() and pixSetPixel(), this function can be sped
          up with little effort using raster line pointers and the
          GET_DATA* and SET_DATA* macros.

=head2 pixFindLargestRectangle

l_int32 pixFindLargestRectangle ( PIX *pixs, l_int32 polarity, BOX **pbox, const char *debugfile )

  pixFindLargestRectangle()

      Input:  pixs  (1 bpp)
              polarity (0 within background, 1 within foreground)
              &box (<return> largest rectangle, either by area or
                    by perimeter)
              debugflag (1 to output image with rectangle drawn on it)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Why is this here?  This is a simple and elegant solution to
          a problem in computational geometry that at first appears
          quite difficult: what is the largest rectangle that can
          be placed in the image, covering only pixels of one polarity
          (bg or fg)?  The solution is O(n), where n is the number
          of pixels in the image, and it requires nothing more than
          using a simple recursion relation in a single sweep of the image.
      (2) In a sweep from UL to LR with left-to-right being the fast
          direction, calculate the largest white rectangle at (x, y),
          using previously calculated values at pixels #1 and #2:
             #1:    (x, y - 1)
             #2:    (x - 1, y)
          We also need the most recent "black" pixels that were seen
          in the current row and column.
          Consider the largest area.  There are only two possibilities:
             (a)  Min(w(1), horizdist) * (h(1) + 1)
             (b)  Min(h(2), vertdist) * (w(2) + 1)
          where
             horizdist: the distance from the rightmost "black" pixel seen
                        in the current row across to the current pixel
             vertdist: the distance from the lowest "black" pixel seen
                       in the current column down to the current pixel
          and we choose the Max of (a) and (b).
      (3) To convince yourself that these recursion relations are correct,
          it helps to draw the maximum rectangles at #1 and #2.
          Then for #1, you try to extend the rectangle down one line,
          so that the height is h(1) + 1.  Do you get the full
          width of #1, w(1)?  It depends on where the black pixels are
          in the current row.  You know the final width is bounded by w(1)
          and w(2) + 1, but the actual value depends on the distribution
          of black pixels in the current row that are at a distance
          from the current pixel that is between these limits.
          We call that value "horizdist", and the area is then given
          by the expression (a) above.  Using similar reasoning for #2,
          where you attempt to extend the rectangle to the right
          by 1 pixel, you arrive at (b).  The largest rectangle is
          then found by taking the Max.

=head2 pixSearchBinaryMaze

PTA * pixSearchBinaryMaze ( PIX *pixs, l_int32 xi, l_int32 yi, l_int32 xf, l_int32 yf, PIX **ppixd )

  pixSearchBinaryMaze()

      Input:  pixs (1 bpp, maze)
              xi, yi  (beginning point; use same initial point
                       that was used to generate the maze)
              xf, yf  (end point, or close to it)
              &ppixd (<optional return> maze with path illustrated, or
                     if no path possible, the part of the maze
                     that was searched)
      Return: pta (shortest path), or null if either no path
              exists or on error

  Notes:
      (1) Because of the overhead in calling pixGetPixel() and
          pixSetPixel(), we have used raster line pointers and the
          GET_DATA* and SET_DATA* macros for many of the pix accesses.
      (2) Commentary:
            The goal is to find the shortest path between beginning and
          end points, without going through walls, and there are many
          ways to solve this problem.
            We use a queue to implement a breadth-first search.  Two auxiliary
          "image" data structures can be used: one to mark the visited
          pixels and one to give the direction to the parent for each
          visited pixels.  The first structure is used to avoid putting
          pixels on the queue more than once, and the second is used
          for retracing back to the origin, like the breadcrumbs in
          Hansel and Gretel.  Each pixel taken off the queue is destroyed
          after it is used to locate the allowed neighbors.  In fact,
          only one distance image is required, if you initialize it
          to some value that signifies "not yet visited."  (We use
          a binary image for marking visited pixels because it is clearer.)
          This method for a simple search of a binary maze is implemented in
          searchBinaryMaze().
            An alternative method would store the (manhattan) distance
          from the start point with each pixel on the queue.  The children
          of each pixel get a distance one larger than the parent.  These
          values can be stored in an auxiliary distance map image
          that is constructed simultaneously with the search.  Once the
          end point is reached, the distance map is used to backtrack
          along a minimum path.  There may be several equal length
          minimum paths, any one of which can be chosen this way.

=head2 pixSearchGrayMaze

PTA * pixSearchGrayMaze ( PIX *pixs, l_int32 xi, l_int32 yi, l_int32 xf, l_int32 yf, PIX **ppixd )

  pixSearchGrayMaze()

      Input:  pixs (1 bpp, maze)
              xi, yi  (beginning point; use same initial point
                       that was used to generate the maze)
              xf, yf  (end point, or close to it)
              &ppixd (<optional return> maze with path illustrated, or
                     if no path possible, the part of the maze
                     that was searched)
      Return: pta (shortest path), or null if either no path
              exists or on error

  Commentary:
      Consider first a slight generalization of the binary maze
      search problem.  Suppose that you can go through walls,
      but the cost is higher (say, an increment of 3 to go into
      a wall pixel rather than 1)?  You're still trying to find
      the shortest path.  One way to do this is with an ordered
      queue, and a simple way to visualize an ordered queue is as
      a set of stacks, each stack being marked with the distance
      of each pixel in the stack from the start.  We place the
      start pixel in stack 0, pop it, and process its 4 children.
      Each pixel is given a distance that is incremented from that
      of its parent (0 in this case), depending on if it is a wall
      pixel or not.  That value may be recorded on a distance map,
      according to the algorithm below.  For children of the first
      pixel, those not on a wall go in stack 1, and wall
      children go in stack 3.  Stack 0 being emptied, the process
      then continues with pixels being popped from stack 1.
      Here is the algorithm for each child pixel.  The pixel's
      distance value, were it to be placed on a stack, is compared
      with the value for it that is on the distance map.  There
      are three possible cases:
         (1) If the pixel has not yet been registered, it is pushed
             on its stack and the distance is written to the map.
         (2) If it has previously been registered with a higher distance,
             the distance on the map is relaxed to that of the
             current pixel, which is then placed on its stack.
         (3) If it has previously been registered with an equal
             or lower value, the pixel is discarded.
      The pixels are popped and processed successively from
      stack 1, and when stack 1 is empty, popping starts on stack 2.
      This continues until the destination pixel is popped off
      a stack.   The minimum path is then derived from the distance map,
      going back from the end point as before.  This is just Dijkstra's
      algorithm for a directed graph; here, the underlying graph
      (consisting of the pixels and four edges connecting each pixel
      to its 4-neighbor) is a special case of a directed graph, where
      each edge is bi-directional.  The implementation of this generalized
      maze search is left as an exercise to the reader.

      Let's generalize a bit further.  Suppose the "maze" is just
      a grayscale image -- think of it as an elevation map.  The cost
      of moving on this surface depends on the height, or the gradient,
      or whatever you want.  All that is required is that the cost
      is specified and non-negative on each link between adjacent
      pixels.  Now the problem becomes: find the least cost path
      moving on this surface between two specified end points.
      For example, if the cost across an edge between two pixels
      depends on the "gradient", you can use:
           cost = 1 + L_ABS(deltaV)
      where deltaV is the difference in value between two adjacent
      pixels.  If the costs are all integers, we can still use an array
      of stacks to avoid ordering the queue (e.g., by using a heap sort.)
      This is a neat problem, because you don't even have to build a
      maze -- you can can use it on any grayscale image!

      Rather than using an array of stacks, a more practical
      approach is to implement with a priority queue, which is
      a queue that is sorted so that the elements with the largest
      (or smallest) key values always come off first.  The
      priority queue is efficiently implemented as a heap, and
      this is how we do it.  Suppose you run the algorithm
      using a priority queue, doing the bookkeeping with an
      auxiliary image data structure that saves the distance of
      each pixel put on the queue as before, according to the method
      described above.  We implement it as a 2-way choice by
      initializing the distance array to a large value and putting
      a pixel on the queue if its distance is less than the value
      found on the array.  When you finally pop the end pixel from
      the queue, you're done, and you can trace the path backward,
      either always going downhill or using an auxiliary image to
      give you the direction to go at each step.  This is implemented
      here in searchGrayMaze().

      Do we really have to use a sorted queue?  Can we solve this
      generalized maze with an unsorted queue of pixels?  (Or even
      an unsorted stack, doing a depth-first search (DFS)?)
      Consider a different algorithm for this generalized maze, where
      we travel again breadth first, but this time use a single,
      unsorted queue.  An auxiliary image is used as before to
      store the distances and to determine if pixels get pushed
      on the stack or dropped.  As before, we must allow pixels
      to be revisited, with relaxation of the distance if a shorter
      path arrives later.  As a result, we will in general have
      multiple instances of the same pixel on the stack with different
      distances.  However, because the queue is not ordered, some of
      these pixels will be popped when another instance with a lower
      distance is still on the stack.  Here, we're just popping them
      in the order they go on, rather than setting up a priority
      based on minimum distance.  Thus, unlike the priority queue,
      when a pixel is popped we have to check the distance map to
      see if a pixel with a lower distance has been put on the queue,
      and, if so, we discard the pixel we just popped.  So the
      "while" loop looks like this:
        - pop a pixel from the queue
        - check its distance against the distance stored in the
          distance map; if larger, discard
        - otherwise, for each of its neighbors:
            - compute its distance from the start pixel
            - compare this distance with that on the distance map:
                - if the distance map value higher, relax the distance
                  and push the pixel on the queue
                - if the distance map value is lower, discard the pixel

      How does this loop terminate?  Before, with an ordered queue,
      it terminates when you pop the end pixel.  But with an unordered
      queue (or stack), the first time you hit the end pixel, the
      distance is not guaranteed to be correct, because the pixels
      along the shortest path may not have yet been visited and relaxed.
      Because the shortest path can theoretically go anywhere,
      we must keep going.  How do we know when to stop?   Dijkstra
      uses an ordered queue to systematically remove nodes from
      further consideration.  (Each time a pixel is popped, we're
      done with it; it's "finalized" in the Dijkstra sense because
      we know the shortest path to it.)  However, with an unordered
      queue, the brute force answer is: stop when the queue
      (or stack) is empty, because then every pixel in the image
      has been assigned its minimum "distance" from the start pixel.

      This is similar to the situation when you use a stack for the
      simpler uniform-step problem: with breadth-first search (BFS)
      the pixels on the queue are automatically ordered, so you are
      done when you locate the end pixel as a neighbor of a popped pixel;
      whereas depth-first search (DFS), using a stack, requires,
      in general, a search of every accessible pixel.  Further, if
      a pixel is revisited with a smaller distance, that distance is
      recorded and the pixel is put on the stack again.

      But surely, you ask, can't we stop sooner?  What if the
      start and end pixels are very close to each other?
      OK, suppose they are, and you have very high walls and a
      long snaking level path that is actually the minimum cost.
      That long path can wind back and forth across the entire
      maze many times before ending up at the end point, which
      could be just over a wall from the start.  With the unordered
      queue, you very quickly get a high distance for the end
      pixel, which will be relaxed to the minimum distance only
      after all the pixels of the path have been visited and placed
      on the queue, multiple times for many of them.  So that's the
      price for not ordering the queue!

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
