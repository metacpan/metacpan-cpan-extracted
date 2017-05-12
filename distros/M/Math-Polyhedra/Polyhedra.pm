# Math::Polyhedra - locate vertices, edges, and faces of common polyhedra

package Math::Polyhedra;

#----------------------------------------------------------------------------
#
# Copyright (C) 1998-2003 Ed Halley
# http://www.halley.cc/ed/
#
# Data Copyright (C) Robert W. Gray, Used with Permission.
# http://www.rwgrayprojects.com/Lynn/Coordinates/coord01.html
#
#----------------------------------------------------------------------------

BEGIN
{
    use vars qw($VERSION @ISA);
    $VERSION = 0.7;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(phi coordinates polyhedron polyhedra
		    vertices edges faces tris);
}

=head1 NAME

Math::Polyhedra - locate vertices, edges, and faces of common polyhedra

=head1 SYNOPSIS

    use Math::Polyhedra qw(polyhedron vertices edges faces tris);

    my $hedron = polyhedron('rhombic dodecahedron');
    my $vertices = vertices($hedron);
    my $edges = edges($hedron);
    my $faces = faces($hedron);
    my $tris = tris($hedron);

=head1 ABSTRACT

This module calculates and structures the coordinates of a library of
commonly useful regular polyhedra.  These geometrical figures can be
selected by name, or by the number of sides.

The heart of the data is a set of 62 coordinates, from which each of
these common polyhedra can be defined.  Each of the vertices can be
defined as a set of points around the origin measured with various
multiples and powers of I<phi>, also known as the S<Golden Ratio>, which
is approximately 1.618.

This package was inspired by the nice reference page provided by Robert
W. Gray: L<http://www.rwgrayprojects.com/Lynn/Coordinates/coord01.html>.
Other sites also explore the S<Golden Ratio> and these polyhedra.

=cut

#----------------------------------------------------------------------------

=head1 FUNCTIONS

=head2 phi()

The C<Golden Ratio> is usually referred by the greek letter I<phi>.  This
can be defined by the following expression:

                   ____
             1 + \/ 5
    phi  =  ------------  =  (1 + sqrt(5)) / 2
                 2

This function simply returns that numeric value, which comes close to
1.61803398874989.  This number, like I<pi>, has many interesting
properties and appears both in nature and invention.

=cut

my $F = undef;
sub phi
{
    return $F if $F;
    $F = (1 + sqrt(5)) / 2;
    return $F;
}

=head2 coordinates()

Returns a list reference containing the master set of coordinate vectors.
All or most of these coordinates are calculated from the value of I<phi>.

Without arguments, the points are only allocated and calculated on the
first call to this function.  Subsequent calls without arguments will
return the same list reference each time.  Each vector is a simple
unblessed list reference, like C<[ $x, $y, $z ]>.

With any argument, this function will calculate a new list afresh.  This
takes slightly more memory and time, but some algorithms may want to
change the given coordinates, which would otherwise spoil future calls
that would return the modified list.

If the first argument given is a code reference, then that code is called
once per vector, with the vector as an argument.  The result of that code
then B<replaces> the original vector in the master set used by the other
functions.  This can be used to bless or convert the vectors with other
vector math packages:

    use Math::Polyhedra;
    use Math::VectorReal;
    my $coords = coordinates( sub { vector(@{$_[0]}) } );

After the above code, all vectors returned by any function in this module
are then referring to blessed C<Math::VectorReal> object instances.  Just
about any vector library would work similarly.  The choice of which
vector module to use is arbitrary, since it's the given code reference
which drives the vector conversion.

=cut

