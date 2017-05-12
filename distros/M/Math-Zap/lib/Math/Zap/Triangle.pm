
=head1 Triangle

Triangles in 3D space

PhilipRBrenan@yahoo.com, 2004, Perl License


=head2 Synopsis

Example t/triangle.t

 #_ Triangle ___________________________________________________________
 # Test 3d triangles    
 # philiprbrenan@yahoo.com, 2004, Perl License    
 #______________________________________________________________________
 
 use Math::Zap::Vector;
 use Math::Zap::Vector2;
 use Math::Zap::Triangle;
 use Test::Simple tests=>25;
  
 $t = triangle
  (vector( 0,  0,  0), 
   vector( 0,  0,  4), 
   vector( 4,  0,  0),
  );
  
 $u = triangle
  (vector( 0,  0,  0), 
   vector( 0,  1,  4), 
   vector( 4,  1,  0),
  );
 
 $T = triangle
  (vector( 0,  1,  0), 
   vector( 0,  1,  1), 
   vector( 1,  1,  0),
  );
 
 $c = vector(1, 1, 1);
 
 #_ Triangle ___________________________________________________________
 # Distance to plane
 #______________________________________________________________________
 
 ok($t->distance($c)   == 1, 'Distance to plane');
 ok($T->distance($c)   == 0, 'Distance to plane');
 ok($t->distance(2*$c) == 2, 'Distance to plane');
 ok($t->distanceToPlaneAlongLine(vector(0,-1,0), vector(0,1,0)) == 1, 'Distance to plane towards a point');
 ok($T->distanceToPlaneAlongLine(vector(0,-1,0), vector(0,1,0)) == 2, 'Distance to plane towards a point');
 
 #_ Triangle ___________________________________________________________
 # Permute the points of a triangle
 #______________________________________________________________________
 
 ok($t->permute                   == $t, 'Permute 1');
 ok($t->permute->permute          == $t, 'Permute 2');
 ok($t->permute->permute->permute == $t, 'Permute 3');
 
 #_ Triangle ___________________________________________________________
 # Intersection of a line with a plane defined by a triangle
 #______________________________________________________________________
 
 #ok($t->intersection($c, vector(1,  -1,  1)) == vector(1, 0, 1), 'Intersection of line with plane');
 #ok($t->intersection($c, vector(-1, -1, -1)) == vector(0, 0, 0), 'Intersection of line with plane');
 
 #_ Triangle ___________________________________________________________
 # Test whether a point is in front or behind a plane relative to another
 # point
 #______________________________________________________________________
  
 ok($t->frontInBehind($c, vector(1,  0.5,  1)) == +1, 'Front');
 ok($t->frontInBehind($c, vector(1,    0,  1)) ==  0, 'In');
 ok($t->frontInBehind($c, vector(1, -0.5,  1)) == -1, 'Behind');
 
 #_ Triangle ___________________________________________________________
 # Parallel
 #______________________________________________________________________
  
 ok($t->parallel($T) == 1, 'Parallel');
 ok($t->parallel($u) == 0, 'Not Parallel');
 
 #_ Triangle ___________________________________________________________
 # Coplanar
 #______________________________________________________________________
  
 #ok($t->coplanar($t) == 1, 'Coplanar');
 #ok($t->coplanar($u) == 0, 'Not coplanar');
 #ok($t->coplanar($T) == 0, 'Not coplanar');
 
 #_ Triangle ___________________________________________________________
 # Project one triangle onto another
 #______________________________________________________________________
 
 $p = vector(0, 2, 0);
 $s = $t->project($T, $p);
 
 ok($s == triangle
  (vector(0,   0,   2),
   vector(0.5, 0,   2),
   vector(0,   0.5, 2),
  ), 'Projection of corner 3');
 
 #_ Triangle ___________________________________________________________
 # Convert space to plane coordinates and vice versa
 #______________________________________________________________________
 
 ok($t->convertSpaceToPlane(vector(2, 2, 2))   == vector(0.5,0.5,2), 'Space to Plane');
 ok($t->convertPlaneToSpace(vector2(0.5, 0.5)) == vector(2, 0, 2),   'Plane to Space');
 
 #_ Triangle ___________________________________________________________
 # Divide 
 #______________________________________________________________________
 
 $it = triangle          # Intersects t
  (vector(  0, -1,  2), 
   vector(  0,  2,  2), 
   vector(  3,  2,  2),
  );
 
 @d = $t->divide($it);
 
 ok($d[0] == triangle(vector(0, -1, 2), vector(0, 0, 2), vector(1, 0, 2)));
 ok($d[1] == triangle(vector(0,  2, 2), vector(0, 0, 2), vector(1, 0, 2)));
 ok($d[2] == triangle(vector(0,  2, 2), vector(1, 0, 2), vector(3, 2, 2)));
 
 $it = triangle          # Intersects t
  (vector(  3,  2,  2),
   vector(  0,  2,  2), 
   vector(  0, -1,  2), 
  );
 
 @d = $t->divide($it);
 
 ok($d[0] == triangle(vector(0, -1, 2), vector(0, 0, 2), vector(1, 0, 2)));
 ok($d[1] == triangle(vector(3,  2, 2), vector(1, 0, 2), vector(0, 0, 2)));
 ok($d[2] == triangle(vector(3,  2, 2), vector(0, 0, 2), vector(0, 2, 2)));
 
 $it = triangle          # Intersects t
  (vector(  3,  2,  2),
   vector(  0, -1,  2), 
   vector(  0,  2,  2), 
  );
 
 @d = $t->divide($it);
 
 ok($d[0] == triangle(vector(0, -1, 2), vector(1, 0, 2), vector(0, 0, 2)));
 ok($d[1] == triangle(vector(3,  2, 2), vector(1, 0, 2), vector(0, 0, 2)));
 ok($d[2] == triangle(vector(3,  2, 2), vector(0, 0, 2), vector(0, 2, 2)));



