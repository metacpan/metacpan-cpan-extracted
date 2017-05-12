
###############################################################################
#   Package Math::Vector                                                      #
#   Copyright 2003, Wayne M. Syvinski, MS                                     #
#                                                                             #
#   If you use this software, you agree to the following:                     #
#   (1) You agree to hold harmless, and waive any claims against, the author. #
#   (2) You agree that there is no warranty, express or implied, for this     #
#       software whatsoever.                                                  #
#   (3) You will abide by the GNU General Public License or the Artistic      #
#       License in the use of this software.                                  #
#   (4) You agree not to modify this notice.                                  #
#                                                                             #
#   If you use this software and find it useful, I would appreciate an e-mail #
#   note to wsyvinski@techcelsior.com                                         #
###############################################################################

package Math::Vector;

require 5.005_64;

use strict;
use Math::Complex;
use Math::Vector;

our $VERSION = 1.03;

my $v = Math::Vector->new();

sub new 
{
    return bless {};
};

sub DotProduct
#returns the dot product of a vector
{
    shift @_;
    my ($x1,$y1,$z1,$x2,$y2,$z2) = @_[0..5];
    return ($x1*$x2)+($y1*$y2)+($z1*$z2);
}

sub CrossProduct
#returns the cross product of two vectors - ORDER MATTERS!!!!!
{
    my ($x,$y,$z);
    shift @_;
    my ($a1,$a2,$a3,$b1,$b2,$b3) = @_[0..5];
    $x = (($a2*$b3) - ($a3*$b2));
    $y = (($a3*$b1) - ($a1*$b3));
    $z = (($a1*$b2) - ($a2*$b1));
    return ($x,$y,$z);
}

sub Magnitude
#returns the magnitude of a vector
{
    shift @_;
    my ($x,$y,$z) = @_[0..2];
    return (($x*$x)+($y*$y)+($z*$z))**(0.5)
}

sub UnitVector
#determines the unit vector for a given vector
{
    shift @_;
    my ($x,$y,$z) = @_[0..2];
    my $mag = $v->Magnitude($x,$y,$z);
    return ($x/$mag,$y/$mag,$z/$mag);
}

sub ScalarMult
#scalar multiplication of vectors
{
    shift @_;
    my ($scmult,$x,$y,$z) = @_[0..3];
    return ($scmult*$x,$scmult*$y,$scmult*$z);
}

sub VecSub
#subtracts vector b from vector a
{
    shift @_;
    my ($a1,$a2,$a3,$b1,$b2,$b3) = @_[0..5];
    return ($a1-$b1,$a2-$b2,$a3-$b3);
}

sub InnerAngle
#determines the acute angle lying in the plane defined by two vectors that meet at a point
#or are parallel/coincident
{
    shift @_;
    my $dp = $v->DotProduct(@_[0..5]);
    my $maga = $v->Magnitude(@_[0..2]);
    my $magb = $v->Magnitude(@_[3..5]);
    return acos($dp/($maga*$magb));
}

sub DirAngles
#determines the direction angles of a vector
{
    shift @_;
    my ($x,$y,$z) = $v->UnitVector(@_[0..2]);
    return (acos($x),acos($y),acos($z));
}

sub VecAdd
#add an arbitrary number of vectors
{
    shift @_;
    my @vecsum = ();
    my $ae = scalar(@_);
    for (my $i = 0 ; $i <= $ae ; $i += 3)
    {
        $vecsum[0] += $_[$i];
        $vecsum[1] += $_[$i+1];
        $vecsum[2] += $_[$i+2];
    }
    return @vecsum;
}

sub UnitVectorPoints
#takes two points (x1,y1,z1) and (x2,y2,z2) and determines the unit vector from the first point to the second
{
    shift @_;
    return $v->UnitVector($v->VecSub(@_[3..5],@_[0..2]));

}

sub InnerAnglePoints
#takes 3 ordered triples; 2nd ordered triple is the vertex of the angle
{
    shift @_;
    my ($x1,$y1,$z1,$x0,$y0,$z0,$x2,$y2,$z2) = @_[0..8];
    return $v->InnerAngle($v->UnitVecPoints($x0,$y0,$z0,$x1,$y1,$z1),$v->UnitVecPoints($x0,$y0,$z0,$x2,$y2,$z2));
}

