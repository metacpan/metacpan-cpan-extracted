#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Vectors in two dimensions
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2017-2020
#-------------------------------------------------------------------------------
# podDocumentation
package Math::Vectors2;
require v5.16;
our $VERSION = 20200419;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Table::Text qw(genHash);
use Math::Trig;

my $nearness = 1e-6;                                                            # Definition of near

sub near($$)                                                                   # Check two scalars are near each other
 {my ($o, $p) = @_;
  abs($p-$o) < $nearness
 }

sub near2($$)                                                                   # Check two vectors are near each other
 {my ($o, $p) = @_;
  $o->d($p) < $nearness
 }

#D1 Methods                                                                     # Vector methods.

sub new($$)                                                                     #S Create new vector from components.
 {my ($x, $y) = @_;                                                             # X component, Y component
  genHash(__PACKAGE__,                                                          # Attributes of a vector
   x => $x,                                                                     # X coordinate
   y => $y,                                                                     # Y coordinate
  );
 }

sub zeroAndUnits()                                                              #S Create the useful vectors: zero=(0,0), x=(1,0), y=(0,1)
 {map {&new(@$_)} ([0, 0], [1, 0], [0, 1])
 }

sub eq($$)                                                                      # Whether two vectors are equal to within the accuracy of floating point arithmetic
 {my ($o, $p) = @_;                                                             # First vector, second vector
  near2($o, $p)
 }

sub zero($)                                                                     # Whether a vector is equal to zero within the accuracy of floating point arithmetic
 {my ($o) = @_;                                                                 # Vector
  near($o->x, 0) && near($o->y, 0)
 }

sub print($@)                                                                   # Print one or more vectors.
 {my ($p, @p) = @_;                                                             # Vector to print, more vectors to print
  join ', ', map {'('.$_->x.','.$_->y.')'} @_
 }

sub clone($)                                                                    # Clone a vector.
 {my ($o) = @_;                                                                 # Vector to clone
  new($o->x, $o->y)
 }

sub Plus($@)                                                                    # Add zero or more other vectors to the first vector and return the result.
 {my ($o, @p) = @_;                                                             # First vector, other vectors
  for(@p)
   {$o->x += $_->x;
    $o->y += $_->y;
   }
  $o
 }

sub plus($@)                                                                    # Add zero or more other vectors to a copy of the first vector and return the result.
 {my ($o, @p) = @_;                                                             # First vector, other vectors
  $o->clone->Plus(@p)
 }

sub Minus($@)                                                                   # Subtract zero or more vectors from the first vector and return the result.
 {my ($o, @p) = @_;                                                             # First vector, other vectors
  for(@p)
   {$o->x -= $_->x;
    $o->y -= $_->y;
   }
  $o
 }

sub minus($@)                                                                   # Subtract zero or more vectors from a copy of the first vector and return the result.
 {my ($o, @p) = @_;                                                             # First vector, other vectors
  $o->clone->Minus(@p)
 }

sub Multiply($$)                                                                # Multiply a vector by a scalar and return the result.
 {my ($o, $m) = @_;                                                             # Vector, scalar to multiply by
  $o->x *= $m; $o->y *= $m;
  $o
 }

sub multiply($$)                                                                # Multiply a copy of a vector by a scalar and return the result.
 {my ($o, $m) = @_;                                                             # Vector, scalar to multiply by
  $o->clone->Multiply($m)
 }

sub Divide($$)                                                                  # Divide a vector by a scalar and return the result.
 {my ($o, $d) = @_;                                                             # Vector, scalar to multiply by
  $o->x /= $d; $o->y /= $d;
  $o
 }

sub divide($$)                                                                  # Divide a copy of a vector by a scalar and return the result.
 {my ($o, $d) = @_;                                                             # Vector, scalar to divide by
  $o->clone->Divide($d)
 }

sub l($)                                                                        # Length of a vector.
 {my ($o) = @_;                                                                 # Vector
  sqrt($o->x**2 + $o->y**2)
 }

sub l2($)                                                                       # Length squared of a vector.
 {my ($o) = @_;                                                                 # Vector
  $o->x**2 + $o->y**2
 }

sub d($$)                                                                       # Distance between the points identified by two vectors when placed on the same point.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  sqrt(($o->x-$p->x)**2 + ($o->y-$p->y)**2)
 }

sub d2($$)                                                                      # Distance squared between the points identified by two vectors when placed on the same point.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  ($o->x-$p->x)**2 + ($o->y-$p->y)**2
 }

