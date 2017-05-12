#
# Filename        : Math/Geometry.pm
# Description     : General Geometry maths functions
# Author          : Greg McCarroll (greg@mccarroll.org.uk)
# Date Created    : 22/10/99
#

=head1 NAME

Math::Geometry - Geometry related functions

=head1 SYNOPSIS

        use Math::Geometry;

        @P2=rotx(@P1,$angle);
        @P3=rotx(@P1,$angle);
        @N =triangle_normal(@P1,@P2,@P3);
        @ZP=zplane_project(@P1,$d);


=head1 NOTES

This is about to get a massive overhaul, but first im adding tests,
lots of lovely lovely tests.

Currently for zplane_project onto a plane with normal of the z axis and z=0,
the function returns the orthographic projections as opposed to a perspective
projection. I'm currently looking into how to properly handle z=0 and will
update it shortly.

=head1 DESCRIPTION

This package implements classic geometry methods. It should be considered alpha
software and any feedback at all is greatly appreciated. The following methods
are available:

=head2 vector_product.

Also known as the cross product, given two vectors in Geometry space, the
vector_product of the two vectors, is a vector which is perpendicular
to the plane of AB with length equal to the length of A multiplied
by the length of B, multiplied by the sin of @, where @ is the angle
between the two vectors.

=head2 triangle_normal

Given a triangle ABC that defines a plane P. This function will return
a vector N, which is a normal to the plane P.

    ($Nx,$Ny,$Nz) =
       triangle_normal(($Ax,$Ay,$Az),($Bx,$By,$Bz),($Cx,$Cy,$Cz));

=head2 zplane_project

Project a point in Geometry space onto a plane with the z-axis as the normal,
at a distance d from z=0.

    ($x2,$y2,$z2) = zplane_project ($x1,$y1,$z1,$d);

=head2 rotx

Rotate about the x axis r radians.

    ($x2,$y2,$z2) = rotx ($x1,$y1,$z1,$r);

=head2 roty

Rotate about the y axis r radians.

    ($x2,$y2,$z2) = roty ($x1,$y1,$z1,$r);

=head2 rotz

Rotate about the z axis r radians.

    ($x2,$y2,$z2) = rotz ($x1,$y1,$z1,$r);

=head2 deg2rad

Convert degree's to radians.

=head2 rad2deg

Convert radians to degree's.

=head2 pi

Returns an approximate value of Pi, the code has been cribed from Pg146, Programming Perl
2nd Ed.

=head1 EXAMPLE

    use Math::Geometry;

=head1 AUTHOR

    Greg McCarroll <greg@mccarroll.org.uk> 
    - http://www.mccarroll.org.uk/~gem/

=head1 COPYRIGHT

Copyright 2006 by Greg McCarroll <greg@mccarroll.org.uk>

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

package Math::Geometry;

use strict;
use warnings;

require Exporter;
our @ISA='Exporter';
our @EXPORT = qw/zplane_project triangle_normal rotx roty rotz rad2deg deg2rad pi/;

use Math::Matrix;

our $VERSION='0.04';

sub version {
    return "Math::Geometry $VERSION";
}


sub vector_product  {
    my($a,$b,$c,$d,$e,$f)=@_;
    return($b*$f-$c*$e,$c*$d-$a*$f,$a*$e-$b*$d);
}

sub triangle_normal {
    my(($ax,$ay,$az),($bx,$by,$bz),($cx,$cy,$cz))=@_;
    my(@AB)=($bx-$ax,$by-$ay,$bz-$az);
    my(@AC)=($cx-$ax,$cy-$ay,$cz-$az);
    return(vector_product(@AB,@AC));
}

sub zplane_project {
    my($x,$y,$z,$d)=@_;
    my($w);
    my($xp,$yp,$zp);
    if ($d == 0) {
        my($trans)=new Math::Matrix ([       1,       0,       0,       0],
                                     [       0,       1,       0,       0],
                                     [       0,       0,       0,       0],
                                     [       0,       0,       0,       1]);
        my($orig) =new Math::Matrix ([      $x],
                                     [      $y],
                                     [      $z],
                                     [       1]);
        my($prod) =$trans->multiply($orig);
        $x=$prod->[0][0];
        $y=$prod->[1][0];
        $z=$prod->[2][0];
        $w=$prod->[3][0];
    } else {
        my($trans)=new Math::Matrix ([       1,       0,       0,       0],
                                     [       0,       1,       0,       0],
                                     [       0,       0,       1,       0],
                                     [       0,       0,     1/$d,      0]);
        my($orig) =new Math::Matrix ([      $x],
                                     [      $y],
                                     [      $z],
                                     [       1]);
        my($prod) =$trans->multiply($orig);
        $x=$prod->[0][0];
        $y=$prod->[1][0];
        $z=$prod->[2][0];
        $w=$prod->[3][0];
        $x=$x/$w;
        $y=$y/$w;
        $z=$z/$w;
    }
    return ($x,$y,$z);
}


sub rotx {
    my($x,$y,$z,$rot)=@_;
    my($cosr)=cos $rot;
    my($sinr)=sin $rot;
    my($trans)=new Math::Matrix ([       1,       0,       0,       0],
                                 [       0,   $cosr,-1*$sinr,       0],
                                 [       0,   $sinr,   $cosr,       0],
                                 [       0,       0,       0,       1]);

    my($orig) =new Math::Matrix ([      $x],
                                 [      $y],
                                 [      $z],
                                 [       1]);

    my($prod) =$trans->multiply($orig);
    $x=$prod->[0][0];
    $y=$prod->[1][0];
    $z=$prod->[2][0];
    return ($x,$y,$z);
}

sub roty {
    my($x,$y,$z,$rot)=@_;
    my($cosr)=cos $rot;
    my($sinr)=sin $rot;
    my($trans)=new Math::Matrix ([   $cosr,       0,   $sinr,       0],
                                 [       0,       1,       0,       0],
                                 [-1*$sinr,       0,   $cosr,       0],
                                 [       0,       0,       0,       1]);

    my($orig) =new Math::Matrix ([      $x],
                                 [      $y],
                                 [      $z],
                                 [       1]);

    my($prod) =$trans->multiply($orig);
    $x=$prod->[0][0];
    $y=$prod->[1][0];
    $z=$prod->[2][0];
    return ($x,$y,$z);
}

sub rotz {
    my($x,$y,$z,$rot)=@_;
    my($cosr)=cos $rot;
    my($sinr)=sin $rot;
    my($trans)=new Math::Matrix ([   $cosr,-1*$sinr,       0,       0],
                                 [   $sinr,   $cosr,       0,       0],
                                 [       0,       0,       1,       0],
                                 [       0,       0,       0,       1]);

    my($orig) =new Math::Matrix ([      $x],
                                 [      $y],
                                 [      $z],
                                 [       1]);

    my($prod) =$trans->multiply($orig);
    $x=$prod->[0][0];
    $y=$prod->[1][0];
    $z=$prod->[2][0];
    return ($x,$y,$z);
}


sub deg2rad ($) {
    my($deg)=@_;
    return ($deg*pi())/180;
}

sub rad2deg ($) {
    my($rad)=@_;
    return ($rad*180)/pi();
}
{
    my($PI);
    sub pi() {
        $PI ||= atan2(1,1)*4;
        return $PI;
    }
}

1;