sub PlaneUnitNormal
#takes three points (three points in space define plane) and returns a unit normal vector for the plane
{
    shift @_;
    my ($x1,$y1,$z1,$x0,$y0,$z0,$x2,$y2,$z2) = @_[0..8];
    return $v->UnitVector($v->CrossProduct(($x1-$x0,$y1-$y0,$z1-$z0),($x2-$x0,$y2-$y0,$z2-$z0)));
}

sub TriAreaPoints
#returns the triangular area defined by three points
{
    shift @_;
    my ($x1,$y1,$z1,$x0,$y0,$z0,$x2,$y2,$z2) = @_[0..8];
    return ($v->Magnitude($v->CrossProduct(($x1-$x0,$y1-$y0,$z1-$z0),($x2-$x0,$y2-$y0,$z2-$z0)))/2.0);
}

sub TriAreaLengths
#returns the area of a triangle defined by lengths of its sides
{
    shift @_;
    my ($a,$b,$c) = @_[0..2];
    my $theta = acos((($c*$c) - ($a*$a) - ($b*$b)) / ((-2.0) * $a * $b));
    return $a*$b*sin($theta)*0.5;
}

sub TripleProduct
#returns vector triple product, which is a scalar calculated using the determinant of the orthogonal
#component magnitudes
{
    shift @_;
    my ($x0,$y0,$z0,$x1,$y1,$z1,$x2,$y2,$z2) = @_[0..8];
    return ($x0*(($y1*$z2) - ($z1*$y2))) - ($y0*(($x1*$z2) - ($z1*$x2))) + ($z0*(($x1*$y2) - ($y1*$x2)));
}

sub IJK
#returns a string representation of a vector in ijk format from an array or list
{
    shift @_;
    my $vec = qq/$_[0]i+$_[1]j+$_[2]k/;
    $vec =~ s|\+\-|\-|g;
    return $vec
}

sub OrdTrip
#returns an ordered triple of a vector in ijk format from an array or list
{
    shift @_;
    return qq/<$_[0],$_[1],$_[2]>/;
}

sub STV
#returns an array of vector components from an ijk or ordered triple string representation
#of a vector
{   
    shift @_;
    my $vs = $_[0];
    $vs =~ s/(<|>)//g;
    $vs =~ s/k//;
    $vs =~ s/[ij]/,/g;
    $vs =~ s/\+//g;
    return split ',',$vs;
}

sub Equil
#given a set of vectors, return the vector that bring the set into equilibrium
{
    shift @_;
    my $ae = scalar(@_);
    my @resvecs = ();
    my ($s,$x,$y,$z);
    for (my $i = 0 ; $i <= ($ae-1) ; $i += 4)
    {
        ($s,$x,$y,$z) = @_[($i)..($i+3)];
        push @resvecs, $v->ScalarMult($s,$v->UnitVector($x,$y,$z));
    }
    return $v->ScalarMult(-1.0,$v->VecAdd(@resvecs));
}

1;

=head1 NAME

Math::Vector - package containing functions for vector mathematics and associated operations

=head1 AUTHOR

Wayne M. Syvinski, MS <syvinski@techcelsior.com>

=head1 COPYRIGHT NOTICE

Copyright 2003 Wayne M. Syvinski

=head1 WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is offered with this software.  You use this software at your own risk.  In case of loss, neither Wayne M. Syvinski, nor anyone else, owes you anything whatseover.  You have been warned.

=head1 LICENSE

You may use this software under one of the following licenses:

