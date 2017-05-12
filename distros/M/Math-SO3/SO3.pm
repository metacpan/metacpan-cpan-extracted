package Math::SO3;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.90';

bootstrap Math::SO3 $VERSION;

# Preloaded methods go here.

sub format_matrix
  {
    my($self, $how)=@_;
    my(@elems);

    $how="%10.5f" unless defined($how);

    @elems=unpack "d9", $$self;

    sprintf "[[$how $how $how] [$how $how $how] [$how $how $how]]", @elems;
  }

sub format_eigenvector
  {
    my($self, $how)=@_;
    my($angle, $dir_str, @dir);

    $how="%10.5f" unless defined($how);

    ($angle, $dir_str)=$self->turning_angle_and_dir("d");
    
    if(defined($angle))
      {
	@dir=unpack "d3", $dir_str;
	sprintf "<rotate $how deg round [$how $how $how]>", 
	        $angle, @dir;
      }
    else
      {
	"<NO ROTATION>";
      }
  }

sub format_euler_zxz
  {
    my($self, $how)=@_;
    my($phi, $theta, $psi);

    $how="%10.5f" unless defined($how);

    ($phi, $theta, $psi)=$self->euler_angles_zxz('d');
    
    sprintf "<D_z(psi=$how deg) D_x(theta=$how deg) D_z(phi=$how deg)>",
    $psi, $theta, $phi;
  }


sub format_euler_yxz
  {
    my($self, $how)=@_;
    my($heading, $pitch, $roll);

    $how="%10.5f" unless defined($how);

    ($heading, $pitch, $roll)=$self->euler_angles_yxz('d');
    
    sprintf "<D_z(heading=$how deg) D_x(pitch=$how deg) D_y(roll=$how deg)>",
    $heading, $pitch, $roll;
  }


sub new
  {
    my($class, @args)=@_;
    my($so3, $x);

    if($x=ref $class)
      {
	$so3=\ ($$class.''); # copy-constructor
	$class=$x;
      }
    else
      {
	$so3=\ (pack "d9", 1,0,0, 0,1,0, 0,0,1);
      }
    $|=1;
    bless $so3, $class;
    $so3->turn(@args);
    $so3;
  }



# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Math::SO3 - Perl extension for SO3 rotations

(Useful for: implementing orientation in 3d scenes. One
major nice feature of this package is to prevent numerical
drift that makes rotation matrices nonorthogonal when
combining lots of them. And no, this is a direct
implementation, of SO3 it does not use quaternions and
SU2->SO3 homomorphism.)

=head1 SYNOPSIS

  use Math::SO3;

  $rotation=Math::SO3->new("zr" => 3.14159/2, 
			   "xr" => 3.14159/4, 
			   "zr" => 3.14159/8);

  $rotation=Math::SO3->new("zd" => 90, 
			   "xd" => 90, 
			   "zr" => 3.14159/6);

  $rotation->invert();

  $rotation->turn("zr" => 3.14159/2, "xr" => 3.14159/4);

  $rotation->turn_round_axis((pack "d3", 1,1,1), 30, "degrees");

  $rotation->combine($rotation_after);

  $rotation->translate_vectors($vec1, $vec2, 
                               $vec3, $vec4, @more_vectors);

  $rotation->inv_translate_vectors($vec1, $vec2, $vec3, 
				   $vec4, @more_vectors);

  ($angle, $dir)=$rotation->turning_angle_and_dir("d");

  ($phi, $theta, $psi)=$rotation->euler_angles_zxz("d");

  ($heading, $pitch, $roll)=$rotation->euler_angles_yxz("d");

  $rotation->format_matrix();
  $rotation->format_matrix("%16.8f");

  $rotation->format_eigenvector();
  $rotation->format_eigenvector("%16.8f");

  $rotation->format_euler_zxz();
  $rotation->format_euler_zxz("%16.8f");

  $rotation->format_euler_yxz();
  $rotation->format_euler_yxz("%16.8f");