my $Coords = undef;
sub coordinates
{
    # We pass through any blessed reference to our own package; no-op.
    # This allows callers to pass specific coord sets through the other
    # functions in this module; an undocumented feature which may change.
    # Any passed-through set is not memo-ized.
    return $_[0] if UNIVERSAL::isa($_[0], __PACKAGE__);

    # If any argument is given, it revokes previous memo-ized results and
    # we need to make a fresh set of vectors instead.  We'll check what
    # the argument type is, if any, later.  If no argument, we may use
    # any already memo-ized prepared set.
    $Coords = undef if @_;
    return $Coords if $Coords;

    # The Golden Ratio, often written as phi or F.
    # The value of F is approximately 1.61803398874989.
    # All of the polyhedra coordinates in X, Y and Z are some relation to F.
    my $F = phi();
    $Coords =
	#       X         Y         Z
	[ undef,
	  [     0,        0,     2*$F**2 ],
	  [    $F**2,     0,       $F**3 ],
	  [    $F,       $F**2,    $F**3 ],
	  [     0,       $F,       $F**3 ],
	  [   -$F,       $F**2,    $F**3 ],
	  [   -$F**2,     0,       $F**3 ],
	  [   -$F,      -$F**2,    $F**3 ],
	  [     0,      -$F,       $F**3 ],
	  [    $F,      -$F**2,    $F**3 ],
	  [    $F**3,    $F,       $F**2 ],
	  [    $F**2,    $F**2,    $F**2 ],
	  [     0,       $F**3,    $F**2 ],
	  [   -$F**2,    $F**2,    $F**2 ],
	  [   -$F**3,    $F,       $F**2 ],
	  [   -$F**3,   -$F,       $F**2 ],
	  [   -$F**2,   -$F**2,    $F**2 ],
	  [     0,      -$F**3,    $F**2 ],
	  [    $F**2,   -$F**2,    $F**2 ],
	  [    $F**3,   -$F,       $F**2 ],
	  [    $F**3,     0,       $F    ],
	  [    $F**2,    $F**3,    $F    ],
	  [   -$F**2,    $F**3,    $F    ],
	  [   -$F**3,     0,       $F    ],
	  [   -$F**2,   -$F**3,    $F    ],
	  [    $F**2,   -$F**3,    $F    ],
	  [  2*$F**2,     0,        0    ],
	  [    $F**3,    $F**2,     0    ],
	  [    $F,       $F**3,     0    ],
	  [     0,     2*$F**2,     0    ],
	  [   -$F,       $F**3,     0    ],
	  [   -$F**3,    $F**2,     0    ],
	  [ -2*$F**2,     0,        0    ],
	  [   -$F**3,   -$F**2,     0    ],
	  [   -$F,      -$F**3,     0    ],
	  [     0,    -2*$F**2,     0    ],
	  [    $F,      -$F**3,     0    ],
	  [    $F**3,   -$F**2,     0    ],
	  [    $F**3,     0,      -$F    ],
	  [    $F**2,    $F**3,   -$F    ],
	  [   -$F**2,    $F**3,   -$F    ],
	  [   -$F**3,     0,      -$F    ],
	  [   -$F**2,   -$F**3,   -$F    ],
	  [    $F**2,   -$F**3,   -$F    ],
	  [    $F**3,    $F,      -$F**2 ],
	  [    $F**2,    $F**2,   -$F**2 ],
	  [     0,       $F**3,   -$F**2 ],
	  [   -$F**2,    $F**2,   -$F**2 ],
	  [   -$F**3,    $F,      -$F**2 ],
	  [   -$F**3,   -$F,      -$F**2 ],
	  [   -$F**2,   -$F**2,   -$F**2 ],
	  [     0,      -$F**3,   -$F**2 ],
	  [    $F**2,   -$F**2,   -$F**2 ],
	  [    $F**3,   -$F,      -$F**2 ],
	  [    $F**2,     0,      -$F**3 ],
	  [    $F,       $F**2,   -$F**3 ],
	  [     0,       $F,      -$F**3 ],
	  [   -$F,       $F**2,   -$F**3 ],
	  [   -$F**2,     0,      -$F**3 ],
	  [   -$F,      -$F**2,   -$F**3 ],
	  [     0,      -$F,      -$F**3 ],
	  [    $F,      -$F**2,   -$F**3 ],
	  [     0,        0,    -2*$F**2 ] ];

    # Convert the vectors if the application supplies a method.
    if ($_[0] and "CODE" eq ref($_[0]))
    {
	eval
	{
	    my $convert = shift;
	    foreach (@$Coords)
	    {
		next if not $_;
		$_ = &$convert($_);
	    }
	};
	print "died: $@" if $@;
    }

    # This coordinate set is blessed so we can identify it in later calls.
    bless($Coords, __PACKAGE__);
    return $Coords;
}

#----------------------------------------------------------------------------

# Ten different regular four-sided tetrahedra can be found.
#
my $Tetrahedra =
    [ {   Verts => [4, 34, 38, 47],
	  Edges => [[4, 34], [4, 38], [4, 47],
		    [34, 38], [34, 47], [38, 47]],
	  Faces => [[4, 47, 34], [4, 34, 38], 
		    [4, 38, 47], [34, 47, 38]] },
      {   Verts => [18, 23, 28, 60],
	  Edges => [[18, 23], [18, 28], [18, 60],
		    [23, 28], [23, 60], [28, 60]],
	  Faces => [[18, 28, 23], [18, 23, 60],
		    [18, 60, 28], [23, 28, 60]] },
      {   Verts => [4, 36, 41, 45],
	  Edges => [[4, 36], [4, 41], [4, 45], 
		    [36, 41], [36, 45], [41, 45]],
	  Faces => [[4, 41, 36], [4, 36, 45],
		    [4, 45, 41], [36, 41, 45]] },
      {   Verts => [16, 20, 30, 60],
	  Edges => [[16, 20], [16, 30], [16, 60], 
		    [20, 30], [20, 60], [30, 60]],
	  Faces => [[16, 20, 30], [16, 60, 20],
		    [16, 30, 60], [20, 60, 30]] },
      {   Verts => [8, 28, 41, 52],
	  Edges => [[8, 28], [8, 41], [8, 52], 
		    [28, 41], [28, 52], [41, 52]],
	  Faces => [[8, 28, 41], [8, 52, 28], 
		    [8, 41, 52], [28, 52, 41]] },
      {   Verts => [13, 20, 34, 56],
	  Edges => [[13, 20], [13, 34], [13, 56], 
		    [20, 34], [20, 56], [34, 56]],
	  Faces => [[13, 34, 20], [13, 20, 56],
		    [13, 56, 34], [20, 34, 56]] },
      {   Verts => [8, 30, 38, 50],
	  Edges => [[8, 30], [8, 38], [8, 50], 
		    [30, 38], [30, 50], [38, 50]],
	  Faces => [[8, 38, 30], [8, 30, 50], 
		    [8, 50, 38], [30, 38, 50]] },
      {   Verts => [11, 23, 36, 56],
	  Edges => [[11, 23], [11, 36], [11, 56], 
		    [23, 36], [23, 56], [36, 56]],
	  Faces => [[11, 23, 36], [11, 56, 23],
		    [11, 36, 56], [23, 56, 36]] },
      {   Verts => [11, 16, 47, 52],
	  Edges => [[11, 16], [11, 47], [11, 52], 
		    [16, 47], [16, 52], [47, 52]],
	  Faces => [[47, 16, 11], [52, 47, 11],
		    [16, 52, 11], [47, 52, 16]] },
      {   Verts => [13, 18, 45, 50],
	  Edges => [[13, 18], [13, 45], [13, 50], 
		    [18, 45], [18, 50], [45, 50]],
	  Faces => [[13, 18, 45], [18, 13, 50],
		    [13, 45, 50], [18, 50, 45]] } ];

#----------------------------------------------------------------------------

