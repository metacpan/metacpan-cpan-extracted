#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Vectors in two dimensions
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2017-2020
#-------------------------------------------------------------------------------
# podDocumentation
package Math::Vectors2;
require v5.16;
our $VERSION = 20231002;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(genHash);
use Math::Trig;

my $nearness = 1e-6;                                                            # Definition of near

sub near($$)                                                                    # Check two scalars are near each other.
 {my ($o, $p) = @_;
  abs($p-$o) < $nearness
 }

sub near2($$)                                                                   # Check two vectors are near each other.
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

sub zeroAndUnits()                                                              #S Create the useful vectors: zero=(0,0), x=(1,0), y=(0,1).
 {map {&new(@$_)} ([0, 0], [1, 0], [0, 1])
 }

sub eq($$)                                                                      # Whether two vectors are equal to within the accuracy of floating point arithmetic.
 {my ($o, $p) = @_;                                                             # First vector, second vector
  near2($o, $p)
 }

sub zero($)                                                                     # Whether a vector is equal to zero within the accuracy of floating point arithmetic.
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

sub cosine($$)                                                                  # Cos(angle between two vectors).
 {my ($o, $p) = @_;                                                             # Vector 1, vector 2
  $o->dot($p) / $o->l / $p->l
 }

sub sine($$)                                                                    # Sin(angle between two vectors).
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

sub rotate($$$$)                                                                # Rotate a vector about another vector through an angle specified by its values as sin, and cos.
 {my ($p, $o, $sin, $cos) = @_;                                                 # Vector to rotate, center of rotation, sin of the angle of rotation, cosine of the angle of rotation
  my $q = $p - $o;
  $o + new($cos*$q->x-$sin*$q->y, $sin*$q->x+$cos*$q->y) 
 }

my sub min(@)                                                                   #P Find the minimum number in a list of numbers
 {my (@m) = @_;                                                                 # Numbers
  my $M = shift @m;             
  for(@m)                       
   {$M = $_ if $_ < $M;         
   }                            
  $M                            
 }                              
							    
my sub max(@)                                                                   #P Find the maximum number in a list of numbers
 {my (@m) = @_;                                                                 # Numbers
  my $M = shift @m;             
  for(@m)                       
   {$M = $_ if $_ > $M;         
   }                            
  $M                            
 }

sub intersection($$$$)                                                          # Find the intersection of two line segments delimited by vectors if such a point exists.
 {my ($a, $b, $c, $d) = @_;                                                     # Start of first line segment, end of first line segment, start of second line segment, end of second line segment

  my $abx = min($a->x, $b->x); my $abX = max($a->x, $b->x);
  my $aby = min($a->y, $b->y); my $abY = max($a->y, $b->y);
  my $cdx = min($c->x, $d->x); my $cdX = max($c->x, $d->x);
  my $cdy = min($c->y, $d->y); my $cdY = max($c->y, $d->y);
  
  return undef if $abX < $cdx;                                                  # Quick reject
  return undef if $abY < $cdy;
  return undef if $abx > $cdX;
  return undef if $aby > $cdY;
 
# $a + $l * ($b - $a) == $c + $m * ($d - $c) 
# $a - $c == $m * ($d - $c) - $l * ($b - $a) 
# $ac     == $m * ($dc) - $l * ($ba) 
# 
# $acx = $m * $dcx - $l * $bax
# $acy = $m * $dcy - $l * $bay
# 
# $acx * $dcy = $m * $dcx * $dcy - $l * $bax * $dcy
# $acy * $dcx = $m * $dcx * $dcy - $l * $dcx * $bay
# 
# $acx * $dcy - $acy * $dcx = $l($dcx * $bay - $bax * $dcy)
# 
# $l = ($acx * $dcy - $acy * $dcx) / ($dcx * $bay - $bax * $dcy)
  
  my $l = (($a-$c)->x * ($d-$c)->y - ($a-$c)->y * ($d-$c)->x) / (($d-$c)->x * ($b-$a)->y - ($b-$a)->x * ($d-$c)->y);
  $a + $l * ($b - $a) 
 }