=head2 Description

Triangles in 3D space

Definitions:

Space coordinates = 3d space

Plane coordinates = a triangle in 3d space defines a 2d plane with a
natural coordinate system: the origin is the first point of the
triangle, the (x,y) units of this plane are the sides from the triangles
first point to its other points.

=cut


package Math::Zap::Triangle;
$VERSION=1.07;
use Math::Zap::Line2;
use Math::Zap::Unique;
use Math::Zap::Vector2 check=>'vector2Check';
use Math::Zap::Vector  check=>'vectorCheck';
use Math::Zap::Matrix  new3v=>'matrixNew3v';
use Carp qw(cluck confess);
use constant debug => 0; # Debugging level


=head2 Constructors


=head3 new

Create a triangle from 3 vectors specifying the coordinates of each
corner in space coordinates.

=cut


sub new($$$)
 {my ($a, $b, $c) = vectorCheck(@_);
  my $t = bless {a=>$a, b=>$b, c=>$c};
  narrow($t, 1);
  $t; 
 }


=head3 triangle

Create a triangle from 3 vectors specifying the coordinates of each
corner in space coordinates - synonym for L</new>.

=cut


sub triangle($$$) {new($_[0],$_[1],$_[2])};


=head2 Methods


=head3 narrow

Narrow (colinear) triangle?

=cut


sub narrow($$)
 {my $t = shift;  # Triangle
  my $a = 1e-2;   # Accuracy
  my $A = shift;  # Action 0: return indicator, 1: confess 
  
  my $n = (($t->b-$t->a) x ($t->c-$t->a))->length < $a;
  
  confess "Narrow triangle" if $n and $A;
  $n;      
 }


=head3 check

Check its a triangle

=cut


sub check(@)
 {if (debug)
   {for my $t(@_)
     {confess "$t is not a triangle" unless ref($t) eq __PACKAGE__;
     }
   } 
  return (@_)
 }


=head3 is

Test its a triangle

=cut


sub is(@)
 {for my $t(@_)
   {return 0 unless ref($t) eq __PACKAGE__;
   }
  'triangle';
 }


=head3 components

Components of a triangle

=cut


sub a($)   {check(@_) if debug; $_[0]->{a}}
sub b($)   {check(@_) if debug; $_[0]->{b}}
sub c($)   {check(@_) if debug; $_[0]->{c}}