# Five different regular six-sided sexahedra (cubes) can be found.
# Each square face is a pair of triangles.
#
my $Sexahedra =
    [ {   Verts => [4, 18, 23, 28, 34, 38, 47, 60],
	  Edges => [ [4,  18], [18, 38], [38, 28],
		     [28, 4],  [4,  23], [18, 34],
		     [28, 47], [38, 60], [23, 34],
		     [34, 60], [60, 47], [47, 23] ],
	  Faces => [ [[4,  18, 38], [38, 28, 4]],
		     [[4,  23, 18], [18, 23, 34]],
		     [[4,  28, 47], [4,  47, 23]],
		     [[28, 38, 60], [28, 60, 47]],
		     [[23, 47, 34], [47, 60, 34]],
		     [[38, 18, 60], [18, 34, 60]] ] },
      {   Verts => [4, 16, 20, 30, 36, 41, 45, 60],
	  Edges => [ [4,  16], [16, 36], [36, 20],
		     [20, 4],  [4,  30], [16, 41],
		     [20, 45], [36, 60], [30, 41],
		     [41, 60], [60, 45], [45, 30] ],
	  Faces => [ [[4,  16, 20], [16, 36, 20]],
		     [[4,  20, 45], [4,  45, 30]],
		     [[4,  30, 41], [4,  41, 16]],
		     [[45, 41, 30], [45, 60, 41]],
		     [[20, 36, 60], [20, 60, 45]],
		     [[36, 16, 41], [36, 41, 60]] ] },
      {   Verts => [8, 13, 20, 28, 34, 41, 52, 56],
	  Edges => [ [8,  13], [13, 28], [28, 20],
		     [20, 8],  [8,  34], [13, 41],
		     [28, 56], [20, 52], [34, 41],
		     [41, 56], [56, 52], [52, 34] ],
	  Faces => [ [[8,  20, 13], [13, 20, 28]],
		     [[8,  52, 20], [8,  34, 52]],
		     [[8,  41, 34], [8,  13, 41]],
		     [[20, 56, 28], [20, 52, 56]],
		     [[52, 41, 56], [52, 34, 41]],
		     [[28, 41, 13], [28, 56, 41]] ] },
      {   Verts => [8, 11, 23, 30, 36, 38, 50, 56],
	  Edges => [ [8,  11], [11, 30], [30, 23],
		     [23, 8],  [8,  36], [11, 38],
		     [23, 50], [30, 56], [36, 38],
		     [38, 56], [56, 50], [50, 36] ],
	  Faces => [ [[8,  11, 23], [11, 30, 23]],
		     [[8,  23, 50], [8,  50, 36]],
		     [[8,  36, 38], [8,  38, 11]],
		     [[23, 30, 56], [23, 56, 50]],
		     [[50, 56, 38], [50, 38, 36]],
		     [[30, 11, 56], [11, 38, 56]] ] },
      {   Verts => [11, 13, 16, 18, 45, 47, 50, 52],
	  Edges => [ [11, 13], [13, 16], [16, 18],
		     [18, 11], [11, 45], [13, 47],
		     [16, 50], [18, 52], [45, 47],
		     [47, 50], [50, 52], [52, 45] ],
	  Faces => [ [[11, 13, 16], [11, 16, 18]],
		     [[11, 45, 47], [11, 47, 13]],
		     [[13, 47, 50], [13, 50, 16]],
		     [[16, 50, 52], [16, 52, 18]],
		     [[18, 52, 45], [18, 45, 11]],
		     [[45, 52, 50], [45, 50, 47]] ] } ];

#----------------------------------------------------------------------------

# Five different regular eight-sided octahedra can be found.
#
my $Octahedra =
    [ {   Verts => [7, 10, 22, 43, 49, 55],
	  Edges => [ [7,  10], [7,  22], [7,  43],
		     [7,  49], [10, 22], [10, 43],
		     [22, 49], [43, 49], [10, 55],
		     [22, 55], [43, 55], [49, 55] ],
	  Faces => [ [7,  43, 10], [7,  10, 22],
		     [7,  49, 43], [7,  22, 49],
		     [55, 10, 43], [55, 22, 10],
		     [55, 43, 49], [55, 49, 22] ] },
      {   Verts => [9, 14, 21, 42, 53, 57],
	  Edges => [ [9,  14], [9,  21], [9,  42],
		     [9,  53], [14, 21], [14, 42],
		     [21, 53], [42, 53], [14, 57],
		     [21, 57], [42, 57], [53, 57] ],
	  Faces => [ [9,  21, 14], [9,  53, 21],
		     [9,  14, 42], [9,  42, 53],
		     [57, 14, 21], [57, 21, 53],
		     [57, 42, 14], [57, 53, 42] ] },
      {   Verts => [3, 15, 25, 40, 44, 59],
	  Edges => [ [3,  15], [3,  25], [3,  40],
		     [3,  44], [15, 25], [15, 40],
		     [40, 44], [25, 44], [25, 59],
		     [15, 59], [40, 59], [44, 59] ],
	  Faces => [ [3,  15, 25], [3,  25, 44],
		     [3,  40, 15], [3,  44, 40],
		     [59, 25, 15], [59, 15, 40],
		     [59, 40, 44], [59, 44, 25] ] },
      {   Verts => [5, 19, 24, 39, 48, 61],
	  Edges => [ [5,  19], [5,  24], [5,  39],
		     [5,  48], [19, 24], [19, 39],
		     [24, 48], [39, 48], [19, 61], 
		     [24, 61], [39, 61], [48, 61] ],
	  Faces => [ [5,  19, 39], [5,  24, 19],
		     [5,  39, 48], [5,  48, 24],
		     [61, 39, 19], [61, 19, 24],
		     [61, 48, 39], [61, 24, 48] ] },
      {   Verts => [1, 26, 29, 32, 35, 62],
	  Edges => [ [1,  26], [1,  29], [1,  32],
		     [1,  35], [26, 29], [29, 32],
		     [32, 35], [35, 26], [62, 26],
		     [62, 29], [62, 32], [62, 35] ],
	  Faces => [ [1,  26, 29], [1,  29, 32],
		     [1,  32, 35], [1,  35, 26],
		     [62, 29, 26], [62, 32, 29],
		     [62, 35, 32], [62, 26, 35] ] } ];