sub n($)                                                                        # Return a normalized a copy of a vector.
 {my ($o) = @_;                                                                 # Vector
  my $l = $o->l;
  $l == 0 and confess;
  new($o->x / $l, $o->y / $l)
 }

sub dot($$)                                                                     # Dot product of two vectors.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  $o->x * $p->x + $o->y * $p->y
 }

sub area($$)                                                                    # Signed area of the parallelogram defined by the two vectors. The area is negative if the second vector appears to the right of the first if they are both placed at the origin and the observer stands against the z-axis in a left handed coordinate system.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  $o->x * $p->y - $o->y * $p->x
 }

sub cosine($$)                                                                  # cos(angle between two vectors)
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  $o->dot($p) / $o->l / $p->l
 }

sub sine($$)                                                                    # sin(angle between two vectors)
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  $o->area($p) / $o->l / $p->l
 }

sub angle($$)                                                                   # Angle in radians anticlockwise that the first vector must be rotated to point along the second vector normalized to the range: -pi to +pi.
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  my $c = $o->cosine($p);
  my $s = $o->sine($p);
  my $a = Math::Trig::acos($c);
  $s > 0 ? $a : -$a
 }

sub smallestAngleToNormalPlane($$)                                              # The smallest angle between the second vector and a plane normal to the first vector.
 {my ($a, $b) = @_;                                                             # Vector 1, vector 2
  my $r = abs $a->angle($b);
  my $p = Math::Trig::pi / 2;
  $r < $p ? $p - $r : $r - $p
 }

sub r90($)                                                                      # Rotate a vector by 90 degrees anticlockwise.
 {my ($o) = @_;                                                                 # Vector to rotate
  new(-$o->y, $o->x)
 }

sub r180($)                                                                     # Rotate a vector by 180 degrees.
 {my ($o) = @_;                                                                 # Vector to rotate
  new(-$o->x, -$o->y)
 }

sub r270($)                                                                     # Rotate a vector by 270 degrees anticlockwise.
 {my ($o) = @_;                                                                 # Vector to rotate
  new($o->y, -$o->x)
 }

sub swap($)                                                                     # Swap the components of a vector
 {my ($o) = @_;                                                                 # Vector
  new($o->y, $o->x)
 }

use overload
  '=='       => sub {my ($o, $p) = @_; $o->eq      ($p)},
  '+'        => sub {my ($o, $p) = @_; $o->plus    ($p)},
  '+='       => sub {my ($o, $p) = @_; $o->Plus    ($p)},
  '-'        => sub {my ($o, $p) = @_; ref($p) ? $o->minus($p) : $o->multiply(-1)},
  '-='       => sub {my ($o, $p) = @_; $o->Minus   ($p)},
  '*'        => sub {my ($o, $p) = @_; $o->multiply($p)},
  '*='       => sub {my ($o, $p) = @_; $o->Multiply($p)},
  '/'        => sub {my ($o, $p) = @_; $o->divide  ($p)},
  '/='       => sub {my ($o, $p) = @_; $o->Divide  ($p)},
  '.'        => sub {my ($o, $p) = @_; $o->dot     ($p)},
  'x'        => sub {my ($o, $p) = @_; $o->area    ($p)},
  '<'        => sub {my ($o, $p) = @_; $o->angle   ($p)},
  '""'       => sub {my ($o)     = @_; $o->print       },
  "fallback" => 1;

#D0
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# containingFolder

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw();
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=encoding utf-8

=head1 Name

Math::Vectors2 - Vectors in two dimensions

=head1 Synopsis

  use Math::Vectors2;

  my ($zero, $x, $y) = Math::Vectors2::zeroAndUnits;

  ok near deg2rad(-60),  $x + $y * sqrt(3)    <    $x;
  ok near deg2rad(+30), ($x + $y * sqrt(3))->angle($y);

=head1 Description

Vectors in two dimensions


Version 20200402.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Methods

Vector methods.

=head2 new($x, $y)

Create new vector from components.

     Parameter  Description
  1  $x         X component
  2  $y         Y component