sub ab($)  {check(@_) if debug; ($_[0]->{b}-$_[0]->{a})}
sub ac($)  {check(@_) if debug; ($_[0]->{c}-$_[0]->{a})}
sub ba($)  {check(@_) if debug; ($_[0]->{a}-$_[0]->{b})}
sub bc($)  {check(@_) if debug; ($_[0]->{c}-$_[0]->{b})}
sub ca($)  {check(@_) if debug; ($_[0]->{a}-$_[0]->{c})}
sub cb($)  {check(@_) if debug; ($_[0]->{b}-$_[0]->{c})}

sub abc($) {check(@_) if debug; ($_[0]->{a}, $_[0]->{b}, $_[0]->{c})}
sub area($){check(@_) if debug; ($_[0]->ab x $_[0]->ac)->length}


=head3 clone

Create a triangle from another triangle 

=cut


sub clone($)
 {my ($t) = check(@_); # Triangle   
  bless {a=>$t->a, b=>$t->b, c=>$t->c};
 }


=head3 permute

Cyclically permute the points of a triangle

=cut


sub permute($)
 {my ($t) = check(@_); # Triangle   
  bless {a=>$t->b, b=>$t->c, c=>$t->a};
 }


=head3 center

Center 

=cut


sub center($)
 {my ($t) = check(@_); # Triangle   
  ($t->a + $t->b + $t->c) / 3;
 }


=head3 add

Add a vector to a triangle               

=cut


sub add($$)
 {my ($t) =         check(@_[0..0]); # Triangle   
  my ($v) = vectorCheck(@_[1..1]); # Vector     
  new($t->a+$v, $t->b+$v, $t->c+$v);                         
 }


=head3 subtract

Subtract a vector from a triangle               

=cut


sub subtract($$)
 {my ($t) =         check(@_[0..0]); # Triangle   
  my ($v) = vectorCheck(@_[1..1]); # Vector     
  new($t->a-$v, $t->b-$v, $t->c-$v);                         
 }


=head3 print

Print triangle 

=cut


sub print($)
 {my ($t) = check(@_); # Triangle   
  my ($a, $b, $c) = ($t->a, $t->b, $t->c);
  "triangle($a, $b, $c)";
 }


=head3 accuracy

# Get/Set accuracy for comparisons

=cut


my $accuracy = 1e-10;

sub accuracy
 {return $accuracy unless scalar(@_);
  $accuracy = shift();
 }


=head3 distance

Shortest distance from plane defined by triangle t to point p                                

=cut


sub distance($$)
 {my ($t) =         check(@_[0..0]); # Triangle  
  my ($p) = vectorCheck(@_[1..1]); # Vector
  my  $n  = $t->ab x $t->ac;         # Plane normal
  my ($a, $b) = ($p, $p+$n);
   
  my $s = matrixNew3v($t->ab, $t->ac, $a-$b)/($a-$t->a);

  ($n*$s->z)->length;
 }


=head3 intersectionInPlane

Intersect line between two points with plane defined by triangle and
return the intersection in plane coordinates. 
Identical logic as per intersection().
Note:  no checks (yet) for line parallel to plane.

=cut


sub intersectionInPlane($$$)
 {my ($t)     =         check(@_[0..0]); # Triangle  
  my ($a, $b) = vectorCheck(@_[1..2]); # Vectors
   
  matrixNew3v($t->ab, $t->ac, $a-$b)/($a-$t->a);
 }


=head3 distanceToPlaneAlongLine

Distance to plane defined by triangle t going from a to b, or undef 
if the line is parallel to the plane           

=cut


sub distanceToPlaneAlongLine($$$)
 {my ($t)     =         check(@_[0..0]); # Triangle  
  my ($a, $b) = vectorCheck(@_[1..2]); # Vectors

  return undef if abs(($t->ab x $t->ac) * ($b - $a)) < $accuracy;
   
  my $i = matrixNew3v($t->ab, $t->ac, $a-$b)/($a-$t->a);
  $i->z * ($a-$b)->length;
 }


=head3 convertSpaceToPlane