=head1 DESCRIPTION

  Internal representation: SO3s are blessed refs to strings
  of size 3*3*sizeof(double) which contain the rotation
  matrix elements in standard C order. THIS IS PART OF THE
  OFFICIAL INTERFACE, so you may use this information, if
  you want. (It simply doesn't make much sense to 
  inherit from purely mathematical data types like this one,
  so this doesn't hurt.)

  Note: whenever the text below says "d" is used for angles
  in degrees, any string starting with a lowercase "d" will
  work. Same goes for "r" for rad. If you entirely leave it
  away, default is "r". So you have much freedom in choosing
  those terms which are most descriptive and most readable.

  Note: some textbooks on Mechanics (like the very good and
  very influential one by Goldstein) follow the convention

  (e1')    (   ) (e1)
  (e2')  = ( M ) (e2)
  (e3')    (   ) (e3)

  This is not very fortunate, since it introduces some nasty
  ambiguity: it's easy to misinterpret the "vector-rotation
  matrix" M as the coefficient-rotation matrix, which,
  however, is just M^T.

  Matrix/vector calculus is exploited best if one agrees to
  write coefficient vectors as column vectors and the "array
  of base vectors" as a row vector (e1 e2 e3). Just look here:

                                     (a1)
  a1*e1 + a2*e2 + a3*e3 = (e1 e2 e3) (a2)
                                     (a3)

  Therefore, WE use the convention

  (a1')    (   ) (a1)
  (a2')  = ( M ) (a2)
  (a3')    (   ) (a3)

                             (   )
  (e1 e2 e3) = (e1' e2' e3') ( M ) 
                             (   )

  For details, see e.g. "Misner, Thorne, Wheeler:
  Gravitation". Unfortunately, the "wrong way" is rather
  widespread. Even OpenGL seems to want us to think this
  way. Please try not to get too confused about this; or
  better, if you are confused: yes, it's not entirely
  trivial what's going on here. Our three-dimensional space
  *is* a bit complicated.  But there is a recipe to master
  it: practice. Once you can think of one constellation in
  two different coordinate systems, you have won.


  In rigid body mechanics, it's best to think of this M as
  the matrix, which, when multiplied-right with a column
  space-coordinate vector (cscv) gives the corresponding
  column body-coordinate vector (cbcv).

  $rotation=Math::SO3->new("zr" => 3.14159/2, 
			   "xr" => 3.14159/4, 
			   "zr" => 3.14159/8);

    Create a new SO3-rotation matrix. You may specify an
    arbitrary number of rotations performed on the identity
    matrix. In the above case, if you think of $rotation as
    the matrix translating column-space-coordinate-vectors
    to column-body-coordinate-vectors (from here on called
    cscv->cbcv), these rotations you specify here will be
    applied to the body, rotating the body round one of its
    body axes. Important: Leftmost rotation will be applied
    first.  "zr" means rotate round z-axis, angle is in rad
    (full turn= 2pi rad); "xd" would mean: rotate round
    x-axis, angle is in degrees (full turn=360 degrees). Can
    be mixed.

    May also act as a copying constructor, as in: 
     $copy=$rotation->new().

  $rotation->invert();

    Invert a rotation.

  $rotation->turn("zr" => 3.14159/2, "xr" => 3.14159/4);

    Just as you can specify rotations at SO3 creation, 
    you may add a few more later on. Although "numerical drift" can
    build up, it is not possible for the rotation to get noticeably
    non-orthogonal.

  $rotation->turn_round_axis((pack "d3", 1,1,1), 30, "degrees");

    Turn the body round the axis given in space coordinates.

  $rotation->combine($rotation_after);

    left-multiplies with $rotation_after, that is, executes
    $rotation_after after $rotation, in the sense defined
    above.

  $rotation->translate_vectors($vec1, $vec2, 
                               $vec3, $vec4, @other_vectors);

    Destructively replace each single one of a list of
    cscv's by the corresponding cbcv's. Note that vectors
    must be packed-double-strings:
    $vec=pack("d3",$xcoord,$ycoord,$zcoord);

    Note: if vectors are "longer", say, like pack("d4", 5,8,10,1), 
    only the first three coordinates will be replaced. 
    This is very useful when working with homogenous coordinates.

  $rotation->inv_translate_vectors($vec1, $vec2, 
                                   $vec3, $vec4, @other_vectors);

    Just the other way round, going cbcv -> cscv.

  ($angle, $dir)=$rotation->turning_angle_and_dir("d");

    Euler's theorem states that in three dimensions, every
    combination of rotations may be expressed as a single
    rotation round a given direction.  This determines angle
    and direction Say "d" if you want degrees, "r" for rad.

    FIXME code for this function is a bit weird and really
    should be reviewed. So please, you NASA guys, don't use
    it to compute RTG-satellite trajectories.

  ($phi, $theta, $psi)=$rotation->euler_angles_zxz("d");

    Returns just the famous Euler angles corresponding to a
    rotation. Specify "d" if you want degrees, "r" for rad.

    Note: this is designed for speed, and may, for a very
    small fraction of all possible angles, give bad results
    due to division by a small quantity.

  ($heading, $pitch, $roll)=$rotation->euler_angles_yxz("d");

    Standard zxz euler angles have one problem: if theta 
    is very small, phi and psi rotations nearly go in 
    the same direction, therefore, it's a bit difficult
    to see from coordinates if two rotations are very 
    similar or are absolutely not. This is an alternative
    angle specification which is very common in aeronautics.
    Probably just the thing you need if you want to build
    a flight simulator.

    Note: accuracy see above.

  $rotation->format_matrix();
  $rotation->format_matrix("%16.8f");

    Computes a string 
    "[[m00 m01 m02][m10 m11 m12][m20 m21 m22]]" 
    displaying the matrix elements. Optionally, a sprintf
    format-string may be specified for the matrix
    elements. Default is "%10.5f".

  $rotation->format_eigenvector();
  $rotation->format_eigenvector("%16.8f");

    Similarly, computes a string like
    "<rotate   92.06153 deg round [   0.88972    0.07784   -0.44982]>"

  $rotation->format_euler_zxz();
  $rotation->format_euler_zxz("%16.8f");

    Similarly, computes a string like
    "<D_z(psi= 330.00000 deg) D_x(theta=  80.00000 deg) D_z(phi= 340.00000 deg)>"

  $rotation->format_euler_yxz();
  $rotation->format_euler_yxz("%16.8f");

   Just the same, but string is like
   "<D_z(heading= 338.30608 deg) D_x(pitch= -24.51349 deg) D_z(roll= 348.25034 deg)>"

  Basically, these functions were added as a quick way to
  get debugging info.  Therefore, all angles are given in
  degrees, since these are more readable.


=head1 AUTHOR AND LICENSE

Copyright 1999 Thomas Fischbacher

(tf@cip.physik.uni-muenchen.de)

License: GNU Lesser General Public License (aka GNU LGPL)
Copy of the LGPL not included, since it should come with
your copy of perl. You may find it at

http://www.gnu.org/copyleft/lesser.html

=head1 SEE ALSO

perl(1).

=cut