B<Example:>


    my ($zero, $x, $y) = zeroAndUnits;
    ok near $y->angle(𝗻𝗲𝘄(+1, -1)), deg2rad(-135);
    ok near $y->angle(𝗻𝗲𝘄(+1,  0)), deg2rad(-90);
    ok near $y->angle(𝗻𝗲𝘄(+1, +1)), deg2rad(-45);
    ok near $y->angle(𝗻𝗲𝘄( 0, +1)), deg2rad(+0);
    ok near $y->angle(𝗻𝗲𝘄(-1, +1)), deg2rad(+45);
    ok near $y->angle(𝗻𝗲𝘄(-1,  0)), deg2rad(+90);
    ok near $y->angle(𝗻𝗲𝘄(-1, -1)), deg2rad(+135);

    ok near 𝗻𝗲𝘄(1,1) < 𝗻𝗲𝘄( 0, -1), deg2rad(-135);
    ok near 𝗻𝗲𝘄(1,1) < 𝗻𝗲𝘄( 1, -1), deg2rad(-90);
    ok near 𝗻𝗲𝘄(1,1) < 𝗻𝗲𝘄( 1,  0), deg2rad(-45);
    ok near 𝗻𝗲𝘄(1,1) < 𝗻𝗲𝘄( 1,  1), deg2rad(0);
    ok near 𝗻𝗲𝘄(1,1) < 𝗻𝗲𝘄( 0,  1), deg2rad(+45);
    ok near 𝗻𝗲𝘄(1,1) < 𝗻𝗲𝘄(-1,  1), deg2rad(+90);
    ok near 𝗻𝗲𝘄(1,1) < 𝗻𝗲𝘄(-1,  0), deg2rad(+135);

    ok near $x + $y * sqrt(3) < $x, deg2rad(-60);
    ok near $x + $y * sqrt(3) < $y, deg2rad(+30);

    for my $i(-179..179)
     {ok near $x < 𝗻𝗲𝘄(cos(deg2rad($i)), sin(deg2rad($i))), deg2rad($i);
     }


This is a static method and so should either be imported or invoked as:

  Math::Vectors2::new


=head2 zeroAndUnits()

Create the useful vectors: o=(0,0), x=(1,0), y=(0,1)


B<Example:>


    my ($z, $x, $y) = 𝘇𝗲𝗿𝗼𝗔𝗻𝗱𝗨𝗻𝗶𝘁𝘀;
    ok $x + $y + $z == $x->plus($y);
    ok $x - $y == $x->minus($y);
    ok $x * 3  == $x->multiply(3);
    ok $y / 2  == $y->divide(2);
    ok $x + $y eq '(1,1)';
    ok $x - $y eq '(1,-1)';
    ok $x * 3  eq '(3,0)';
    ok $y / 2  eq '(0,0.5)';
    ok (($x * 2 + $y * 3)-> print eq '(2,3)');


This is a static method and so should either be imported or invoked as:

  Math::Vectors2::zeroAndUnits


=head2 eq($o, $p)

Whether two vectors are equal to within the accuracy of floating point arithmetic

     Parameter  Description
  1  $o         First vector
  2  $p         Second vector

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x + $y + $z == $x->plus($y);
    ok $x - $y == $x->minus($y);
    ok $x * 3  == $x->multiply(3);
    ok $y / 2  == $y->divide(2);
    ok $x + $y 𝗲𝗾 '(1,1)';
    ok $x - $y 𝗲𝗾 '(1,-1)';
    ok $x * 3  𝗲𝗾 '(3,0)';
    ok $y / 2  𝗲𝗾 '(0,0.5)';
    ok (($x * 2 + $y * 3)-> print 𝗲𝗾 '(2,3)');


=head2 zero($o)

Whether a vector is equal to zero within the accuracy of floating point arithmetic

     Parameter  Description
  1  $o         Vector

B<Example:>


    my ($𝘇𝗲𝗿𝗼, $x, $y) = zeroAndUnits;
    ok $𝘇𝗲𝗿𝗼->𝘇𝗲𝗿𝗼;
    ok !$x->𝘇𝗲𝗿𝗼;
    ok !$y->𝘇𝗲𝗿𝗼;


=head2 print($p, @p)

Print one or more vectors.

     Parameter  Description
  1  $p         Vector to print
  2  @p         More vectors to print

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x + $y + $z == $x->plus($y);
    ok $x - $y == $x->minus($y);
    ok $x * 3  == $x->multiply(3);
    ok $y / 2  == $y->divide(2);
    ok $x + $y eq '(1,1)';
    ok $x - $y eq '(1,-1)';
    ok $x * 3  eq '(3,0)';
    ok $y / 2  eq '(0,0.5)';
    ok (($x * 2 + $y * 3)-> 𝗽𝗿𝗶𝗻𝘁 eq '(2,3)');