Convert space to plane coordinates                                   

=cut


sub convertSpaceToPlane($$)
 {my ($t) =         check(@_[0..0]); # Triangle  
  my ($p) = vectorCheck(@_[1..1]); # Vector
   
  my $q = $p-$t->a;

  vector
   ($q * $t->ab / ($t->ab * $t->ab),
    $q * $t->ac / ($t->ac * $t->ac),
    $q * ($t->ab x $t->ac)->norm
   );
 }


=head3 convertPlaneToSpace

Convert splane to space coordinates                                   

=cut


sub convertPlaneToSpace($$)
 {my ($t, $p) = @_;
         check(@_[0..0]) if debug; # Triangle  
  vector2Check(@_[1..1]) if debug; # Vector in plane
   
  $t->a + ($p->x * $t->ab) + ($p->y * $t->ac);
 }


=head3 frontInBehind

Determine whether a test point b as viewed from a view point a is in
front of(1), in(0), or behind(-1) a plane defined by a triangle t.
Identical logic as per intersection(), except this time we use the
z component to determine the relative position of the point b.
Note:  no checks (yet) for line parallel to plane.

=cut


sub frontInBehind($$$)
 {my ($t, $a, $b) = @_;
          check(@_[0..0]) if debug; # Triangle  
  vectorCheck(@_[1..2]) if debug; # Vectors
  return 1 if abs(($t->ab x $t->ac) * ($a-$b)) < $accuracy; # Parallel
  $s = matrixNew3v($t->ab, $t->ac, $a-$b)/($a-$t->a);
  $s->z <=> 1;
 }


=head3 frontInBehindZ

Determine whether a test point b as viewed from a view point a is in
front of(1), in(0), or behind(-1) a plane defined by a triangle t.
Identical logic as per intersection(), except this time we use the
z component to determine the relative position of the point b.
Note:  no checks (yet) for line parallel to plane.

=cut


sub frontInBehindZ($$$)
 {my ($t, $a, $b) = @_;
          check(@_[0..0]) if debug; # Triangle  
  vectorCheck(@_[1..2]) if debug; # Vectors
  return undef if abs(($t->ab x $t->ac) * ($a-$b)) < $accuracy;  # Parallel
  $s = matrixNew3v($t->ab, $t->ac, $a-$b)/($a-$t->a);
  $s->z;
 }


=head3 parallel

Are two triangle parallel?
I.e. do they define planes that are parallel?
If they are parallel, their normals will have zero cross product

=cut


sub parallel($$)
 {my ($a, $b) = check(@_); # Triangles
  !(($a->ab x $a->ac) x ($b->ab x $b->ac))->length;
 }


=head3 divide

Divide triangle b by a:  split b into triangles each of which is not
intersected by a. 
Triangles are easy to draw in 3d except when they intersect:
If they do not intersect, we can always draw one on top of the other
and obtain the correct result;
If they do intersect, they have to be split along the line of
intersection into a sub triangle and a quadralateral: which can
be be split again to obtain a result consisting of only triangles.
The splitting can be done once: Each new view point only requires
the correct ordering of the non intersecting triangles.

=cut


