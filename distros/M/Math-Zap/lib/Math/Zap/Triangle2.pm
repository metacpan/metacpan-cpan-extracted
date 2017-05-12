
=head1 Triangle2

Triangles in 2D space

PhilipRBrenan@yahoo.com, 2004, Perl License


=head2 Synopsis

Example t/triangle2.t

 #_ Triangle ___________________________________________________________
 # Test 2d triangles    
 # philiprbrenan@yahoo.com, 2004, Perl License    
 #______________________________________________________________________
 
 use Math::Zap::Triangle2;
 use Math::Zap::Vector2;
 use Test::Simple tests=>27;
  
 $a = triangle2
  (vector2(0, 0), 
   vector2(2, 0), 
   vector2(0, 2),
  );
  
 $b = triangle2
  (vector2( 0,  0), 
   vector2( 4,  0), 
   vector2( 0,  4),
  );
  
 $c = triangle2
  (vector2( 0,  0), 
   vector2(-4,  0), 
   vector2( 0, -4),
  );
  
 $d = $b - vector2(1,1);
 $e = $c + vector2(1,1);
 
 #print "a=$a\nb=$b\nc=$c\nd=$d\ne=$e\n";
 
 ok($a->containsPoint(vector2( 1,  1)));
 ok($a->containsPoint(vector2( 1,  1)));
 ok($b->containsPoint(vector2( 2,  0)));
 ok($b->containsPoint(vector2( 1,  0)));
 ok($c->containsPoint(vector2(-1,  0)));
 ok($c->containsPoint(vector2(-2,  0)));
 ok($d->containsPoint(vector2( 1, -1)));
 
 ok(!$a->containsPoint(vector2( 9,  1)));
 ok(!$a->containsPoint(vector2( 1,  9)));
 ok(!$b->containsPoint(vector2( 2,  9)));
 ok(!$b->containsPoint(vector2( 9,  0)));
 ok(!$c->containsPoint(vector2(-9,  0)));
 ok(!$c->containsPoint(vector2(-2,  9)));
 ok(!$d->containsPoint(vector2( 9, -1)));
 
 ok( $a->containsPoint(vector2(0.5, 0.5)));
 ok(!$a->containsPoint(vector2( -1,  -1)));
 
 ok(vector2(1,2)->rightAngle == vector2(-2, 1));
 ok(vector2(1,0)->rightAngle == vector2( 0, 1));
 
 ok($a->area == 2);
 ok($c->area == 8);
 
 eval { triangle2(vector2(0, 0), vector2(3, -6), vector2(-3, 6))};
 ok($@ =~ /^Narrow triangle2/, 'Narrow triangle');
 
 $t = triangle2(vector2(0,0),vector2(0,10),vector2( 10,0));
 $T = triangle2(vector2(0,0),vector2(0,10),vector2(-10,10))+vector2(5, -2);
 @p = $t->ring($T);
 #print "$_\n" for(@p);
 ok($p[0] == vector2(0, 8), 'Ring 0');
 ok($p[1] == vector2(2, 8), 'Ring 1');
 ok($p[2] == vector2(5, 5), 'Ring 2');
 ok($p[3] == vector2(5, 0), 'Ring 3');
 ok($p[4] == vector2(3, 0), 'Ring 4');
 ok($p[5] == vector2(0, 3), 'Ring 5');



=head2 Description

Triangles in 2d space

=cut


package Math::Zap::Triangle2;
$VERSION=1.07;
use Math::Zap::Line2;
use Math::Zap::Matrix2 new2v=>'matrix2New2v';
use Math::Zap::Vector2 check=>'vector2Check';
use Math::Zap::Vector  check=>'vectorCheck';
use Math::Trig;            
use Carp qw(cluck confess);
use constant debug => 0; # Debugging level


=head2 Constructors


=head3 new

Create a triangle from 3 vectors specifying the coordinates of each
corner in space coordinates.

=cut


sub new($$$)
 {vector2Check(@_) if debug;
  my $t = bless {a=>$_[0], b=>$_[1], c=>$_[2]};
  narrow($t, 1);      
  $t;
 }


=head3 triangle2

Create a triangle from 3 vectors specifying the coordinates of each
corner in space coordinates - synonym for L</new>.

=cut


sub triangle2($$$) {new($_[0],$_[1],$_[2])};


=head3 newnnc

New without narrowness check

=cut


sub newnnc($$$)
 {vector2Check(@_) if debug;
  bless {a=>$_[0], b=>$_[1], c=>$_[2]};
 }


=head3 newV

Create a triangle from the x,y components of 3 3d vectors.

=cut


sub newV($$$)
 {vectorCheck(@_) if debug;
  my $t = bless
   {a=>vector2($_[0]->{x}, $_[0]->{y}),
    b=>vector2($_[1]->{x}, $_[1]->{y}),
    c=>vector2($_[2]->{x}, $_[2]->{y})};
  narrow($t, 1);      
  $t;
 }


=head3 newVnnc