sub triangulate($@)                                                             # Find a set of triangles that cover a shape whose boundary points are represented by an array of vectors. The points along the boundary must be given in such away that the interior of the shape is always on the same side for each pair of successive points as indicated by the clockwise parameter. 
 {my ($clockwise, @boundary) = @_;                                              # If true then the interior of the shape is on the left as the boundary of the shape is traversed otherwise on the right, vectors representing the boundary of the shape

  @boundary >= 3 or confess "Need at least 3 points to outline the shape.";  

  my @t; my @b = @boundary;                                                     # Generated triangles. Current boundary
  
  while(@b > 3)                                                                 # Reduce the boundary by one point by triangulating four consecutive points.
   {my @B;                                                                      # New boundary
	for(my $i = 0; $i < @b; ++$i)                                               # Move around border filling in where possible to establish a new inner boundary that is smaller than the outer boundary
	 {my $A = $b[$i % @b];
	  my ($B, $C, $D) = ($b[($i+1) % @b], $b[($i+2) % @b], $b[($i+3) % @b]);
      if (defined(my $X = intersection($A, $C, $B, $D)))                        # Located the intersection
       {my $a = area($X - $A, $B - $A);                                         # Area of triangle made by first pair and intersection
        my $b = area($X - $B, $C - $B);                                         # Area of triangle made by second pair and intersection
        my $c = area($X - $C, $D - $C);                                         # Area of triangle made by third pair and intersection
        if ($a < 0 && $b < 0 && $c < 0 &&  $clockwise or 
            $a > 0 && $b > 0 && $c > 0 && !$clockwise)                          # All of the triangles are on the expected side 
         {push @t, [$X, $A, $B], [$X, $B, $C], [$X, $C, $D]; 
 	 	  push @B, $A, $X, $D;
		  $i += 3;
	     } 
	    else	                                                                # One or more of the triangles is outside the shape
	     {push @B, $A;
    	 } 
       }
     }
    if (@B == @b)                                                               # Unable to make any reductions
     {my $c = $clockwise ? 0 : 1;
	  confess <<END;
No reductions available yet shape not filled. You might want to try again with
the clockwise parameter set to $c.
END
     }   
    @b = @B;                                                                    # New boundary
   }
  push @t, [@b] if @b == 3;                                                     # Last triangle
  @t                                                                            # Triangulation
 }

sub swap($)                                                                     # Swap the components of a vector.
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


Version 20231001.


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
  
    ok near $y->angle(new(+1, -1)), deg2rad(-135);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new(+1,  0)), deg2rad(-90);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new(+1, +1)), deg2rad(-45);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new( 0, +1)), deg2rad(+0);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new(-1, +1)), deg2rad(+45);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new(-1,  0)), deg2rad(+90);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new(-1, -1)), deg2rad(+135);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
  
    ok near new(1,1) < new( 0, -1), deg2rad(-135);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near new(1,1) < new( 1, -1), deg2rad(-90);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near new(1,1) < new( 1,  0), deg2rad(-45);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near new(1,1) < new( 1,  1), deg2rad(0);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near new(1,1) < new( 0,  1), deg2rad(+45);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near new(1,1) < new(-1,  1), deg2rad(+90);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near new(1,1) < new(-1,  0), deg2rad(+135);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near deg2rad(-60),  $x + $y * sqrt(3)    <    $x;
    ok near deg2rad(+30), ($x + $y * sqrt(3))->angle($y);
  
    ok near deg2rad(  0), $y->smallestAngleToNormalPlane( $x);                    # First vector is y, second vector is 0 degrees anti-clockwise from x axis
    ok near deg2rad(+45), $y->smallestAngleToNormalPlane( $x +  $y);              
    ok near deg2rad(+90), $y->smallestAngleToNormalPlane(       $y);              
    ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              
    ok near deg2rad(  0), $y->smallestAngleToNormalPlane(-$x);                    
    ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              
    ok near deg2rad(+90), $y->smallestAngleToNormalPlane(      -$y);              
    ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              
    ok near deg2rad(  0), $y->smallestAngleToNormalPlane( $x);                    
  
    for my $i(-179..179)
  
     {ok near $x < new(cos(deg2rad($i)), sin(deg2rad($i))), deg2rad($i);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     }
  

This is a static method and so should either be imported or invoked as:

  Math::Vectors2::new


=head2 zeroAndUnits()

Create the useful vectors: zero=(0,0), x=(1,0), y=(0,1).


B<Example:>


  
    my ($z, $x, $y) = zeroAndUnits;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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