#----------------------------------------------------------------------------

# Five different rhombic twelve-sided dodecahedra can be found.
# Each rhomboid face is a pair of triangles.
#
my $RhombicDodecahedra =
    [ {   Verts => [4, 7, 10, 18, 22, 23, 28, 34, 38, 43, 47, 49, 55, 60],
	  Edges => [ [7,  4],  [7,  18], [7,  23],
		     [7,  34], [10, 4],  [10, 18],
		     [10, 28], [10, 38], [22, 4],
		     [22, 23], [22, 28], [22, 47],
		     [43, 18], [43, 34], [43, 38],
		     [43, 60], [49, 23], [49, 34],
		     [49, 47], [49, 60], [55, 28],
		     [55, 38], [55, 47], [55, 60] ],
	  Faces => [ [[4,  7,  18], [10, 4,  18]],
		     [[7,  34, 18], [43, 18, 34]],
		     [[7,  23, 34], [49, 34, 23]],
		     [[7,  4,  23], [4, 22,  23]],
		     [[22, 4,  28], [4, 10,  28]],
		     [[10, 18, 43], [38, 10, 43]],
		     [[34, 49, 43], [49, 60, 43]],
		     [[23, 22, 49], [47, 49, 22]],
		     [[55, 38, 60], [38, 43, 60]],
		     [[55, 60, 47], [49, 47, 60]],
		     [[55, 47, 28], [22, 28, 47]],
		     [[55, 28, 38], [28, 10, 38]] ] },
      {   Verts => [4, 9, 14, 16, 20, 21, 30, 36, 41, 42, 45, 53, 57, 60],
	  Edges => [ [9,  4],  [9,  16], [9,  20],
		     [9,  36], [14, 4],  [14, 16],
		     [14, 30], [14, 41], [21, 4], 
		     [21, 20], [21, 30], [21, 45],
		     [42, 16], [42, 36], [42, 41],
		     [42, 60], [53, 20], [53, 36],
		     [53, 45], [53, 60], [57, 30], 
		     [57, 41], [57, 45], [57, 60] ],
	  Faces => [ [[9,  4,  16], [4, 14,  16]],
		     [[9,  16, 36], [16, 42, 36]],
		     [[9,  36, 20], [53, 20, 36]],
		     [[9,  20, 4],  [21, 4, 20]],
		     [[14, 4,  30], [21, 30,  4]],
		     [[16, 14, 42], [41, 42, 14]],
		     [[36, 42, 53], [60, 53, 42]],
		     [[20, 53, 21], [45, 21, 53]],
		     [[42, 41, 60], [57, 60, 41]],
		     [[53, 60, 45], [57, 45, 60]],
		     [[21, 45, 30], [57, 30, 45]],
		     [[14, 30, 41], [57, 41, 30]] ] },
      {   Verts => [3, 8, 13, 15, 20, 25, 28, 34, 40, 41, 44, 52, 56, 59],
	  Edges => [ [3,  8],  [3,  13], [3,  20],
		     [3,  28], [15, 8],  [15, 13],
		     [15, 34], [15, 41], [25, 8], 
		     [25, 20], [25, 34], [25, 52],
		     [40, 13], [40, 28], [40, 41],
		     [40, 56], [44, 20], [44, 28],
		     [44, 52], [44, 56], [59, 34],
		     [59, 41], [59, 52], [59, 56] ],
	  Faces => [ [[3,  13,  8], [15, 8,  13]],
		     [[3,  28, 13], [40, 13, 28]],
		     [[3,  20, 28], [44, 28, 20]],
		     [[3,  8, 20],  [25, 20, 8]],
		     [[8,  15, 25], [34, 25, 15]],
		     [[13, 40, 15], [41, 15, 40]],
		     [[28, 44, 40], [56, 40, 44]],
		     [[20, 25, 44], [52, 44, 25]],
		     [[15, 41, 34], [59, 34, 41]],
		     [[40, 56, 41], [59, 41, 56]],
		     [[44, 52, 56], [59, 56, 52]],
		     [[25, 34, 52], [59, 52, 34]] ] },
      {   Verts => [5, 8, 11, 19, 23, 24, 30, 36, 38, 39, 48, 50, 56, 61],
	  Edges => [ [5,  8],  [5,  11], [5,  23],
		     [5,  30], [19, 8],  [19, 11],
		     [19, 36], [19, 38], [24, 8], 
		     [24, 23], [24, 36], [24, 50],
		     [39, 11], [39, 30], [39, 38],
		     [39, 56], [48, 23], [48, 30],
		     [48, 50], [48, 56], [61, 36],
		     [61, 38], [61, 50], [61, 56] ],
	  Faces => [ [[5,  8,  11], [8, 19,  11]],
		     [[5,  11, 30], [11, 39, 30]],
		     [[5,  30, 23], [30, 48, 23]],
		     [[5,  23, 8],  [23, 24, 8]],
		     [[8,  24, 19], [36, 19, 24]],
		     [[11, 19, 39], [19, 38, 39]],
		     [[30, 39, 48], [39, 56, 48]],
		     [[23, 48, 24], [48, 50, 24]],
		     [[19, 36, 38], [61, 38, 36]],
		     [[39, 38, 56], [61, 56, 38]],
		     [[48, 56, 50], [61, 50, 56]],
		     [[24, 50, 36], [61, 36, 50]] ] },
      {   Verts => [1, 11, 13, 16, 18, 26, 29, 32, 35, 45, 47, 50, 52, 62],
	  Edges => [ [1,  11], [1,  13], [1,  16], 
		     [1,  18], [26, 18], [26, 11],
		     [26, 45], [26, 52], [29, 11],
		     [29, 13], [29, 47], [29, 45],
		     [32, 13], [32, 16], [32, 50],
		     [32, 47], [35, 16], [35, 18],
		     [35, 52], [35, 50], [62, 45],
		     [62, 47], [62, 50], [62, 52] ],
	  Faces => [ [[1,  11, 29], [29, 13, 1]],
		     [[1,  13, 32], [32, 16, 1]],
		     [[1,  16, 35], [35, 18, 1]],
		     [[1,  18, 26], [26, 11, 1]],
		     [[26, 45, 29], [29, 11, 26]],
		     [[29, 47, 32], [32, 13, 29]],
		     [[32, 50, 35], [35, 16, 32]],
		     [[35, 52, 26], [26, 18, 35]],
		     [[62, 45, 26], [26, 52, 62]],
		     [[62, 47, 29], [29, 45, 62]],
		     [[62, 50, 32], [32, 47, 62]],
		     [[62, 52, 35], [35, 50, 62]] ] } ];