Create a triangle from the x,y components of 3 3d vectors without
narrowness checking - assumes caller will do thir own.

=cut


sub newVnnc($$$)
 {vectorCheck(@_) if debug;
  bless
   {a=>vector2($_[0]->{x}, $_[0]->{y}),
    b=>vector2($_[1]->{x}, $_[1]->{y}),
    c=>vector2($_[2]->{x}, $_[2]->{y})};
 }


=head2 Methods


=head3 accuracy

Get/Set accuracy for comparisons

=cut


my $accuracy = 1e-10;

sub accuracy
 {return $accuracy unless scalar(@_);
  $accuracy = shift();
 }


=head3 narrow

Narrow (colinear) colinear?

=cut


sub narrow($$)
 {my $t = shift;  # Triangle
  my $a = 1e-2;   # Accuracy
  my $A = shift;  # Action 0: return indicator, 1: confess 
  my $b = vector($t->{b}{x}-$t->{a}{x}, $t->{b}{y}-$t->{a}{y}, 0);                                           
  my $c = vector($t->{c}{x}-$t->{a}{x}, $t->{c}{y}-$t->{a}{y}, 0);                                           
  my $n = ($b x $c)->length < $a;
  confess "Narrow triangle2" if $n and $A;
  $n;      
 }


=head3 check

Check its a triangle

=cut


sub check(@)
 {if (debug)
   {for my $t(@_)
     {confess "$t is not a triangle2" unless ref($t) eq __PACKAGE__;
     }
   }
  @_;
 }


=head3 is

Test its a triangle

=cut