Whether two vectors are equal to within the accuracy of floating point arithmetic.

     Parameter  Description
  1  $o         First vector
  2  $p         Second vector

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x + $y + $z == $x->plus($y);
    ok $x - $y == $x->minus($y);
    ok $x * 3  == $x->multiply(3);
    ok $y / 2  == $y->divide(2);
  
    ok $x + $y eq '(1,1)';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $x - $y eq '(1,-1)';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $x * 3  eq '(3,0)';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $y / 2  eq '(0,0.5)';  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok (($x * 2 + $y * 3)-> print eq '(2,3)');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 zero($o)

Whether a vector is equal to zero within the accuracy of floating point arithmetic.

     Parameter  Description
  1  $o         Vector

B<Example:>


  
    my ($zero, $x, $y) = zeroAndUnits;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $zero->zero;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$x->zero;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok !$y->zero;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

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
  
    ok (($x * 2 + $y * 3)-> print eq '(2,3)');  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 clone($o)

Clone a vector.

     Parameter  Description
  1  $o         Vector to clone

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok $x->swap == $y;
  
    ok $x->clone == $x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 Plus($o, @p)

Add zero or more other vectors to the first vector and return the result.

     Parameter  Description
  1  $o         First vector
  2  @p         Other vectors

B<Example:>


    my ($zero, $x, $y) = zeroAndUnits;
  
    $x->Plus(new(1,1));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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
  
    ok $x + $y + $z == $x->plus($y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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
  
    $x->Minus(new(0, 1));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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
  
    ok $x - $y == $x->minus($y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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
  
    $x->Multiply(2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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
  
    ok $x * 3  == $x->multiply(3);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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
  
    $x->Divide(1/2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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
  
    ok $y / 2  == $y->divide(2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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
  
  
    ok  5 == ($x * 3 + $y * 4)->l;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok 25 == ($x * 3 + $y * 4)->l2;
  
  
    ok 2 * ($x + $y)->l  == ($x + $y)->d (-$x - $y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok 4 * ($x + $y)->l2 == ($x + $y)->d2(-$x - $y);
  

=head2 l2($o)

Length squared of a vector.

     Parameter  Description
  1  $o         Vector

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
  
    ok  5 == ($x * 3 + $y * 4)->l;
  
    ok 25 == ($x * 3 + $y * 4)->l2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok 2 * ($x + $y)->l  == ($x + $y)->d (-$x - $y);
  
    ok 4 * ($x + $y)->l2 == ($x + $y)->d2(-$x - $y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 d($o, $p)

Distance between the points identified by two vectors when placed on the same point.

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
  
    ok  5 == ($x * 3 + $y * 4)->l;
    ok 25 == ($x * 3 + $y * 4)->l2;
  
  
    ok 2 * ($x + $y)->l  == ($x + $y)->d (-$x - $y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

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
  
    ok 4 * ($x + $y)->l2 == ($x + $y)->d2(-$x - $y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 n($o)

Return a normalized a copy of a vector.

     Parameter  Description
  1  $o         Vector

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
  
    ok (($x * 3 + $y * 4)->n == $x * 3/5 + $y * 4/5);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
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
  
    ok near -2,         ($x + $y)->area($x * 2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near +2,         ($x + $y)->area($y * 2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 cosine($o, $p)

Cos(angle between two vectors).

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
  
    ok +1 == $x->cosine($x);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok +1 == $y->cosine($y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  0 == $x->cosine($y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  0 == $y->cosine($x);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  0 == $x->sine($x);
    ok  0 == $y->sine($y);
    ok +1 == $x->sine($y);
    ok -1 == $y->sine($x);
  
    ok near -sqrt(1/2), ($x + $y)->sine($x);
    ok near +sqrt(1/2), ($x + $y)->sine($y);
    ok near -2,         ($x + $y)->area($x * 2);
    ok near +2,         ($x + $y)->area($y * 2);
  

=head2 sine($o, $p)

Sin(angle between two vectors).

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
    ok +1 == $x->cosine($x);
    ok +1 == $y->cosine($y);
    ok  0 == $x->cosine($y);
    ok  0 == $y->cosine($x);
  
  
    ok  0 == $x->sine($x);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok  0 == $y->sine($y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok +1 == $x->sine($y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok -1 == $y->sine($x);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
  
    ok near -sqrt(1/2), ($x + $y)->sine($x);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near +sqrt(1/2), ($x + $y)->sine($y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok near -2,         ($x + $y)->area($x * 2);
    ok near +2,         ($x + $y)->area($y * 2);
  

=head2 angle($o, $p)

Angle in radians anticlockwise that the first vector must be rotated to point along the second vector normalized to the range: -pi to +pi.

     Parameter  Description
  1  $o         Vector 1
  2  $p         Vector 2

B<Example:>


    my ($zero, $x, $y) = zeroAndUnits;
  
    ok near $y->angle(new(+1, -1)), deg2rad(-135);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new(+1,  0)), deg2rad(-90);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new(+1, +1)), deg2rad(-45);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new( 0, +1)), deg2rad(+0);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new(-1, +1)), deg2rad(+45);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new(-1,  0)), deg2rad(+90);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near $y->angle(new(-1, -1)), deg2rad(+135);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near new(1,1) < new( 0, -1), deg2rad(-135);
    ok near new(1,1) < new( 1, -1), deg2rad(-90);
    ok near new(1,1) < new( 1,  0), deg2rad(-45);
    ok near new(1,1) < new( 1,  1), deg2rad(0);
    ok near new(1,1) < new( 0,  1), deg2rad(+45);
    ok near new(1,1) < new(-1,  1), deg2rad(+90);
    ok near new(1,1) < new(-1,  0), deg2rad(+135);
  
    ok near deg2rad(-60),  $x + $y * sqrt(3)    <    $x;
  
    ok near deg2rad(+30), ($x + $y * sqrt(3))->angle($y);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near deg2rad(  0), $y->smallestAngleToNormalPlane( $x);                    # First vector is y, second vector is 0 degrees anti-clockwise from x axis
    ok near deg2rad(+45), $y->smallestAngleToNormalPlane( $x +  $y);              
    ok near deg2rad(+90), $y->smallestAngleToNormalPlane(       $y);              
    ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              
    ok near deg2rad(  0), $y->smallestAngleToNormalPlane(-$x);                    
    ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              
    ok near deg2rad(+90), $y->smallestAngleToNormalPlane(      -$y);              
    ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              
    ok near deg2rad(  0), $y->smallestAngleToNormalPlane( $x);                    
  
    for my $i(-179..179)
     {ok near $x < new(cos(deg2rad($i)), sin(deg2rad($i))), deg2rad($i);
     }
  

=head2 smallestAngleToNormalPlane($a, $b)

The smallest angle between the second vector and a plane normal to the first vector.

     Parameter  Description
  1  $a         Vector 1
  2  $b         Vector 2

=head2 r90($o)

Rotate a vector by 90 degrees anticlockwise.

     Parameter  Description
  1  $o         Vector to rotate

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
  
    ok $x->r90           ==  $y;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $y->r90           == -$x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $x->r90->r90      == -$x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $y->r90->r90      == -$y;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $x->r90->r90->r90 == -$y;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok $y->r90->r90->r90 ==  $x;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

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
  

=head2 rotate($p, $o, $sin, $cos)

Rotate a vector about another vector through an angle specified by its values as sin, and cos.

     Parameter  Description
  1  $p         Vector to rotate
  2  $o         Center of rotation
  3  $sin       Sin of the angle of rotation
  4  $cos       Cosine of the angle of rotation

B<Example:>


  
    ok near2 new(1, 0)->rotate(new(0,0),  1, 0), new( 0, 1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near2 new(1, 1)->rotate(new(0,0),  1, 0), new(-1, 1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near2 new(0, 1)->rotate(new(0,0),  1, 0), new(-1, 0);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near2 new(2, 2)->rotate(new(1,1),  -1/sqrt(2),   1/sqrt(2)), new(1+sqrt(2), 1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near2 new(3, 1)->rotate(new(1,1),     sqrt(3)/2, 1/2),       new(2,         1+sqrt(3));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
  
    ok near2 new(3, 1)->rotate(new(1,1),   # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

       new(1, 0)->sine  (new(1,1)), 
       new(1, 0)->cosine(new(1,1))),
       new(1+sqrt(2), 1+sqrt(2));
  

=head2 intersection($a, $b, $c, $d)

Find the intersection of two line segments delimited by vectors if such a point exists.

     Parameter  Description
  1  $a         Start of first line segment
  2  $b         End of first line segment
  3  $c         Start of second line segment
  4  $d         End of second line segment

B<Example:>


  
    ok near2 intersection(new(0,0), new(2,2),  new(0,2),new(2,0)),  new(1,1);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  
    ok near2 intersection(new(1,1), new(3,3),  new(1,3),new(3,1)),  new(2,2);  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

  

=head2 triangulate($clockwise, @boundary)

Find a set of triangles that cover a shape whose boundary points are represented by an array of vectors. The points along the boundary must be given in such away that the interior of the shape is always on the same side for each pair of successive points as indicated by the clockwise parameter.

     Parameter   Description
  1  $clockwise  If true then the interior of the shape is on the left as the boundary of the shape is traversed otherwise on the right
  2  @boundary   Vectors representing the boundary of the shape

B<Example:>


  
    my @t = triangulate(1, new(0,0), new(2,0), new(2,2), new(0,2));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    ok near2 $t[0][0], new(1, 1);
    ok near2 $t[0][1], new(0, 0);
    ok near2 $t[0][2], new(2, 0);
    
    ok near2 $t[1][0], new(1, 1);
    ok near2 $t[1][1], new(2, 0);
    ok near2 $t[1][2], new(2, 2);
    
    ok near2 $t[2][0], new(1, 1);
    ok near2 $t[2][1], new(2, 2);
    ok near2 $t[2][2], new(0, 2);
    
    ok near2 $t[3][0], new(0, 0);
    ok near2 $t[3][1], new(1, 1);
    ok near2 $t[3][2], new(0, 2);
  
  
    my @t = triangulate(0, new(2,2), new(2, 4), new(4,4), new(4, 2));  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    
    ok near2 $t[0][0], new(3, 3);
    ok near2 $t[0][1], new(2, 2);
    ok near2 $t[0][2], new(2, 4);
    
    ok near2 $t[1][0], new(3, 3);
    ok near2 $t[1][1], new(2, 4);
    ok near2 $t[1][2], new(4, 4);
    
    ok near2 $t[2][0], new(3, 3);
    ok near2 $t[2][1], new(4, 4);
    ok near2 $t[2][2], new(4, 2);
    
    ok near2 $t[3][0], new(2, 2);
    ok near2 $t[3][1], new(3, 3);
    ok near2 $t[3][2], new(4, 2);
  

=head2 swap($o)

Swap the components of a vector.

     Parameter  Description
  1  $o         Vector

B<Example:>


    my ($z, $x, $y) = zeroAndUnits;
  
    ok $x->swap == $y;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok $x->clone == $x;
  


=head1 Hash Definitions




=head2 Math::Vectors2 Definition


Attributes of a vector




=head3 Output fields


=head4 x

X coordinate

=head4 y

Y coordinate



=head1 Index


1 L<angle|/angle> - Angle in radians anticlockwise that the first vector must be rotated to point along the second vector normalized to the range: -pi to +pi.

2 L<area|/area> - Signed area of the parallelogram defined by the two vectors.

3 L<clone|/clone> - Clone a vector.

4 L<cosine|/cosine> - Cos(angle between two vectors).

5 L<d|/d> - Distance between the points identified by two vectors when placed on the same point.

6 L<d2|/d2> - Distance squared between the points identified by two vectors when placed on the same point.

7 L<Divide|/Divide> - Divide a vector by a scalar and return the result.

8 L<divide|/divide> - Divide a copy of a vector by a scalar and return the result.

9 L<dot|/dot> - Dot product of two vectors.

10 L<eq|/eq> - Whether two vectors are equal to within the accuracy of floating point arithmetic.

11 L<intersection|/intersection> - Find the intersection of two line segments delimited by vectors if such a point exists.

12 L<l|/l> - Length of a vector.

13 L<l2|/l2> - Length squared of a vector.

14 L<Minus|/Minus> - Subtract zero or more vectors from the first vector and return the result.

15 L<minus|/minus> - Subtract zero or more vectors from a copy of the first vector and return the result.

16 L<multiply|/multiply> - Multiply a copy of a vector by a scalar and return the result.

17 L<Multiply|/Multiply> - Multiply a vector by a scalar and return the result.

18 L<n|/n> - Return a normalized a copy of a vector.

19 L<new|/new> - Create new vector from components.

20 L<plus|/plus> - Add zero or more other vectors to a copy of the first vector and return the result.

21 L<Plus|/Plus> - Add zero or more other vectors to the first vector and return the result.

22 L<print|/print> - Print one or more vectors.

23 L<r180|/r180> - Rotate a vector by 180 degrees.

24 L<r270|/r270> - Rotate a vector by 270 degrees anticlockwise.

25 L<r90|/r90> - Rotate a vector by 90 degrees anticlockwise.

26 L<rotate|/rotate> - Rotate a vector about another vector through an angle specified by its values as sin, and cos.

27 L<sine|/sine> - Sin(angle between two vectors).

28 L<smallestAngleToNormalPlane|/smallestAngleToNormalPlane> - The smallest angle between the second vector and a plane normal to the first vector.

29 L<swap|/swap> - Swap the components of a vector.

30 L<triangulate|/triangulate> - Find a set of triangles that cover a shape whose boundary points are represented by an array of vectors.

31 L<zero|/zero> - Whether a vector is equal to zero within the accuracy of floating point arithmetic.

32 L<zeroAndUnits|/zeroAndUnits> - Create the useful vectors: zero=(0,0), x=(1,0), y=(0,1).

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Math::Vectors2

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2023 Philip R Brenan.

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
#__DATA__
use Test::More tests => 465;

eval "goto latest";

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
  ok near deg2rad(+45), $y->smallestAngleToNormalPlane( $x +  $y);              
  ok near deg2rad(+90), $y->smallestAngleToNormalPlane(       $y);              
  ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              
  ok near deg2rad(  0), $y->smallestAngleToNormalPlane(-$x);                    
  ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              
  ok near deg2rad(+90), $y->smallestAngleToNormalPlane(      -$y);              
  ok near deg2rad(+45), $y->smallestAngleToNormalPlane(-$x + -$y);              
  ok near deg2rad(  0), $y->smallestAngleToNormalPlane( $x);                    

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

#latest:;
if (1) {                                                                        #Trotate
  ok near2 new(1, 0)->rotate(new(0,0),  1, 0), new( 0, 1);
  ok near2 new(1, 1)->rotate(new(0,0),  1, 0), new(-1, 1);
  ok near2 new(0, 1)->rotate(new(0,0),  1, 0), new(-1, 0);
  ok near2 new(2, 2)->rotate(new(1,1),  -1/sqrt(2),   1/sqrt(2)), new(1+sqrt(2), 1);
  ok near2 new(3, 1)->rotate(new(1,1),     sqrt(3)/2, 1/2),       new(2,         1+sqrt(3));

  ok near2 new(3, 1)->rotate(new(1,1), 
     new(1, 0)->sine  (new(1,1)), 
     new(1, 0)->cosine(new(1,1))),
     new(1+sqrt(2), 1+sqrt(2));
 }

#latest:;
if (1) {                                                                        #Tintersection
  ok near2 intersection(new(0,0), new(2,2),  new(0,2),new(2,0)),  new(1,1);
  ok near2 intersection(new(1,1), new(3,3),  new(1,3),new(3,1)),  new(2,2);
 }

#latest:;
if (1) {                                                                        #Ttriangulate
  my @t = triangulate(1, new(0,0), new(2,0), new(2,2), new(0,2));
  
  ok near2 $t[0][0], new(1, 1);
  ok near2 $t[0][1], new(0, 0);
  ok near2 $t[0][2], new(2, 0);
  
  ok near2 $t[1][0], new(1, 1);
  ok near2 $t[1][1], new(2, 0);
  ok near2 $t[1][2], new(2, 2);
  
  ok near2 $t[2][0], new(1, 1);
  ok near2 $t[2][1], new(2, 2);
  ok near2 $t[2][2], new(0, 2);
  
  ok near2 $t[3][0], new(0, 0);
  ok near2 $t[3][1], new(1, 1);
  ok near2 $t[3][2], new(0, 2);
 }

#latest:;
if (1) {                                                                        #Ttriangulate
  my @t = triangulate(0, new(2,2), new(2, 4), new(4,4), new(4, 2));
  
  ok near2 $t[0][0], new(3, 3);
  ok near2 $t[0][1], new(2, 2);
  ok near2 $t[0][2], new(2, 4);
  
  ok near2 $t[1][0], new(3, 3);
  ok near2 $t[1][1], new(2, 4);
  ok near2 $t[1][2], new(4, 4);
  
  ok near2 $t[2][0], new(3, 3);
  ok near2 $t[2][1], new(4, 4);
  ok near2 $t[2][2], new(4, 2);
  
  ok near2 $t[3][0], new(2, 2);
  ok near2 $t[3][1], new(3, 3);
  ok near2 $t[3][2], new(4, 2);
 }
