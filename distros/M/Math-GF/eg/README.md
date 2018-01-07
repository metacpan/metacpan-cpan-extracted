# Examples

This directory contains some examples (starting from... 1 example, which
might remain alone for a long time or forever!).

## `pg2` - projective geometries of dimension 2

This example generates (finite) [projective geometries][pg] of dimension 2
and order provided on the command line (defaulting to 2, i.e. the [Fano
Plane][fp]). Dimension 2 projective geometries also go under the name of
[projective planes][pp].

[pg]: https://en.wikipedia.org/wiki/Projective_geometry
[fp]: https://en.wikipedia.org/wiki/Fano_plane
[pp]: http://mathworld.wolfram.com/ProjectivePlane.html

Example:

    $ perl pg2
    elements in field: 2
      0. (1, 3, 5)
      1. (0, 3, 4)
      2. (2, 3, 6)
      3. (0, 1, 2)
      4. (1, 4, 6)
      5. (0, 5, 6)
      6. (2, 4, 5)
    errors in check: 0

The *elements in field* corresponds to the order of the projective
geometry. As anticipated, the defualt value is `2`.

Then, the list of *lines* is provided, as collections of *order*+1
*points* each. So, for example, *line* `0` is comprised of *points* `1`,
`3` and `5`.

For duality, you can also consider each of them as *points*, listing the
*lines* it belongs to. As a matter of fact, the arrangement is such that
this property always holds, i.e. if *point* `x` belongs to line `y`, then
point `y` belongs to line `x`.

The *errors in check* is a verification that the generated list of
*points*/*lines* actually is a projective geometry, i.e. that all lines
have the same *order*+1 *points* and that each *point* belongs exactly to
*order*+1 lines.

As a curiosity, the game [Dobble][dobble] (known in some countries as
*Spot It*) is a game based on *PG(2, 7)*:

    $ perl pg2 7
    elements in field: 7
      0. (1, 8, 15, 22, 29, 36, 43, 50)
      1. (0, 8, 9, 10, 11, 12, 13, 14)
      2. (7, 8, 21, 27, 33, 39, 45, 51)
     ...
     54. (3, 13, 15, 24, 33, 42, 44, 53)
     55. (4, 12, 15, 25, 35, 38, 48, 51)
     56. (7, 9, 15, 28, 34, 40, 46, 52)
    errors in check: 0

where:

- each *point* is associated to a picture
- each *line* is associated to a card
- only 55 cards out of the 57 possible ones are included in the game
- each picture is included in at most 8 cards (because 2 cards were left
  out)
- each card contains exactly 8 pictures
- any two cards share exactly 1 picture (corresponding to the notion that
  two *lines* intersect in exactly one *point*)

You can consider the dual of course... this is left as an exercise!

[dobble]: https://boardgamegeek.com/boardgame/63268/spot-it