=head2 clone($o)

Clone a vector.

     Parameter  Description
  1  $o         Vector to clone

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x->swap == $y;
    ok $x->𝗰𝗹𝗼𝗻𝗲 == $x;


=head2 Plus($o, @p)

Add zero or more other vectors to the first vector and return the result.

     Parameter  Description
  1  $o         First vector
  2  @p         Other vectors

B<Example:>


    my ($zero, $x, $y) = zeroAndUnits;
    $x->𝗣𝗹𝘂𝘀(new(1,1));
    ok $x eq '(2,1)';
    $y += new(1,1);
    ok $y eq '(1,2)';



=head2 plus($o, @p)

Add zero or more other vectors to a copy of the first vector and return the result.

     Parameter  Description
  1  $o         First vector
  2  @p         Other vectors

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x + $y + $z == $x->𝗽𝗹𝘂𝘀($y);
    ok $x - $y == $x->minus($y);
    ok $x * 3  == $x->multiply(3);
    ok $y / 2  == $y->divide(2);
    ok $x + $y eq '(1,1)';
    ok $x - $y eq '(1,-1)';
    ok $x * 3  eq '(3,0)';
    ok $y / 2  eq '(0,0.5)';
    ok (($x * 2 + $y * 3)-> print eq '(2,3)');


=head2 Minus($o, @p)

Subtract zero or more vectors from the first vector and return the result.

     Parameter  Description
  1  $o         First vector
  2  @p         Other vectors

B<Example:>


    my ($zero, $x, $y) = zeroAndUnits;
    $x->𝗠𝗶𝗻𝘂𝘀(new(0, 1));
    ok $x eq '(1,-1)';
    $y -= new(1,1);
    ok $y eq '(-1,0)';


=head2 minus($o, @p)

Subtract zero or more vectors from a copy of the first vector and return the result.

     Parameter  Description
  1  $o         First vector
  2  @p         Other vectors

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x + $y + $z == $x->plus($y);
    ok $x - $y == $x->𝗺𝗶𝗻𝘂𝘀($y);
    ok $x * 3  == $x->multiply(3);
    ok $y / 2  == $y->divide(2);
    ok $x + $y eq '(1,1)';
    ok $x - $y eq '(1,-1)';
    ok $x * 3  eq '(3,0)';
    ok $y / 2  eq '(0,0.5)';
    ok (($x * 2 + $y * 3)-> print eq '(2,3)');


=head2 Multiply($o, $m)

Multiply a vector by a scalar and return the result.

     Parameter  Description
  1  $o         Vector
  2  $m         Scalar to multiply by

B<Example:>


    my ($zero, $x, $y) = zeroAndUnits;
    $x->𝗠𝘂𝗹𝘁𝗶𝗽𝗹𝘆(2);
    ok $x eq '(2,0)';
    $y *= 2;
    ok $y eq '(0,2)';



=head2 multiply($o, $m)

Multiply a copy of a vector by a scalar and return the result.

     Parameter  Description
  1  $o         Vector
  2  $m         Scalar to multiply by

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x + $y + $z == $x->plus($y);
    ok $x - $y == $x->minus($y);
    ok $x * 3  == $x->𝗺𝘂𝗹𝘁𝗶𝗽𝗹𝘆(3);
    ok $y / 2  == $y->divide(2);
    ok $x + $y eq '(1,1)';
    ok $x - $y eq '(1,-1)';
    ok $x * 3  eq '(3,0)';
    ok $y / 2  eq '(0,0.5)';
    ok (($x * 2 + $y * 3)-> print eq '(2,3)');


=head2 Divide($o, $d)

Divide a vector by a scalar and return the result.

     Parameter  Description
  1  $o         Vector
  2  $d         Scalar to multiply by

B<Example:>


    my ($zero, $x, $y) = zeroAndUnits;
    $x->𝗗𝗶𝘃𝗶𝗱𝗲(1/2);
    ok $x eq '(2,0)';
    $y /= 1/2;
    ok $y eq '(0,2)';



=head2 divide($o, $d)

