package Math::Geometry::HexGrid;

use 5.014;
use warnings;
use Carp qw(croak);
use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT_OK = qw(
    oddr_to_cube
    cube_to_oddr
    hex_distance
    hex_is_collinear
    hex_neighbors
    hex_collinear_ray
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

require XSLoader;
XSLoader::load('Math::Geometry::HexGrid', $VERSION);

# Load OO coordinate class (which in turn requires Math::Geometry::HexGrid)
use Math::Geometry::HexGrid::Hex;

sub hex {
    my ($class, $col, $row) = @_;
    return Math::Geometry::HexGrid::Hex->new($col, $row);
}

1;

=pod

=encoding utf8

=head1 NAME

Math::Geometry::HexGrid - Fast, XS-accelerated hexagonal grid mathematics

=head1 SYNOPSIS

    use Math::Geometry::HexGrid qw(:all);

    # 1. High-Performance Functional Interface (Pure C Speed)
    # Convert odd-r offset coordinates to 3D cube coordinates:
    my ($q, $r, $s) = oddr_to_cube(15, 12); # (9, 12, -21)
    my ($col, $row) = cube_to_oddr($q, $r, $s);

    # Calculate exact Manhattan hex distance:
    my $dist = hex_distance(0, 0, 15, 12);

    # Check if two coordinates lie along a common cardinal hex axis:
    if (hex_is_collinear($c1, $r1, $c2, $r2)) {
        my @ray = hex_collinear_ray($c1, $r1, $c2, $r2);
        for my $step (@ray) {
            say "Step: $step->[0], $step->[1]";
        }
    }

    # Fetch 6 immediate neighbors (respects odd-r row parity):
    my @neighbors = hex_neighbors(4, 4);

    # 2. Object-Oriented Interface (Ergonomic Value Objects)
    my $h1 = Math::Geometry::HexGrid->hex(4, 4);
    my $h2 = Math::Geometry::HexGrid->hex(10, 4);

    say $h1->col;              # 4
    say $h1->row;              # 4
    say $h1->distance_to($h2); # 6
    say "$h1";                 # Overloaded stringification: "4,4"

    if ($h1 == $h2) {
        # Overloaded equality in C
    }

    my @nbs = $h1->neighbors; # Returns Math::Geometry::HexGrid::Hex objects

=head1 DESCRIPTION

C<Math::Geometry::HexGrid> provides high-performance, exact hexagonal grid
mathematics implemented in ANSI C with Perl XS bindings.

Working with hexagonal grids in standard Cartesian C<($col, $row)> offset
coordinates is notoriously error-prone because movement vectors change depending
on row or column parity. By mapping offset coordinates to symmetric 3-axis
B<Cube Coordinates> C<($q, $r, s)> where C<$q + $r + $s == 0>, all hexagonal
operations (distance, direction, adjacency, and line-drawing) become simple,
branch-free linear algebra.

All mathematical operations use pure integer arithmetic, completely avoiding
floating-point roundoff errors and precision drift.

=head1 MATHEMATICAL FOUNDATIONS & ALGORITHMS

This module implements pointy-topped hexagonal grids with B<odd-r offset>
layout (where odd-numbered rows are shifted to the right by half a hex width).

=head2 1. Coordinate Systems

=over 4

=item * B<Odd-R Offset Coordinates> C<($col, $row)>:

Standard 2D array coordinates convenient for map storage and display.

=item * B<Cube Coordinates> C<($q, $r, $s)>:

A 3D coordinate system where each axis corresponds to one of the three
primary hexagonal diagonal directions, constrained to the diagonal plane:

    q + r + s = 0

=back

=head2 2. Conversion Formulas

Conversion between odd-r offset and cube coordinates is an exact, reversible integer bijection:

=head3 Offset to Cube

    q = col - floor((row - (row & 1)) / 2)
    r = row
    s = -q - r

Because C<row - (row & 1)> is always an even integer, dividing by 2 yields an
exact integer without fractional truncation.

=head3 Cube to Offset

    col = q + floor((r - (r & 1)) / 2)
    row = r

=head2 3. Hexagonal Distance

The shortest path distance between two hexes in a regular grid is defined by the
Manhattan metric in cube coordinates:

    distance = max(|q1 - q2|, |r1 - r2|, |s1 - s2|)

Equivalently:

    distance = (|q1 - q2| + |r1 - r2| + |s1 - s2|) / 2

=head2 4. Adjacency & Direction Offsets

Every hexagon has exactly 6 neighbors. In cube coordinates, neighbor directions
are unit permutations of C<(+1, -1, 0)>:

    Direction 0 (East):      (+1,  0, -1)
    Direction 1 (Northeast): (+1, -1,  0)  [or (+1, -1) in odd rows]
    Direction 2 (Northwest): ( 0, -1, +1)
    Direction 3 (West):      (-1,  0, +1)
    Direction 4 (Southwest): (-1, +1,  0)
    Direction 5 (Southeast): ( 0, +1, -1)

C<hex_neighbors> maps these offsets directly to odd-r coordinates taking row
parity into account.

=head2 5. Collinear Line-Drawing & Raycasting

Two hexes are B<collinear> if and only if they lie along a common straight line
parallel to one of the 3 cube axes:

    q1 == q2  OR  r1 == r2  OR  s1 == s2

C<hex_collinear_ray> traces intermediate hexes by interpolating along the shared
axis, rounding each step to integer coordinates.

=head1 FUNCTIONAL API

The following subroutines are available for export. Use the tag C<:all> to
import all of them:

    use Math::Geometry::HexGrid qw(:all);

=head2 oddr_to_cube($col, $row)

    my ($q, $r, $s) = oddr_to_cube($col, $row);

Converts 2D odd-r offset coordinates C<($col, $row)> to 3D cube coordinates
C<($q, $r, $s)>. Returns a 3-element list of integers.

=head2 cube_to_oddr($q, $r, $s)

    my ($col, $row) = cube_to_oddr($q, $r, $s);

Converts 3D cube coordinates C<($q, $r, $s)> back to 2D odd-r offset coordinates.
Returns a 2-element list of integers C<($col, $row)>.

=head2 hex_distance($col1, $row1, $col2, $row2)

    my $dist = hex_distance($col1, $row1, $col2, $row2);

Calculates the exact integer Manhattan hex distance between two hexes.

=head2 hex_is_collinear($col1, $row1, $col2, $row2)

    if (hex_is_collinear($c1, $r1, $c2, $r2)) { ... }

Returns a boolean indicating whether the two hex coordinates share one of the 6
cardinal hexagonal axes. Returns false if the coordinates are identical.

=head2 hex_neighbors($col, $row)

    my @nbs = hex_neighbors($col, $row);

Returns a 6-element list of array references C<([$c, $r], ...)> representing
the immediate neighboring coordinates in clockwise order starting from East (direction 0).

=head2 hex_collinear_ray($col1, $row1, $col2, $row2, [$max_length = 100])

    my @ray = hex_collinear_ray($col1, $row1, $col2, $row2, $max_len);

Traces a straight line from C<($col1, $row1)> toward C<($col2, $row2)>.
Returns an empty list if the two points are not collinear.
Otherwise, returns a list of array references C<([$c, $r], ...)> beginning with
the first step past the origin, up to C<$max_length> steps or reaching the destination.

=head1 OBJECT-ORIENTED API

For higher-level application logic, C<Math::Geometry::HexGrid> provides a
lightweight value object class C<Math::Geometry::HexGrid::Hex>.

All OO methods are implemented in native C/XS with zero Perl method-call
overhead.

=head2 Math::Geometry::HexGrid->hex($col, $row)

=head2 Math::Geometry::HexGrid::Hex->new($col, $row)

    my $hex = Math::Geometry::HexGrid->hex($col, $row);

Constructs and returns a new hex coordinate value object.

=head2 $hex->col

Returns the integer column coordinate.

=head2 $hex->row

Returns the integer row coordinate.

=head2 $hex->to_cube

    my ($q, $r, $s) = $hex->to_cube;

Returns the 3D cube coordinates C<($q, $r, $s)> as a list.

=head2 $hex->distance_to($other)

    my $d = $hex->distance_to($other_hex);

Returns the integer hex distance to another C<Math::Geometry::HexGrid::Hex> object.

=head2 $hex->is_collinear_with($other)

    if ($hex->is_collinear_with($other)) { ... }

Returns true if both hex objects are collinear.

=head2 $hex->neighbors

    my @neighbors = $hex->neighbors;

Returns a list of 6 new C<Math::Geometry::HexGrid::Hex> objects representing
the adjacent neighbors.

=head2 $hex->ray_to($other, [$max_length = 100])

    my @ray = $hex->ray_to($other, 5);

Returns a list of C<Math::Geometry::HexGrid::Hex> objects representing the
collinear ray toward C<$other>.

=head2 $hex->equals($other)

Returns true if both coordinates have identical column and row values.

=head2 Overloaded Operators

The C<Math::Geometry::HexGrid::Hex> class overloads the following operators:

=over 4

=item * B<Stringification> (C<"">): Formats as C<"col,row"> (e.g. C<"4,7">), making hex objects natural hash keys.

=item * B<Equality> (C<==>): Checks exact integer equality in native C.

=item * B<Inequality> (C<!=>): Inverted equality check.

=back

=head1 SEE ALSO

=over 4

=item * Red Blob Games Hexagonal Grids Guide: L<https://www.redblobgames.com/grids/hexagons/>

The canonical reference for hexagonal grid mathematics and algorithms.

=back

=head1 AUTHOR

Steffen Mueller E<lt>cpan@steffen-mueller.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 Steffen Mueller

This software is released under the MIT License. See the F<LICENSE> file included
with this distribution for full license details.

=cut

