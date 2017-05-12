package Grid::Transform;

use strict;
use warnings;

use XSLoader;

our $VERSION    = '0.09';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

XSLoader::load(__PACKAGE__, $XS_VERSION);

1;

__END__

=head1 NAME

Grid::Transform - fast grid transformations

=head1 SYNOPSIS

    use Grid::Transform;

    $g = Grid::Transform->new(['a'..'o'], rows=>5);
    $g->rotate_270->flip_vertical;
    print join(' ', $g->grid), "\n";

=head1 DESCRIPTION

The C<Grid::Transform> module provides fast methods to transform a grid of
arbitrary data types.

=head1 METHODS

=over

=item $g = Grid::Transform->B<new>(\@grid, rows=>num, columns=>num)

Creates a new C<Grid::Transform> object.  The first argument is a reference to
a 1-dimensional array representing a 2-dimensional "row major" (row by row)
grid. (A column major grid is simply the counter transpose of a row major
one.)  The grid may be composed of arbitrary data types.  The original array
is never modified- all transformations operate on a copy.

At least one dimension must be specified.  If the grid and dimensions do not
produce a rectangular grid extra empty elements ("") will be added to the
grid.

=item $g2 = $g->B<copy>

Returns a copy of the original C<Grid::Transform> object.

=back

These methods get or set the grid attributes:

=over

=item @grid = $g->B<grid>

=item $grid = $g->B<grid>

=item @grid = $g->B<grid>(\@grid)

In list context, returns an array representing the current grid.  In scalar
context, returns a reference to the array.  Accepts an array reference
representing a new grid.  The new grid will be resized if the dimensions of
the previous grid do not match.

=item $g->B<rows>

=item $g->B<rows>($num)

Returns or sets the current number of rows.

=item $g->B<columns>

=item $g->B<cols>

=item $g->B<columns>($num)

Returns or sets the current number of columns.

=back

All transform methods return the C<Grid::Transform> object, so transforms can
be chained.

=over

=item $g->B<rotate_90>

=item $g->B<rotate90>

Rotates the grid 90 degrees clock-wise.

    a b c d e f g h i j k l    a b c d      i e a
              |                e f g h  ->  j f b
    i e a j f b k g c l h d    i j k l      k g c
                                            l h d

=item $g->B<rotate_180>

=item $g->B<rotate180>

Rotates the grid 180 degrees clock-wise.

    a b c d e f g h i j k l    a b c d      l k j i
              |                e f g h  ->  h g f e
    l k j i h g f e d c b a    i j k l      d c b a

=item $g->B<rotate_270>

=item $g->B<rotate270>

Rotates the grid 270 degrees clock-wise.

    a b c d e f g h i j k l    a b c d      d h l
              |                e f g h  ->  c g k
    d h l c g k b f j a e i    i j k l      b f j
                                            a e i

=item $g->B<flip_horizontal>

=item $g->B<mirror_horizontal>

Flips the grid across the horizontal axis.

    a b c d e f g h i j k l    a b c d      i j k l
              |                e f g h  ->  e f g h
    i j k l e f g h a b c d    i j k l      a b c d

=item $g->B<flip_vertical>

=item $g->B<mirror_vertical>

Flips the grid across the vertical axis.

    a b c d e f g h i j k l    a b c d      d c b a
              |                e f g h  ->  h g f e
    d c b a h g f e l k j i    i j k l      l k j i

=item $g->B<transpose>

Flips the grid across the vertical axis and then rotates it 90 degress
clock-wise.

    a b c d e f g h i j k l    a b c d      l h d
              |                e f g h  ->  k g c
    l h d k g c j f b i e a    i j k l      j f b
                                            i e a

=item $g->B<counter_transpose>

=item $g->B<countertranspose>

Flips the grid across the horizontal axis and then rotates it 90 degrees
clock-wise.

    a b c d e f g h i j k l    a b c d      a e i
              |                e f g h  ->  b f j
    a e i b f j c g k d h l    i j k l      c g k
                                            d h l

=item $g->B<fold_right>

Folds the columns to the right.

    a b c d e f g h i j k l    a b c d      b c d a
              |                e f g h  ->  f g e h
    b c a d f g e h j k i l    i j k l      j k i l

=item $g->B<fold_left>

Folds the columns to the left.

    a b c d e f g h i j k l    a b c d      d a c b
              |                e f g h  ->  h e g f
    d a c b h e g f l i k j    i j k l      l i k j

=item $g->B<alternate_row_direction>

=item $g->B<alt_row_dir>

Follows a path from left to right on the first row, right to left on the
second, left to right on the third, etc.

    a b c d e f g h i j k l    a b c d      a b c d
              |                e f g h  ->  h g f e
    a b c d h g f e i j k l    i j k l      i j k l

=item $g->B<spiral>

Follows a spiral path towards the center, starting from the upper left to
right.

    a b c d e f g h i j k l    a b c d      a b c d
              |                e f g h  ->  h l k j
    a b c d h l k j i e f g    i j k l      i e f g

=back

=head1 NOTES

Some of the methods require temporary extra space for bookkeeping, so it's
possible that O(n^3) space will be required- the original array, the internal
copy, and the temporary space required by the transformation. Note, the copies
are shallow, so they will be smaller than the original array if it contains
complex data structures.

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Grid-Transform>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 TODO

=over

=item * Allow the empty element to be user-specified (e.g.
$Grid::Transform::EMPTY_ELEMENT or empty_element constructor arg).

=item * Accept / convert grid to LoLs.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Grid::Transform

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/grid-transform>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Grid-Transform>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Grid-Transform>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Grid-Transform>

=item * Search CPAN

L<http://search.cpan.org/dist/Grid-Transform>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2014 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