Divide a copy of a vector by a scalar and return the result.

     Parameter  Description
  1  $o         Vector
  2  $d         Scalar to divide by

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x + $y + $z == $x->plus($y);
    ok $x - $y == $x->minus($y);
    ok $x * 3  == $x->multiply(3);
    ok $y / 2  == $y->𝗱𝗶𝘃𝗶𝗱𝗲(2);
    ok $x + $y eq '(1,1)';
    ok $x - $y eq '(1,-1)';
    ok $x * 3  eq '(3,0)';
    ok $y / 2  eq '(0,0.5)';
    ok (($x * 2 + $y * 3)-> print eq '(2,3)');


=head2 l($o)

Length of a vector.

     Parameter  Description
  1  $o         Vector

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;

    ok  5 == ($x * 3 + $y * 4)->𝗹;
    ok 25 == ($x * 3 + $y * 4)->l2;

    ok 2 * ($x + $y)->𝗹  == ($x + $y)->d (-$x - $y);
    ok 4 * ($x + $y)->l2 == ($x + $y)->d2(-$x - $y);


=head2 l2($o)

Length squared of a vector.

     Parameter  Description
  1  $o         Vector

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;

    ok  5 == ($x * 3 + $y * 4)->l;
    ok 25 == ($x * 3 + $y * 4)->𝗹𝟮;

    ok 2 * ($x + $y)->l  == ($x + $y)->d (-$x - $y);
    ok 4 * ($x + $y)->𝗹𝟮 == ($x + $y)->d2(-$x - $y);


=head2 d($o, $p)

Distance between the points identified by two vectors when placed on the same point.

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;

    ok  5 == ($x * 3 + $y * 4)->l;
    ok 25 == ($x * 3 + $y * 4)->l2;

    ok 2 * ($x + $y)->l  == ($x + $y)->𝗱 (-$x - $y);
    ok 4 * ($x + $y)->l2 == ($x + $y)->d2(-$x - $y);


=head2 d2($o, $p)

Distance squared between the points identified by two vectors when placed on the same point.

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;

    ok  5 == ($x * 3 + $y * 4)->l;
    ok 25 == ($x * 3 + $y * 4)->l2;

    ok 2 * ($x + $y)->l  == ($x + $y)->d (-$x - $y);
    ok 4 * ($x + $y)->l2 == ($x + $y)->𝗱𝟮(-$x - $y);


=head2 n($o)

Return a normalized a copy of a vector.

     Parameter  Description
  1  $o         Vector

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok (($x * 3 + $y * 4)->𝗻 == $x * 3/5 + $y * 4/5);

    ok 0 == $x . $y;
    ok 1 == $x . $x;
    ok 1 == $y . $y;
    ok 8 == ($x * 1 + $y * 2) .($x * 2 + $y * 3);


=head2 dot($o, $p)

Dot product of two vectors.

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok (($x * 3 + $y * 4)->n == $x * 3/5 + $y * 4/5);

    ok 0 == $x . $y;
    ok 1 == $x . $x;
    ok 1 == $y . $y;
    ok 8 == ($x * 1 + $y * 2) .($x * 2 + $y * 3);


=head2 area($o, $p)

Signed area of the parallelogram defined by the two vectors. The area is negative if the second vector appears to the right of the first if they are both placed at the origin and the observer stands against the z-axis in a left handed coordinate system.

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok +1 == $x->cosine($x);
    ok +1 == $y->cosine($y);
    ok  0 == $x->cosine($y);
    ok  0 == $y->cosine($x);

    ok  0 == $x->sine($x);
    ok  0 == $y->sine($y);
    ok +1 == $x->sine($y);
    ok -1 == $y->sine($x);

    ok near -sqrt(1/2), ($x + $y)->sine($x);
    ok near +sqrt(1/2), ($x + $y)->sine($y);
    ok near -2,         ($x + $y)->𝗮𝗿𝗲𝗮($x * 2);
    ok near +2,         ($x + $y)->𝗮𝗿𝗲𝗮($y * 2);


=head2 cosine($o, $p)

cos(angle between two vectors)

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok +1 == $x->𝗰𝗼𝘀𝗶𝗻𝗲($x);
    ok +1 == $y->𝗰𝗼𝘀𝗶𝗻𝗲($y);
    ok  0 == $x->𝗰𝗼𝘀𝗶𝗻𝗲($y);
    ok  0 == $y->𝗰𝗼𝘀𝗶𝗻𝗲($x);

    ok  0 == $x->sine($x);
    ok  0 == $y->sine($y);
    ok +1 == $x->sine($y);
    ok -1 == $y->sine($x);

    ok near -sqrt(1/2), ($x + $y)->sine($x);
    ok near +sqrt(1/2), ($x + $y)->sine($y);
    ok near -2,         ($x + $y)->area($x * 2);
    ok near +2,         ($x + $y)->area($y * 2);