sub divide($$)
 {my ($a, $b) = check(@_);         # Triangles  

  return ($b) if $a->parallel($b); # Parallel: no need to split

  my $A = $a->permute; $a = $A if $b->distance($A->a) > $b->distance($a->a);
     $A = $A->permute; $a = $A if $b->distance($A->a) > $b->distance($a->a);
 
  my $na = $a->ab x $a->ac;        # Normal to a
  my $nb = $b->ab x $b->ac;        # Normal to b

  my $aa = $a->a;
  my $ab = $a->b;
  my $ac = $a->c;
  my $bc = $a->bc;

# Avoid using vectors in a that are parallel to b
  $ab += $bc/2 if ($a->ab->norm * $nb->norm) < 0.1;
  $ac += $bc/2 if ($a->ac->norm * $nb->norm) < 0.1;

# Two points in both planes in b plane coordinates
  my $i = $b->intersectionInPlane($aa, $ab);
  my $j = $b->intersectionInPlane($aa, $ac);


# Does the line between these points intersect the sides of triangle b?
  my $l = line2
   (vector2($i->x, $i->y), 
    vector2($j->x, $j->y),
   );
  return ($b) if ($l->b-$l->a)->length < $accuracy;

# Triangle b has very simple sides in b plane coordinates

  my $l1 = line2(vector2(0, 0), vector2(1, 0)); # ab
  my $l2 = line2(vector2(0, 0), vector2(0, 1)); # ac
  my $l3 = line2(vector2(1, 0), vector2(0, 1)); # bc 

  my $i1 = ((!$l->parallel($l1)) and ($l->intersectWithin($l1)));
  my $i2 = ((!$l->parallel($l2)) and ($l->intersectWithin($l2)));
  my $i3 = ((!$l->parallel($l3)) and ($l->intersectWithin($l3)));

# There should be either 0 or 2 intersections.
   {my $n = $i1+$i2+$i3;
    ($n == 1 or $n == 3) and  debug and warn "There should 0 or 2 intersections, not $n";
    return ($b) unless $n == 2; # No division required
   }

# There are two intersections.
# Make a copy of b called c, orientated so that the line of 
# intersection crosses sides c->ab, c->ac           
  my $c;
  $c = $b                                 if $i1 and $i2;   
  $c = triangle($b->b, $b->a, $b->c) if $i1 and $i3;   
  $c = triangle($b->c, $b->a, $b->b) if $i2 and $i3;

# Find intersection points in terms of reorientated triangle   

  unless ($i1 and $i2)
   {$i = $c->intersectionInPlane($aa, $ab);
    $j = $c->intersectionInPlane($aa, $ac);
    $l = line2
     (vector2($i->x, $i->y), 
      vector2($j->x, $j->y),
     );
   }

# this time in plane coordinates
  $i1 = $l->intersect($l1);
  $i2 = $l->intersect($l2);

# Convert to space coordinates
  my $s1 = $c->convertPlaneToSpace($i1);
  my $s2 = $c->convertPlaneToSpace($i2);

# Vertices close to intersection points 
  my $a1 = ($c->a - $s1)->length < 1e-3; 
  my $a2 = ($c->a - $s2)->length < 1e-3; 
  my $b1 = ($c->b - $s1)->length < 1e-3; 
  my $b2 = ($c->b - $s2)->length < 1e-3; 
  my $c1 = ($c->c - $s1)->length < 1e-3; 
  my $c2 = ($c->c - $s2)->length < 1e-3;

  return ($b) if ($a1 or $b1 or $c1) and ($a2 or $b2 or $c2);
  
# Divide b into 3 if the intersections points are far from the vertices
  return
   (triangle($c->a, $s1, $s2),
    triangle($c->b, $s1, $s2),
    triangle($c->b, $s2, $c->c),
   ) unless $a1 or $a2 or $b1 or $b2 or $c1 or $c2;

# If only one intersection point is close to a vertex, make it s1.
  ($s1, $s2, $a1, $b1, $c1, $a2, $b2, $c2) =
  ($s2, $s1, $a2, $b2, $c2, $a1, $b1, $c1) if !($a1 or $b1 or $c1) and ($a2 or $b2 or $c2);

# Divide b into 2 if one intersection point is close to a vertex
  return
   (triangle($c->a, $c->b, $s2),
    triangle($c->a, $c->c, $s2),
   ) if $a1;
  return
   (triangle($c->a, $c->b, $s2),
    triangle($c->c, $c->b, $s2),
   ) if $b1;
  return
   (triangle($c->a, $c->c, $s2),
    triangle($c->b, $c->c, $s2),
   ) if $c1;
  confess "Unable to divide triangle $a by $b\n"
 }


=head3 project

Project onto the plane defined by triangle t the image of a triangle
triangle T as viewed from a view point p.
Return the coordinates of the projection of T onto t using the plane
coordinates induced by t.
The projection coordinates are (of course) 2d in the projection plane,
however they are returned as the x,y components of a 3d vector with 
the z component set to the multiple of the distance from the view point
to the corresponding corner of T required to reach t. If z > 1, this
corner of T is in front the plane of t, if z < 1 this corner of T is
behind the plane of t.
The logic is the same as intersection().