#----------------------------------------------------------------------------

# One regular twelve-sided dodecahedron can be found.
# Each regular pentagonal face is a triplet of triangles.
#
my $Dodecahedron =
    [ {   Verts => [ 4,  8,  11, 13, 16, 18, 20, 23, 28, 30,
		     34, 36, 38, 41, 45, 47, 50, 52, 56, 60 ],
	  Edges => [ [4, 8], [4,  11], [4,  13],
		     [8,  16], [8,  18], [11, 20],
		     [11, 28], [13, 30], [13, 23],
		     [16, 23], [16, 34], [18, 36],
		     [18, 20], [20, 38], [23, 41],
		     [28, 30], [28, 45], [30, 47],
		     [34, 50], [34, 36], [36, 52],
		     [38, 45], [38, 52], [41, 47],
		     [41, 50], [45, 56], [47, 56],
		     [50, 60], [52, 60], [56, 60] ],
	  Faces => [ [[4,  8,  11], [11, 8,  18], [11, 18, 20]],
		     [[4,  13, 23], [4,  23, 8],  [8,  23, 16]],
		     [[4,  11, 28], [4,  28, 30], [4,  30, 13]],
		     [[8,  16, 34], [8,  34, 18], [18, 34, 36]],
		     [[11, 20, 28], [20, 45, 28], [20, 38, 45]],
		     [[13, 30, 23], [23, 30, 41], [41, 30, 47]],
		     [[16, 23, 34], [34, 23, 50], [50, 23, 41]],
		     [[18, 36, 52], [18, 52, 38], [18, 38, 20]],
		     [[28, 45, 56], [28, 56, 47], [28, 47, 30]],
		     [[34, 50, 60], [34, 60, 36], [36, 60, 52]],
		     [[38, 52, 60], [38, 60, 56], [38, 56, 45]],
		     [[41, 47, 56], [41, 56, 60], [41, 60, 50]] ] } ];

#----------------------------------------------------------------------------

# One regular twenty-sided icosahedron can be found.
#
my $Icosahedron =
    [ {   Verts => [2, 6, 12, 17, 27, 31, 33, 37, 46, 51, 54, 58],
	  Edges => [ [2,  6],  [2,  12], [2,  17],
		     [2,  37], [2,  27], [6,  12],
		     [6,  17], [6,  31], [6,  33],
		     [12, 27], [12, 46], [12, 31],
		     [17, 33], [17, 51], [17, 37],
		     [27, 37], [27, 54], [27, 46],
		     [31, 46], [31, 58], [31, 33],
		     [33, 58], [33, 51], [37, 51],
		     [37, 54], [46, 54], [46, 58],
		     [51, 54], [51, 58], [54, 58] ],
	  Faces => [ [2,  6,  17], [2,  12, 6], [2,  17, 37],
		     [2,  37, 27], [2,  27, 12], [37, 54, 27],
		     [27, 54, 46], [27, 46, 12], [12, 46, 31],
		     [12, 31, 6], [6,  31, 33], [6,  33, 17],
		     [17, 33, 51], [17, 51, 37], [37, 51, 54],
		     [58, 54, 51], [58, 46, 54], [58, 31, 46],
		     [58, 33, 31], [58, 51, 33] ] } ];

#----------------------------------------------------------------------------

# One rhombic thirty-sided triacontahedron can be found.
# Each rhomboid face is a pair of triangles.
#
my $RhombicTriacontahedron =
    [ {   Verts => [ 2,  4,  6,  8,  11, 12, 13, 16,
		     17, 18, 20, 23, 27, 28, 30, 31,
		     33, 34, 36, 37, 38, 41, 45, 46,
		     47, 50, 51, 52, 54, 56, 58, 60 ],
	  Edges => [ [2,  4],  [4,  6],  [6,  8], 
		     [8,  2],  [2,  11], [11, 12],
		     [4,  12], [12, 13], [13, 6], 
		     [6,  23], [6,  16], [16, 17],
		     [17, 8],  [17, 18], [2,  18],
		     [2,  20], [20, 27], [27, 28],
		     [12, 28], [12, 30], [13, 31],
		     [23, 31], [23, 33], [33, 16],
		     [18, 37], [37, 20], [11, 27],
		     [54, 56], [56, 58], [58, 60],
		     [60, 54], [54, 45], [45, 46],
		     [46, 56], [58, 47], [58, 41],
		     [58, 50], [60, 51], [52, 54],
		     [54, 38], [38, 27], [27, 45],
		     [46, 47], [47, 31], [31, 41],
		     [41, 33], [33, 50], [50, 51],
		     [51, 52], [52, 37], [37, 38],
		     [28, 46], [30, 46], [30, 31],
		     [17, 36], [36, 51], [51, 34],
		     [34, 17], [36, 37], [33, 34] ],
	  Faces => [ [[2,  4,  6],  [6,  8,  2]],
		     [[2,  11, 4],  [4,  11, 12]],
		     [[4,  12, 13], [4,  13, 6]],
		     [[6,  16, 8],  [8,  16, 17]],
		     [[8,  17, 18], [8,  18, 2]],
		     [[2,  18, 37], [2,  37, 20]],
		     [[2,  20, 27], [2,  27, 11]],
		     [[11, 27, 28], [11, 28, 12]],
		     [[6,  13, 31], [6,  31, 23]],
		     [[6,  23, 33], [6,  33, 16]],
		     [[54, 60, 58], [58, 56, 54]],
		     [[54, 56, 45], [45, 56, 46]],
		     [[56, 58, 47], [47, 46, 56]],
		     [[47, 58, 41], [41, 31, 47]],
		     [[58, 50, 33], [33, 41, 58]],
		     [[58, 60, 51], [51, 50, 58]],
		     [[60, 54, 52], [52, 51, 60]],
		     [[54, 38, 37], [37, 52, 54]],
		     [[45, 27, 38], [38, 54, 45]],
		     [[20, 37, 38], [38, 27, 20]],
		     [[23, 31, 41], [41, 33, 23]],
		     [[12, 28, 46], [46, 30, 12]],
		     [[12, 30, 31], [31, 13, 12]],
		     [[31, 30, 46], [46, 47, 31]],
		     [[28, 27, 45], [45, 46, 28]],
		     [[17, 34, 51], [51, 36, 17]],
		     [[18, 17, 36], [36, 37, 18]],
		     [[37, 36, 51], [51, 52, 37]],
		     [[17, 16, 33], [33, 34, 17]],
		     [[34, 33, 50], [50, 51, 34]] ] } ];