=head2 sine($o, $p)

sin(angle between two vectors)

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok +1 == $x->cosine($x);
    ok +1 == $y->cosine($y);
    ok  0 == $x->cosine($y);
    ok  0 == $y->cosine($x);

    ok  0 == $x->𝘀𝗶𝗻𝗲($x);
    ok  0 == $y->𝘀𝗶𝗻𝗲($y);
    ok +1 == $x->𝘀𝗶𝗻𝗲($y);
    ok -1 == $y->𝘀𝗶𝗻𝗲($x);

    ok near -sqrt(1/2), ($x + $y)->𝘀𝗶𝗻𝗲($x);
    ok near +sqrt(1/2), ($x + $y)->𝘀𝗶𝗻𝗲($y);
    ok near -2,         ($x + $y)->area($x * 2);
    ok near +2,         ($x + $y)->area($y * 2);


=head2 angle($o, $p)

Angle in radians anticlockwise that the first vector must be rotated to point along the second vector normalized to the range: -pi to +pi.

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($zero, $x, $y) = zeroAndUnits;
    ok near $y->𝗮𝗻𝗴𝗹𝗲(new(+1, -1)), deg2rad(-135);
    ok near $y->𝗮𝗻𝗴𝗹𝗲(new(+1,  0)), deg2rad(-90);
    ok near $y->𝗮𝗻𝗴𝗹𝗲(new(+1, +1)), deg2rad(-45);
    ok near $y->𝗮𝗻𝗴𝗹𝗲(new( 0, +1)), deg2rad(+0);
    ok near $y->𝗮𝗻𝗴𝗹𝗲(new(-1, +1)), deg2rad(+45);
    ok near $y->𝗮𝗻𝗴𝗹𝗲(new(-1,  0)), deg2rad(+90);
    ok near $y->𝗮𝗻𝗴𝗹𝗲(new(-1, -1)), deg2rad(+135);

    ok near new(1,1) < new( 0, -1), deg2rad(-135);
    ok near new(1,1) < new( 1, -1), deg2rad(-90);
    ok near new(1,1) < new( 1,  0), deg2rad(-45);
    ok near new(1,1) < new( 1,  1), deg2rad(0);
    ok near new(1,1) < new( 0,  1), deg2rad(+45);
    ok near new(1,1) < new(-1,  1), deg2rad(+90);
    ok near new(1,1) < new(-1,  0), deg2rad(+135);

    ok near $x + $y * sqrt(3) < $x, deg2rad(-60);
    ok near $x + $y * sqrt(3) < $y, deg2rad(+30);

    for my $i(-179..179)
     {ok near $x < new(cos(deg2rad($i)), sin(deg2rad($i))), deg2rad($i);
     }


=head2 r90($o)

Rotate a vector by 90 degrees anticlockwise.

     Parameter  Description
  1  $o         Vector to rotate

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x->𝗿𝟵𝟬           ==  $y;
    ok $y->𝗿𝟵𝟬           == -$x;
    ok $x->𝗿𝟵𝟬->𝗿𝟵𝟬      == -$x;
    ok $y->𝗿𝟵𝟬->𝗿𝟵𝟬      == -$y;
    ok $x->𝗿𝟵𝟬->𝗿𝟵𝟬->𝗿𝟵𝟬 == -$y;
    ok $y->𝗿𝟵𝟬->𝗿𝟵𝟬->𝗿𝟵𝟬 ==  $x;


=head2 r180($o)

Rotate a vector by 180 degrees.

     Parameter  Description
  1  $o         Vector to rotate

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x->r90           ==  $y;
    ok $y->r90           == -$x;
    ok $x->r90->r90      == -$x;
    ok $y->r90->r90      == -$y;
    ok $x->r90->r90->r90 == -$y;
    ok $y->r90->r90->r90 ==  $x;


=head2 r270($o)

Rotate a vector by 270 degrees anticlockwise.

     Parameter  Description
  1  $o         Vector to rotate

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x->r90           ==  $y;
    ok $y->r90           == -$x;
    ok $x->r90->r90      == -$x;
    ok $y->r90->r90      == -$y;
    ok $x->r90->r90->r90 == -$y;
    ok $y->r90->r90->r90 ==  $x;