(1) GNU General Public License (can be found at http://www.gnu.org/copyleft/gpl.html)
(2) Artistic License (can be found at http://www.perl.com/pub/language/misc/Artistic.html)

=head1 GENERAL INFORMATION

This module was developed using ActivePerl build 618, version 5.6.0, under Windows 2000 Professional.  It needs to be placed in the /Math (or \Math, in Win32) directory of your Perl libraries.

This module was written entirely in Perl, with dependency on Math::Complex for the arccosine function, and possible future enhancements.

=head1 USAGE

use Math::Vector;

$v = Math::Vector->new();

In concert with the concept of TMTOWTDI, you may pass arguments to methods as lists of scalars in scalar context, lists of scalars in list context, or arrays.  Function prototypes are therefore not used.  When using this module, you should generally represent vectors as three-membered arrays of real numbers (i.e. ordered triples).

Example:  method UnitVector takes a single vector as an argument.  Using the initialization above, you could call the method in the following ways.

(way #1)

my ($x,$y,$z) = (1,2,3);

my $uv = $v->UnitVector($x,$y,$z);

(way #2)

my (@vector) = (1,2,3);

my $uv = $v->UnitVector(@vector);

It is important to note that if a method takes 3 scalar (in the Perl sense) arguments, and you pass an array containing four scalar entities, the fourth entity is ignored.  In other words, extra arguments take a trip to the Twilight Zone.  However, if a method can accept two or more vectors, and one is 4-dimensional, you will get results you were guaranteed not to expect!  The onus is on the user to keep track of how may dimensions are passed with arrays (you may wish to use array slices to ensure the proper number of values are passed in an array).

PLEASE NOTE:  All calculations are performed in Cartesian (rectilinear) coordinates.  No facility is provided for direct computation with vectors using spherical, cylindrical, or other non-orthogonal coordinate systems.  

To perform vector mathematics using spherical or cylindrical coordinate systems, you can use the follwing functions from module Math::Trig (the following were taken from the POD documentation in Math::Trig):

cartesian_to_cylindrical($rho, $theta, $z) = cartesian_to_cylindrical($x, $y, $z);

cartesian_to_spherical($rho, $theta, $phi) = cartesian_to_spherical($x, $y, $z);

cylindrical_to_cartesian($x, $y, $z) = cylindrical_to_cartesian($rho, $theta, $z);

cylindrical_to_spherical($rho_s, $theta, $phi) = cylindrical_to_spherical($rho_c, $theta, $z);
Notice that when C<$z> is not 0 C<$rho_s> is not equal to C<$rho_c>.

spherical_to_cartesian($x, $y, $z) = spherical_to_cartesian($rho, $theta, $phi);

spherical_to_cylindrical($rho_c, $theta, $z) = spherical_to_cylindrical($rho_s, $theta, $phi);
Notice that when C<$z> is not 0 C<$rho_c> is not equal to C<$rho_s>.

=head1 DESCRIPTION

This package facilitates the mathematical manipulation of 3-dimensional vector quantities.  Two-dimensional vectors are supported only by setting one of the orthogonal components to 0, and n-D vectors where n > 3 are not supported.

Given the limitation to 2- and 3-dimensional vectors, this is a package suited to applications for Euclidean geometry and engineering.  Again...no warranty, express or implied, exists for this software.  USE AT YOUR OWN RISK!!!

People using this module are assumed to know basic vector mathematics and trigonometry, so the theory behind the methods will not be explained.

=head1 METHOD DESCRIPTIONS AND USE

=head2 Magnitude

usage:      $scalar_result = $v->Magnitude($x,$y,$z);

            or 

            my @vec1 = ($x,$y,$z);
            $scalar_result = $v->Magnitude(@vec1);

Returns the magnitude (length, absolute value) of a vector, which is a mathematical scalar.

=head2 ScalarMult

usage:  @vector_result = $v->ScalarMult($sc,$x,$y,$z);

            or
        
            my $sc; #this is a mathematical scalar quantity
            my @vec1 = ($x,$y$z);
            @vector_result = $v->ScalarMult($sc,@vec1); 

Returns a vector which is the result of multiplying a vector by a mathematical scalar.  Note that the first value passed to the method is the mathematical scalar quantity by which the vector is multiplied.

=head2 DotProduct

usage:  $scalar_result = $v->DotProduct($x1,$y1,$z1,$x2,$y2,$z2);

            or
    
            my @vec1 = ($x1,$y1,$z1);
            my @vec2 = ($x2,$y2,$z2);
            $scalar_result = $v->DotProduct(@vec1,@vec2);

Returns the dot (inner) product of two vectors.  

=head2 CrossProduct

usage:  @vector_result = $v->CrossProduct($x1,$y1,$z1,$x2,$y2,$z2);

            or
    
            my @vec1 = ($x1,$y1,$z1);
            my @vec2 = ($x2,$y2,$z2);
            @vector_result = $v->CrossProduct(@vec1,@vec2);

Returns the cross (outer) product of two vectors.  Remember, ORDER MATTERS (Cross-multiplication of vectors is not commutative!!!!!).  The first vector comes first, then the second, such that the first vector is cross-multiplied into the second.

=head2 UnitVector

usage:      @vector_result = $v->UnitVector($x,$y,$z);

            or 

            my @vec1 = ($x,$y,$z);
            @vector_result = $v->UnitVector(@vec1);

Returns the unit vector (magnitude = 1) that lies in the same direction as the parent vector.

=head2 UnitVectorPoints

usage:  @vector_result = $v->UnitVectorPoints($xA,$yA,$zA,$xA,$yA,$zA);

            or
        
            my @pointA = ($xA,$yA,$zA);
            my @pointB = ($xB,$yB,$zB);
            @vector_result = $v->UnitVectorPoints(@pointA,@pointB);

Returns the unit vector defined by two points; the direction of the vector is from A to B.

=head2 VecAdd

usage:  @vector_result = $v->VecAdd($x1,$y1,$z1,...$xN,$yN,$zN);

            or
    
            @vector_result = $v->VecAdd(@vec1,@vec2,...@vecN);

Returns the sum of an arbitrary number of vectors.  This method accepts an arbitrary number of values.  However, if the number of values passed is not a multiple of 3, the 'last array' that contains fewer than three values will, for the user's intents and purposes, have 0s 'push'ed onto the end in order to make it an ordered triple.  (This doesn't really happen in code, but the method acts as if it does).

=head2 VecSub

usage:  @vector_result = $v->VecSub($x1,$y1,$z1,$x2,$y2,$z2);

            or

            my @vec1 = ($x1,$y1,$z1);
            my @vec2 = ($x2,$y2,$z2);
            @vector_result = (@vec1,@vec2);

Returns the difference of two vectors.  The second vector is subtracted from the first (@vec1 - @vec2, if you will).

=head2 InnerAngle

usage:  $scalar_result = $v->InnerAngle($x1,$y1,$z1,$x2,$y2,$z2);

            or

            my @vec1 = ($x1,$y1,$z1);
            my @vec2 = ($x2,$y2,$z2);
            $scalar_result = $v->InnerAngle(@vec1,@vec2);

Returns the acute angle between two vectors defined by the smallest angle between vectors while lying in a common plane.  The angle is returned in radians.  Use the Math::Trig module or an identity function to obtain angles in units other than radians.

=head2 InnerAnglePoints

usage       $scalar_result = $v->InnerAnglePoints($pxA,$pyA,$pyA,$pxB,$pyB,$pzB,$pxC,$pyC,$pzC);

            or 

            my @pointA = ($pxA,$pyA,$pzA);
            my @pointB = ($pxB,$pyB,$pzB);
            my @pointC = ($pxC,$pyC,$pzC);
            $scalar_result = $v->InnerAnglePoints(@pointA,@pointB,@pointC);

Returns the acute angle ABC (B is the vertex) given three points A, B, and C lying in the same plane.

=head2 DirAngles

usage       @array_result = $v->DirAngles($x,$y,$z);

            or

            my @vec = ($x,$y,$z);
            @array_result = $v->DirAngles(@vec);

Returns the direction angles of a vector with its tail at the origin.  Note that this method returns an array containing angles in radians - NOT A VECTOR!!!!!

=head2 PlaneUnitNormal

usage       @vector_result = $v->PlaneUnitNormal($pxA,$pyA,$pzA,$pxB,$pyB,$pzB,$pxC,$pyC,$pzC);

            or

            my @pointA = ($pxA,$pyA,$pzA);
            my @pointB = ($pxB,$pyB,$pzB);
            my @pointC = ($pxC,$pyC,$pzC);
            @vector_result = $v->PlaneUnitNormal(@pointA,@pointB,@pointC);

Returns a unit normal defining the plane based on three points in space.

To return a unit normal for a plane defined by two vectors, use the following code:

@vector_result = $v->UnitVector($v->CrossProduct(@vec1,@vec2));

=head2 TriAreaPoints

usage       $scalar_result = $v->TriAreaPoints($pxA,$pyA,$pzA,$pxB,$pyB,$pzB,$pxC,$pyC,$pzC);

            or

            my @pointA = ($pxA,$pyA,$pzA);
            my @pointB = ($pxB,$pyB,$pzB);
            my @pointC = ($pxC,$pyC,$pzC);
            $scalar_result = $v->TriAreaPoints(@pointA,@pointB,@pointC);            


Returns the area of a triangle defined by three points, which define the vertices of the triangle.

=head2 TriAreaLengths

usage       $scalar_result = $v->TriAreaLengths($lengthA,$lengthB,$lengthC);

            or

            my @generic_array = ($lengthA,$lengthB,$lengthC);
            $scalar_result = $v->TriAreaLengths(@generic_array);

Returns the area of a triangle using the lengths of the three sides.

=head2 TripleProduct

usage   $scalar_result = $v->TripleProduct($x1,$y1,$z1,$x2,$y2,$z2,$x3,$y3,$z3);
            
            or

            my @vec1 = ($x1,$y1,$z1);
            my @vec2 = ($x2,$y2,$z2);
            my @vec3 = ($x3,$y3,$z3);
            $scalar_result = $v->TripleProduct(@vec1,@vec2,@vec3);

Returns the scalar triple product of three vectors.  It is defined by the following determinant.

|$x1 $y1 $z1|
|$x2 $y2 $z2|
|$x3 $y3 $z3|

=head2 IJK

usage       $string = $v->IJK($i,$j,$k);

            or
        
            my @vec = ($i,$j,$k);
            $string = $v->IJK(@vec);

Converts the array or list-context representation of a vector into the string form 'ai+bj+ck'.

Example:

my @vec = (2,-5,6);
my $vecstring = $v->IJK(@vec);

#method IJK returns '2i-5j+6k' to scalar variable $vecstring

=head2 OrdTrip

usage       $string = $v->OrdTrip($i,$j,$k);

            or
    
            my @vec = ($i,$j,$k);
            $string = $v->OrdTrip(@vec);            

Converts the array or list-context representation of a vector into the string form '<i,j,k>' (ordered triple).

Example:

my @vec = (2,-5,6);
my $vecstring = $v->OrdTrip(@vec);

#method IJK returns '<2,-5,6>' to scalar variable $vecstring


=head2 STV ("String To Vector")

usage       @vector_result = $v->STV('2i-5j+6k');

            or

            @vector_result = $v->STV('<2,-5,6>');

Converts a vector represented as a string in either ijk or ordered triple format into its array representation.  Argument may be a scalar variable or a string literal.

=head2 Equil

usage       @vector_result = $v->Equil($s1,$x1,$y1,$z1,...$sN,$xN,$yN,$zN);

            or
        
            my ($s1,...$sN);
            my ($x1,$y1,$z1,...$xN,$yN,$zN);
            my (@vec1,...@vecN);

            @vec1 = ($x1,$y1,$z1);
            .
            .
            .
            @vecN = ($xN,$yN,$zN);
            @vector_result = $v->Equil($s1,@vec1,...$sN,@vecN);

Returns the vector necessary to bring a group of vectors into mechanical equilibrium.  This function can accept an arbitrary number of arguments, but the arguments need to be passed in groups of four, in order.  The order is scalar multiplier, x-component, y-component, z-component.

Example:

First vector:  1000 N along 3i+4j-7k
Second vector:  1300 N along -5i-7j+k

No magnitude information is carried by the directional vectors.  Find the vector that brings these into mechanical equilibrium.

@vector_result = $v->Equil(1000,3,4,-7,1300,-5,-7,1);

(The answer is approximately (401.8i + 585.8j + 663.6k) N, or 972.1(0.413i + 0.602j + 0.683k) N )

[END OF EXAMPLE]

The method first calculates the unit vector for the vector given, then performs scalar multiplication.  IMPORTANT:  NO MAGNITUDE INFORMATION IS DERIVED FROM THE VECTOR.
    
If you have a combination of a scalar multiplier and vectors with magnitude information you want to use, you will have to use one of the following constructs.

@vector_result = $v->Equil($s*$v->Magnitude(@vec),@vec);
@vector_result = $v->Equil(1,$v->ScalarMult($s,@vec)); #I recommend this one, but YMMV.

If you want to return a magnitude and a unit vector as a result, you will have to do it in two steps, using the method calls available ( $v->Magnitude() and $v->UnitVector() )

If you want to determine if a set of vectors are already in equilibrium, you can use this function.  You just need to check if the zero vector (or its computer floating-point approximation) was returned.

=cut

#eof