# All of the points form a 120-sided figure.
# What would that be called?  I'm guessing it's a hexicosahedron (6*20).
# Each rhomboid face is a pair of triangles.
#
my $Hexicosahedron =
    [ {   Verts => [ 1,  2,  3,  4,  5,  6,  7,  8,  9, 
		     10, 11, 12, 13, 14, 15, 16, 17, 18,
		     19, 20, 21, 22, 23, 24, 25, 26, 27,
		     28, 29, 30, 31, 32, 33, 34, 35, 36,
		     37, 38, 39, 40, 41, 42, 43, 44, 45,
		     46, 47, 48, 49, 50, 51, 52, 53, 54,
		     55, 56, 57, 58, 59, 60, 61, 62 ],
	  Edges => [ [1,  2],  [1,  4],  [1,  6], 
		     [1,  8],  [2,  3],  [2,  4],
		     [2,  8],  [2,  9],  [2,  10], 
		     [2,  11], [2,  18], [2,  19],
		     [2,  20], [3,  4],  [3,  11],
		     [3,  12], [4,  5],  [4,  6],
		     [4,  12], [5,  6],  [5,  12], 
		     [5,  13], [6,  7],  [6,  8],
		     [6,  13], [6,  14], [6,  15],
		     [6,  16], [6,  23], [7,  8],
		     [7,  16], [7,  17], [8,  9], 
		     [8,  17], [9,  17], [9,  18],
		     [10, 11], [10, 20], [10, 27],
		     [11, 12], [11, 21], [11, 27],
		     [12, 13], [12, 21], [12, 28],
		     [12, 29], [12, 22], [12, 30],
		     [13, 14], [13, 22], [13, 31],
		     [14, 23], [14, 31], [15, 16],
		     [15, 23], [15, 33], [16, 17],
		     [16, 24], [16, 33], [17, 18],
		     [17, 24], [17, 25], [17, 34],
		     [17, 35], [17, 36], [18, 19],
		     [18, 25], [18, 37], [19, 20],
		     [19, 37], [20, 26], [20, 27],
		     [20, 37], [21, 27], [21, 28],
		     [22, 30], [22, 31], [23, 31],
		     [23, 32], [23, 33], [24, 33],
		     [24, 34], [25, 36], [25, 37],
		     [26, 27], [26, 37], [26, 38],
		     [27, 28], [27, 38], [27, 39],
		     [27, 44], [27, 45], [28, 29],
		     [28, 39], [28, 46], [29, 30],
		     [29, 46], [30, 31], [30, 40],
		     [30, 46], [31, 32], [31, 40],
		     [31, 41], [31, 47], [31, 48],
		     [32, 33], [32, 41], [33, 34],
		     [33, 41], [33, 42], [33, 49],
		     [33, 50], [34, 35], [34, 42],
		     [34, 51], [35, 36], [35, 51],
		     [36, 37], [36, 43], [36, 51],
		     [37, 38], [37, 43], [37, 52],
		     [37, 53], [38, 44], [38, 53],
		     [38, 54], [39, 45], [39, 46],
		     [40, 46], [40, 47], [41, 48],
		     [41, 49], [41, 58], [42, 50],
		     [42, 51], [43, 51], [43, 52],
		     [44, 45], [44, 54], [45, 55],
		     [45, 46], [46, 47], [46, 55],
		     [46, 56], [46, 57], [47, 48],
		     [47, 57], [47, 58], [48, 58],
		     [49, 50], [49, 58], [50, 51],
		     [50, 58], [50, 59], [51, 52],
		     [51, 59], [51, 60], [51, 61],
		     [52, 53], [52, 61], [52, 54],
		     [53, 54], [54, 55], [54, 56],
		     [54, 60], [54, 61], [54, 62],
		     [55, 56], [56, 57], [56, 58],
		     [56, 62], [57, 58], [58, 59],
		     [58, 60], [58, 62], [59, 60],
		     [60, 61], [60, 62] ],
	  Faces => [ [1,  2,  4], [2,  3,  4], [2,  20, 10],
		     [2,  10, 11], [2,  11, 3], [3,  11, 12],
		     [3,  12, 4], [20, 26, 27], [20, 27, 10],
		     [10, 27, 11], [11, 27, 21], [11, 21, 12],
		     [21, 27, 28], [12, 21, 28], [12, 28, 29],
		     [1,  4,  6], [4,  12, 5], [4,  5,  6],
		     [5,  12, 13], [5,  13, 6], [6,  13, 14],
		     [6,  14, 23], [12, 29, 30], [12, 30, 22],
		     [12, 22, 13], [13, 22, 31], [22, 30, 31],
		     [13, 31, 14], [14, 31, 23], [23, 31, 32],
		     [1,  6,  8], [6,  23, 15], [6,  15, 16],
		     [6,  16, 7], [6,  7,  8], [8,  7,  17],
		     [7,  16, 17], [23, 32, 33], [15, 23, 33],
		     [16, 15, 33], [24, 16, 33], [34, 24, 33],
		     [17, 16, 24], [17, 24, 34], [17, 34, 35],
		     [1,  8,  2], [8,  17, 9], [8,  9,  2],
		     [9,  17, 18], [9,  18, 2], [2,  18, 19],
		     [2,  19, 20], [17, 35, 36], [17, 36, 25],
		     [17, 25, 18], [18, 25, 37], [25, 36, 37],
		     [19, 18, 37], [20, 19, 37], [20, 37, 26],
		     [27, 26, 38], [27, 38, 44], [27, 44, 45],
		     [27, 45, 39], [27, 39, 28], [28, 39, 46],
		     [28, 46, 29], [39, 45, 46], [38, 54, 44],
		     [55, 45, 54], [45, 44, 54], [45, 55, 46],
		     [46, 55, 56], [55, 54, 56], [56, 54, 62],
		     [30, 29, 46], [30, 46, 40], [31, 30, 40],
		     [40, 46, 47], [31, 40, 47], [31, 47, 48],
		     [31, 48, 41], [31, 41, 32], [46, 56, 57],
		     [47, 46, 57], [47, 57, 58], [48, 47, 58],
		     [41, 48, 58], [57, 56, 58], [58, 56, 62],
		     [33, 32, 41], [33, 41, 49], [33, 49, 50],
		     [33, 50, 42], [33, 42, 34], [34, 42, 51],
		     [42, 50, 51], [35, 34, 51], [49, 41, 58],
		     [50, 49, 58], [50, 58, 59], [51, 50, 59],
		     [51, 59, 60], [59, 58, 60], [60, 58, 62],
		     [36, 35, 51], [36, 51, 43], [37, 36, 43],
		     [43, 51, 52], [37, 43, 52], [37, 52, 53],
		     [37, 53, 38], [37, 38, 26], [51, 60, 61],
		     [52, 51, 61], [52, 61, 54], [53, 52, 54],
		     [38, 53, 54], [54, 61, 60], [54, 60, 62] ] } ];