sub is(@)
 {for my $t(@_)
   {return 0 unless ref($t) eq __PACKAGE__;
   }
  'triangle2';
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

sub lab($)  {check(@_) if debug; line2($_[0]->{b}, $_[0]->{a})}
sub lac($)  {check(@_) if debug; line2($_[0]->{c}, $_[0]->{a})}
sub lba($)  {check(@_) if debug; line2($_[0]->{a}, $_[0]->{b})}
sub lbc($)  {check(@_) if debug; line2($_[0]->{c}, $_[0]->{b})}
sub lca($)  {check(@_) if debug; line2($_[0]->{a}, $_[0]->{c})}
sub lcb($)  {check(@_) if debug; line2($_[0]->{b}, $_[0]->{c})}


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


=head3 area

Area 

=cut


sub area($)
 {my ($t) = check(@_); # Triangle   
  sqrt((($t->ab*$t->ab) * ($t->ac*$t->ac)) - ($t->ab * $t->ac))/2;
 }


=head3 add

Add a vector to a triangle               

=cut


sub add($$)
 {my ($t) =          check(@_[0..0]); # Triangle   
  my ($v) = vector2Check(@_[1..1]); # Vector     
  new($t->a+$v, $t->b+$v, $t->c+$v);                         
 }


=head3 subtract

Subtract a vector from a triangle               

=cut


sub subtract($$)
 {my ($t) =          check(@_[0..0]); # Triangle   
  my ($v) = vector2Check(@_[1..1]); # Vector     
  new($t->a-$v, $t->b-$v, $t->c-$v);                         
 }


=head3 multiply

Multiply a triangle by a scalar               

=cut


sub multiply($$)
 {my ($t) = check(@_[0..0]); # Triangle   
  my ($s) =       @_[1..1] ; # Scalar     
  new($t->a * $s, $t->b * $s, $t->c * $s);                         
 }


=head3 divideBy

Divide a triangle by a scalar               

=cut


sub divideBy($$)
 {my ($t) = check(@_[0..0]); # Triangle   
  my ($s) =       @_[1..1] ; # Scalar
  $s != 0 or confess "Attempt to divide by zero";    
  new($t->a / $s, $t->b / $s, $t->c / $s);                         
 }


=head3 print

Print triangle 

=cut


sub print($)
 {my ($t) = @_; # Triangle   
  check(@_) if debug;   
  my ($a, $b, $c) = ($t->a, $t->b, $t->c);
  "triangle2($a, $b, $c)";
 }


=head3 convertSpaceToPlane

Convert space to plane coordinates                                   

=cut


sub convertSpaceToPlane($$)
 {my ($t, $p) = @_;
           check(@_[0..0]) if debug; # Triangle  
  vector2Check(@_[1..1]) if debug; # Vector
   
  my $q = $p-$t->a;

  vector2
   ($q * $t->ab / ($t->ab * $t->ab),
    $q * $t->ac / ($t->ac * $t->ac),
   );
 }


=head3 containsPoint

Check whether point p is completely contained within triangle t.                                   

=cut


sub containsPoint($$)
 {my ($t, $p) = @_;
           check(@_[0..0]) if debug; # Triangle  
  vector2Check(@_[1..1]) if debug; # Vector

  my $s = matrix2New2v($t->ab, $t->ac) / ($p - $t->a);
                 
  return 1 if 0 <= $s->x and $s->x <= 1
          and 0 <= $s->y and $s->y <= 1
          and        $s->x + $s->y <= 1;
  0;
 }


=head3 contains

Check whether triangle T is completely contained within triangle t.                                   

=cut


sub contains($$)
 {my ($t, $T) = @_; 
  check(@_) if debug; # Triangles

  return 1 if $t->containsPoint($T->a) and
              $t->containsPoint($T->b) and
              $t->containsPoint($T->c);   
  0;
 }


=head3 pointsInCommon

Find points in common to two triangles.  A point in common is a point
on the border of one triangle touched by the border of the other
triangle.

=cut


sub pointsInCommon($$)
 {my ($t, $T) = @_; 
  check(@_) if debug; # Triangles

  return ($T->a, $T->b, $T->c) if $t->contains($T);
  return ($t->a, $t->b, $t->c) if $T->contains($t);

  my @p = ();
  push @p, $t->a if $T->containsPoint($t->a);  
  push @p, $t->b if $T->containsPoint($t->b);  
  push @p, $t->c if $T->containsPoint($t->c);

  push @p, $T->a if $t->containsPoint($T->a);  
  push @p, $T->b if $t->containsPoint($T->b);  
  push @p, $T->c if $t->containsPoint($T->c);
  
  push @p, $t->lab->intersect($T->lab) if $t->lab->crossOver($T->lab); 
  push @p, $t->lab->intersect($T->lac) if $t->lab->crossOver($T->lac); 
  push @p, $t->lab->intersect($T->lbc) if $t->lab->crossOver($T->lbc); 
  push @p, $t->lac->intersect($T->lab) if $t->lac->crossOver($T->lab); 
  push @p, $t->lac->intersect($T->lac) if $t->lac->crossOver($T->lac); 
  push @p, $t->lac->intersect($T->lbc) if $t->lac->crossOver($T->lbc);
  push @p, $t->lbc->intersect($T->lab) if $t->lbc->crossOver($T->lab); 
  push @p, $t->lbc->intersect($T->lac) if $t->lbc->crossOver($T->lac); 
  push @p, $t->lbc->intersect($T->lbc) if $t->lbc->crossOver($T->lbc);

# Remove duplicate points caused by splitting the vertices - inefficient and unreliable
  my %p;
  $p{"$_"}=$_ for(@p);
  values(%p); 
 }


=head3 ring

Ring of points formed by overlaying triangle t and T

=cut


sub ring($$)
 {my ($t, $T) = @_; 
  check(@_) if debug; # Triangles

  my @p = $t->pointsInCommon($T);
# scalar(@p) == 1 and warn "Only one point in common";
# scalar(@p) == 2 and warn "Only two points in common";
  return () unless scalar(@p) > 2;

# Find center
  my $c = vector2(0,0);
  $c += $_ for(@p);
  $c /= scalar(@p);

# Split by y coord   
  my (@yp, @yn);
  for my $p(0..@p-1)
   {return () if ($p[$p]-$c)->length < $accuracy;
    if (($p[$p]-$c)->y >= 0)
     {push @yp, $p;
     }
    else
     {push @yn, $p;
     }
   }

  @yp = sort {($p[$a]-$c)->norm->x <=> ($p[$b]-$c)->norm->x} @yp;
  @yn = sort {($p[$b]-$c)->norm->x <=> ($p[$a]-$c)->norm->x} @yn;

  my @a;
  push @a, $p[$_] for(@yp);
  push @a, $p[$_] for(@yn);
  @a;
 }


=head3 convertPlaneToSpace

Convert plane to space coordinates                                   

=cut


sub convertPlaneToSpace($$)
 {my ($t, $p) = @_;                               
           check(@_[0..0]) if debug; # Triangle  
  vector2Check(@_[1..1]) if debug; # Vector in plane
   
  $t->a + ($p->x * $t->ab) + ($p->y * $t->ac);
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


=head3 Operators

Operator overloads

=cut


use overload
 '+',       => \&add3,      # Add a vector
 '-',       => \&sub3,      # Subtract a vector
 '*',       => \&multiply3, # Multiply by a scalar
 '/',       => \&divide3,   # Divide by a scalar
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


=head3 multiply

Multiply operator.

=cut


sub multiply3
 {my ($a, $b) = @_;
  return $a->multiply($b);
 }


=head3 divide

Divide operator.

=cut


sub divide3
 {my ($a, $b, $c) = @_;
  return $a->divideBy($b);
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

Export L</triangle2>, L</new>, L</newnnc>, L</newV>, L</newVnnc>

=cut


use Math::Zap::Exports qw(
  triangle2 ($$$)
  new       ($$$)
  newnnc    ($$$)
  newV      ($$$)
  newVnnc   ($$$)
 );

#_ Triangle2 ___________________________________________________________
# Package loaded successfully
#_______________________________________________________________________

1;



=head2 Credits

=head3 Author

philiprbrenan@yahoo.com

=head3 Copyright

philiprbrenan@yahoo.com, 2004

=head3 License

Perl License.


=cut