=cut


sub project($$$)
 {my ($t, $T, $p) = @_;
          check(@_[0..1]) if debug; # Triangles 
  vectorCheck(@_[2..2]) if debug; # Vector

  new
   (matrixNew3v($t->ab, $t->ac, $p-$T->a)/($p-$t->a),
    matrixNew3v($t->ab, $t->ac, $p-$T->b)/($p-$t->a),
    matrixNew3v($t->ab, $t->ac, $p-$T->c)/($p-$t->a),
   );
 } 


=head3 split

Split a triangle into 4 sub triangles unless the sub triangles would
be too small

=cut


sub split($$)
 {my ($t) = check(@_[0..0]); # Triangles 
  my ($s) =      (@_[1..1]); # Minimum size 

  return () unless
    $t->ab->length > $s and
    $t->ac->length > $s and
    $t->bc->length > $s;

   (new($t->a, ($t->a+$t->b)/2, ($t->a+$t->c)/2),
    new($t->b, ($t->b+$t->a)/2, ($t->b+$t->c)/2),
    new($t->c, ($t->c+$t->a)/2, ($t->c+$t->b)/2),
    new(($t->a+$t->b)/2, ($t->a+$t->b)/2, ($t->b+$t->c)/2)
   )
 } 


=head3 triangulate

Triangulate

=cut


sub triangulate($$)
 {my ($t)    = check(@_[0..0]); # Triangle
  my  $color =       @_[1..1];  # Color           
  my  $plane = unique();        # Plane           
   
  {triangle=>$t, color=>$color, plane=>$plane};
 }


=head3 equals

Compare two triangles for equality                                  

=cut


sub equals($$)
 {my ($a, $b) = check(@_); # Triangles
  my ($aa, $ab, $ac) = ($a->a, $a->b, $a->c);
  my ($ba, $bb, $bc) = ($b->a, $b->b, $b->c);
  my  $d             = $accuracy;  

  return 1 if 
abs(($aa-$ba)->length) < $d and abs(($ab-$bb)->length) < $d and abs(($ac-$bc)->length) < $d or
abs(($aa-$ba)->length) < $d and abs(($ab-$bc)->length) < $d and abs(($ac-$bb)->length) < $d or
abs(($aa-$bb)->length) < $d and abs(($ab-$bc)->length) < $d and abs(($ac-$ba)->length) < $d or
abs(($aa-$bb)->length) < $d and abs(($ab-$ba)->length) < $d and abs(($ac-$bc)->length) < $d or
abs(($aa-$bc)->length) < $d and abs(($ab-$ba)->length) < $d and abs(($ac-$bb)->length) < $d or
abs(($aa-$bc)->length) < $d and abs(($ab-$bb)->length) < $d and abs(($ac-$ba)->length) < $d;  
  0;
 } 


=head2 Operators

Operator overloads

=cut


use overload
 '+',       => \&add3,      # Add a vector
 '-',       => \&sub3,      # Subtract a vector
 '=='       => \&equals3,   # Equals
 '""'       => \&print3,    # Print
 'fallback' => FALSE;


=head3 add

Add operator.

=cut


sub add3
 {my ($a, $b, $c) = @_;
  return $a->add($b);
 }


=head3 subtract

Subtract operator.

=cut


sub sub3
 {my ($a, $b, $c) = @_;
  return $a->subtract($b);
 }


=head3 equals

Equals operator.

=cut


sub equals3
 {my ($a, $b, $c) = @_;
  return $a->equals($b);
 }


=head3 print

Print a triangle

=cut


sub print3
 {my ($a) = @_;
  return $a->print;
 }


=head2 Exports

Export L</triangle>

=cut


use Math::Zap::Exports qw(
  triangle ($$$)
 );

#_ Triangle ___________________________________________________________
# Package loaded successfully
#______________________________________________________________________

1;



=head2 Credits

=head3 Author

philiprbrenan@yahoo.com

=head3 Copyright

philiprbrenan@yahoo.com, 2004

=head3 License

Perl License.


=cut