#----------------------------------------------------------------------------

# A map from sides or name to the right structure.
#
my $Tris =
{
    120 => $Hexicosahedron,          'hexicosa' => $Hexicosahedron,
     20 => $Icosahedron,             'icosa' => $Icosahedron,
     12 => $Dodecahedron,            'dodeca' => $Dodecahedron,
      8 => $Octahedra,               'octa' => $Octahedra,
      6 => $Sexahedra,               'cube' => $Sexahedra,
                                     'hexa' => $Sexahedra,
                                     'sexa' => $Sexahedra,
      4 => $Tetrahedra,              'tetra' => $Tetrahedra,
};

my $Rhombics =
{
    -30 => $RhombicTriacontahedron,  'triaconta' => $RhombicTriacontahedron,
    -12 => $RhombicDodecahedra,      'dodeca' => $RhombicDodecahedra,
     -6 => $Sexahedra,               'cube' => $Sexahedra,
                                     'hexa' => $Sexahedra,
                                     'sexa' => $Sexahedra,
};

#----------------------------------------------------------------------------

=head2 polyhedra(), polyhedron()

Retrieves a reference to a polyhedron structure by its name or the number
of sides.  This is a read-only structure which defines all of the vertex,
edge and face information for the given polyhedron figure.

The argument should either be a number, or a name.  For example,
C<polyhedron(6)> and C<polyhedron('cube')> and C<polyhedron('rhombic
hexahedron')> are all equivalent methods to retrieve the structure
representing regular six-sided cubical figures.

    my $cube = polyhedron(6); # regular six-sided figure
    my $ico = polyhedron(20); # icosahedron has 20 triangular faces
    my $rhombdod = polyhedron($_ = 'rhombic dodecahedron');
    print 'Found ', scalar @$ico, ' variations of ', $_, $/;

The values inside the reference should not be modified as they are not
recalculated on each subsequent call.  The scalar reference is intended
to be given as an argument to the C<vertices()>, C<edges()>, C<faces()>,
or C<tris()> functions in this module.

The set of known names and their faces are as follows:

=over 4

=item *

tetrahedron (4 triangular faces) [10 variations]

=item *

cube, hexahedron (6 square faces) (+6) (-6) [5 variations]

=item *

octahedron (8 triangular faces) [5 variations]

=item *

dodecahedron (12 pentagonic faces)

=item *

rhombic dodecahedron (12 diamond faces) (-12) [5 variations]

=item *

icosahedron (20 triangular faces)

=item *

rhombic triacontahedron (30 diamond faces) (-30)

=item *

hexicosahedron (120 irregular triangular faces)

=back

Other polyhedra such as the decahedron, a common rhombic ten-sided
figure, cannot be constructed solely using the value of I<phi>, and are
not currently supported by this module.  The name 'hexicosahedron' may be
apocryphal, since it's not a regular shape with 120 regular sides, but is
instead comprised of various unions of the other volumes presented.

For a given polyhedron structure, more than one variation of the
structure may be known.  There are ten different C<'tetrahedra'> defined
by the 62 I<phi> point library, for example.  The expression C<(scalar
@$hedron)> for a given structure will return how many variations are
defined, and C<< ($hedron->[3]) >> will select that specific variety for the
other functions.  These variations are not different in shape, but merely
in differing orientations relative to the origin.  Most applications
don't need this information, but some studies of the S<Golden Ratio> may
select from these variations.

The C<polyhedra()> function is just a convenient alias for the preferred
name, C<polyhedron()>.

=cut

sub polyhedra { polyhedron(@_) }

sub polyhedron
{
    my $sides = shift;
    $sides = lc($sides);
    $sides =~ s/hedron|hedra//;
    my $set = (($sides =~ s/rhomb//) || (0 > $sides))? $Rhombics : $Tris;
    return undef if not $set;
    return $set->{$sides} if $set->{$sides};
    for (keys %$set) { return $set->{$_} if $sides =~ m/$_/ }
    return undef;
}

=head2 vertices()

    my $verts = vertices($cube);
    while (@$verts)
        { draw_dot(shift @$verts); }

Returns a list reference, containing one vector for each vertex in the
polyhedron.  Each vertex is itself a list reference of real coordinate
values, such as this C< [ $x, $y, $z ] > triple.

=cut

sub vertices
{
    my $hedron = shift;
    $hedron = $hedron->[0] if "ARRAY" eq ref $hedron;
    my $coords = coordinates(@_);
    my @v = @{$hedron->{Verts}};
    @v = map { $coords->[$_] } @v;
    return \@v;
}

=head2 edges()

    my $edges = edges($cube);
    while (@$edges)
    {    move_to(shift @$edges);
         draw_to(shift @$edges);
    }

Returns a list reference, which contains two vectors defining each edge
of the polyhedra.  Each pair is an independent edge; the first edge is
the vectors indexed 0 and 1, then index 2 to index 3, and so on.  (This
is not an optimized "line strip.")  The vector references will be
repeated as required.

=cut

sub edges
{
    my $hedron = shift;
    $hedron = $hedron->[0] if "ARRAY" eq ref $hedron;
    my $coords = coordinates(@_);
    my @e = @{$hedron->{Edges}};
    @e = map { $coords->[$_->[0]], $coords->[$_->[1]] } @e;
    return \@e;
}

=head2 faces()

Returns a list reference, which contains sublists of at least three
coplanar vectors defining each face.  Each list is an independent
face.  The vector references will be repeated as required.

The vertices in each face are not sorted or ordered around the
circumference of the face.  Typically, graphics programs should use the
C<edges()> or C<tris()> for ordering information.

=cut

sub faces
{
    my $hedron = shift;
    $hedron = $hedron->[0] if "ARRAY" eq ref $hedron;
    my $coords = coordinates(@_);

    my @e = @{$hedron->{Faces}};

    # multiple tris per face
    # @e = ( [ [ v v v ] [ v v v ] ]
    #        [ [ v v v ] [ v v v ] ] ... )
    if (ref($e[0]) and
	ref($e[0][0]))
    {
	my @ee = ();
	foreach my $f (@e)
	{
	    my %u = ();
	    foreach my $t (@$f)
	        { @u{@$t} = (@$t); }
	    push(@ee, [ map { $coords->[$_] } values %u ]);
	}
	return \@ee;
    }

    # single tris per face
    # @e = ( [ v v v ]
    #        [ v v v ] ... )
    #
    @e = map { [ $coords->[$_->[0]],
		 $coords->[$_->[1]],
		 $coords->[$_->[2]] ] } @e;

    return \@e;
}

=head2 tris()

    my $tris = tris($cube);
    while (@$tris)
    {    first_vertex(shift @$tris);
         second_vertex(shift @$tris),
         third_vertex(shift @$tris);
    }

Returns a list reference, which contains three [ X, Y, Z ] coordinate
triples for each triangle in sublists.  Each triple is an independent
triangle; the first triangle is between vectors 0, 1, 2, then another
triangle between vectors 3, 4, 5, and so on.  (This is not an optimized
"triangle strip.")  The vector references will be repeated as required.

All of the triangles returned are defined in clockwise order, such that
the implied normals (B-A)x(C-A) are facing "outward," away from the
origin.  Many graphics applications require consistent definition to
calculate proper outward-facing normals for lighting or culling.

=cut

sub tris
{
    my $hedron = shift;
    $hedron = $hedron->[0] if "ARRAY" eq ref $hedron;
    my $coords = coordinates(@_);
    my @e = @{$hedron->{Faces}};

    # multiple tris per face
    # @e = ( [ [ v v v ] [ v v v ] ]
    #        [ [ v v v ] [ v v v ] ] ... )
    if (ref($e[0]) and
	ref($e[0][0]))
    {
	@e = map { @$_ } @e;
    }

    # single tris per face
    # @e = ( [ v v v ]
    #        [ v v v ] ... )
    #
    @e = map { $coords->[$_->[0]],
	       $coords->[$_->[1]],
	       $coords->[$_->[2]] } @e;

    return \@e;
}

1;
__END__
#----------------------------------------------------------------------------

=head1 EXAMPLE

    use Math::Polyhedra qw(polyhedron vertices edges faces);

    # Get the geometry.
    my $hedron = polyhedron($_ = 'cube');
    my $verts = vertices($hedron);
    my $edges = edges($hedron);
    my $faces = faces($hedron);

    # Validate Euler's Formula
    $verts = (scalar @$verts);
    $edges = (scalar @$edges) / 2; # each edge shared for two faces
    $faces = (scalar @$faces);
    print "$_ has $verts vertices, $edges edges, and $faces faces.\n";
    my $Euler = $verts - $edges + $faces;
    my $is = $Euler==2? "is" : "is not";
    print "V - E + F = $Euler so the $_ $is simple.\n";

=head1 FUTURE WORK

The current module only has a small set of popular polyhedra, those which
can be defined by the use of the S<Golden Ratio>, or I<phi>.  Future
extensions could add non-I<phi> shapes such as decahedrons, various
tesselated forms, and a set of useful prisms.

The C<faces()> routine should probably derive the proper order of the
vertices returned in each face.  Some graphics libraries can (re)do the
triangular subdivision with better consistency in the implied normals.

Another useful feature would be to return useful C<normals()>, one vector
for each face.  This could augment or precompute the values needed by
some graphics libraries which refuse to work out the implied normals for
you.

=head1 AUTHOR

Ed Halley, E<lt>ed@halley.ccE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 1998-2003 by Ed Halley

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