=head2 swap($o)

Swap the components of a vector

     Parameter  Description
  1  $o         Vector

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x->𝘀𝘄𝗮𝗽 == $y;
    ok $x->clone == $x;



=head2 Math::Vectors2 Definition


Attributes of a vector




=head3 Output fields


B<x> - X coordinate

B<y> - Y coordinate



=head1 Index


1 L<angle|/angle> - Angle in radians anticlockwise that the first vector must be rotated to point along the second vector normalized to the range: -pi to +pi.

2 L<area|/area> - Signed area of the parallelogram defined by the two vectors.

3 L<clone|/clone> - Clone a vector.

4 L<cosine|/cosine> - cos(angle between two vectors)

5 L<d|/d> - Distance between the points identified by two vectors when placed on the same point.

6 L<d2|/d2> - Distance squared between the points identified by two vectors when placed on the same point.

7 L<divide|/divide> - Divide a copy of a vector by a scalar and return the result.

8 L<Divide|/Divide> - Divide a vector by a scalar and return the result.

9 L<dot|/dot> - Dot product of two vectors.

10 L<eq|/eq> - Whether two vectors are equal to within the accuracy of floating point arithmetic

11 L<l|/l> - Length of a vector.

12 L<l2|/l2> - Length squared of a vector.

13 L<Minus|/Minus> - Subtract zero or more vectors from the first vector and return the result.

14 L<minus|/minus> - Subtract zero or more vectors from a copy of the first vector and return the result.

15 L<Multiply|/Multiply> - Multiply a vector by a scalar and return the result.

16 L<multiply|/multiply> - Multiply a copy of a vector by a scalar and return the result.

17 L<n|/n> - Return a normalized a copy of a vector.

18 L<new|/new> - Create new vector from components.

19 L<Plus|/Plus> - Add zero or more other vectors to the first vector and return the result.

20 L<plus|/plus> - Add zero or more other vectors to a copy of the first vector and return the result.

21 L<print|/print> - Print one or more vectors.

22 L<r180|/r180> - Rotate a vector by 180 degrees.

23 L<r270|/r270> - Rotate a vector by 270 degrees anticlockwise.

24 L<r90|/r90> - Rotate a vector by 90 degrees anticlockwise.

25 L<sine|/sine> - sin(angle between two vectors)

26 L<swap|/swap> - Swap the components of a vector

27 L<zero|/zero> - Whether a vector is equal to zero within the accuracy of floating point arithmetic

28 L<zeroAndUnits|/zeroAndUnits> - Create the useful vectors: o=(0,0), x=(1,0), y=(0,1)

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Math::Vectors2

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More tests => 433;

if (1) {                                                                        #TzeroAndUnits #Tplus #Tminus #Tmultiply #Tdivide #Teq #Tprint
  my ($z, $x, $y) = zeroAndUnits;
  ok $x + $y + $z == $x->plus($y);
  ok $x - $y == $x->minus($y);
  ok $x * 3  == $x->multiply(3);
  ok $y / 2  == $y->divide(2);
  ok $x + $y eq '(1,1)';
  ok $x - $y eq '(1,-1)';
  ok $x * 3  eq '(3,0)';
  ok $y / 2  eq '(0,0.5)';
  ok (($x * 2 + $y * 3)-> print eq '(2,3)');
 }

if (1) {                                                                        #Tclone #Tswap
  my ($z, $x, $y) = zeroAndUnits;
  ok $x->swap == $y;
  ok $x->clone == $x;
 }

if (1) {                                                                        #Td #Td2 #Tl #Tl2
  my ($z, $x, $y) = zeroAndUnits;

  ok  5 == ($x * 3 + $y * 4)->l;
  ok 25 == ($x * 3 + $y * 4)->l2;

  ok 2 * ($x + $y)->l  == ($x + $y)->d (-$x - $y);
  ok 4 * ($x + $y)->l2 == ($x + $y)->d2(-$x - $y);
 }

if (1) {                                                                        #Tn #Tdot
  my ($z, $x, $y) = zeroAndUnits;
  ok (($x * 3 + $y * 4)->n == $x * 3/5 + $y * 4/5);

  ok 0 == $x . $y;
  ok 1 == $x . $x;
  ok 1 == $y . $y;
  ok 8 == ($x * 1 + $y * 2) .($x * 2 + $y * 3);
 }


if (1) {                                                                        #Tr90 #Tr180 #Tr270
  my ($z, $x, $y) = zeroAndUnits;
  ok $x->r90           ==  $y;
  ok $y->r90           == -$x;
  ok $x->r90->r90      == -$x;
  ok $y->r90->r90      == -$y;
  ok $x->r90->r90->r90 == -$y;
  ok $y->r90->r90->r90 ==  $x;
 }


if (1) {                                                                        #Tsine #Tcosine #Tarea
  my ($z, $x, $y) = zeroAndUnits;
  ok +1 == $x->cosine($x);
  ok +1 == $y->cosine($y);
  ok  0 == $x->cosine($y);
  ok  0 == $y->cosine($x);

  ok  0 == $x->sine($x);
  ok  0 == $y->sine($y);
  ok +1 == $x->sine($y);
  ok -1 == $y->sine($x);

  ok near -sqrt(1/2), ($x + $y)->sine($x);
  ok near +sqrt(1/2), ($x + $y)->sine($y);
  ok near -2,         ($x + $y)->area($x * 2);
  ok near +2,         ($x + $y)->area($y * 2);
 }

if (1) {                                                                        #Tangle #Tnew
  my ($zero, $x, $y) = zeroAndUnits;
  ok near $y->angle(new(+1, -1)), deg2rad(-135);
  ok near $y->angle(new(+1,  0)), deg2rad(-90);
  ok near $y->angle(new(+1, +1)), deg2rad(-45);
  ok near $y->angle(new( 0, +1)), deg2rad(+0);
  ok near $y->angle(new(-1, +1)), deg2rad(+45);
  ok near $y->angle(new(-1,  0)), deg2rad(+90);
  ok near $y->angle(new(-1, -1)), deg2rad(+135);

  ok near new(1,1) < new( 0, -1), deg2rad(-135);
  ok near new(1,1) < new( 1, -1), deg2rad(-90);
  ok near new(1,1) < new( 1,  0), deg2rad(-45);
  ok near new(1,1) < new( 1,  1), deg2rad(0);
  ok near new(1,1) < new( 0,  1), deg2rad(+45);
  ok near new(1,1) < new(-1,  1), deg2rad(+90);
  ok near new(1,1) < new(-1,  0), deg2rad(+135);

  ok near deg2rad(-60),  $x + $y * sqrt(3)    <    $x;
  ok near deg2rad(+30), ($x + $y * sqrt(3))->angle($y);

  ok near deg2rad(  0), $y->smallestAngleToNormalPlane( $x);                    # First vector is y, second vector is 0 degrees anti-clockwise from x axis
  ok near deg2rad(+45), $y->smallestAngleToNormalPlane( $x +  $y);              #   +45
  ok near deg2rad(+90), $y->smallestAngleToNormalPlane(       $y);              #   +90
  ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              #  +135
  ok near deg2rad(  0), $y->smallestAngleToNormalPlane(-$x);                    #  +180
  ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              #  +225
  ok near deg2rad(+90), $y->smallestAngleToNormalPlane(      -$y);              #  +270
  ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              #  +315
  ok near deg2rad(  0), $y->smallestAngleToNormalPlane( $x);                    #  +360

  for my $i(-179..179)
   {ok near $x < new(cos(deg2rad($i)), sin(deg2rad($i))), deg2rad($i);
   }
 }

if (1) {                                                                        #TPlus
  my ($zero, $x, $y) = zeroAndUnits;
  $x->Plus(new(1,1));
  ok $x eq '(2,1)';
  $y += new(1,1);
  ok $y eq '(1,2)';

 }
if (1) {                                                                        #TMinus
  my ($zero, $x, $y) = zeroAndUnits;
  $x->Minus(new(0, 1));
  ok $x eq '(1,-1)';
  $y -= new(1,1);
  ok $y eq '(-1,0)';
 }
if (1) {                                                                        #TMultiply
  my ($zero, $x, $y) = zeroAndUnits;
  $x->Multiply(2);
  ok $x eq '(2,0)';
  $y *= 2;
  ok $y eq '(0,2)';

 }
if (1) {                                                                        #TDivide
  my ($zero, $x, $y) = zeroAndUnits;
  $x->Divide(1/2);
  ok $x eq '(2,0)';
  $y /= 1/2;
  ok $y eq '(0,2)';

 }

if (1) {                                                                        #Tzero
  my ($zero, $x, $y) = zeroAndUnits;
  ok $zero->zero;
  ok !$x->zero;
  ok !$y->zero;
 }

