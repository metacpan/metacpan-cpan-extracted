
=head1 Rectangle

Rectangles in 3d space    

PhilipRBrenan@yahoo.com, 2004, Perl License


=head2 Synopsis

Example t/rectangle.t

 #_ Rectangle __________________________________________________________
 # Test 3d rectangles          
 # philiprbrenan@yahoo.com, 2004, Perl License    
 #______________________________________________________________________
 
 use Math::Zap::Rectangle;
 use Math::Zap::Vector;
 use Test::Simple tests=>3;
 
 my ($a, $b, $c, $d) =
  (vector(0,    0, +1),
   vector(0, -1.9, -1),
   vector(0, -2.0, -1),
   vector(0, -2.1, -1)
  );
 
 my $r = rectangle
  (vector(-1,-1, 0),
   vector( 2, 0, 0),
   vector( 0, 2, 0)
  );
 
 ok($r->intersects($a, $b) == 1);
 ok($r->intersects($a, $c) == 1);
 ok($r->intersects($a, $d) == 0);
 



=head2 Description

Rectangles in 3d space    

=cut


package Math::Zap::Rectangle;
$VERSION=1.07;
use Math::Zap::Vector check=>'vectorCheck';
use Math::Zap::Matrix new3v=>'matrixNew3v';
use Carp;


=head2 Constructors


=head3 new

Create a rectangle from 3 vectors:

 a position of any corner
 b first side
 c second side.

Note that vectors b,c must be at right angles to each other.

=cut


sub new($$$)
 {my ($a, $b, $c) = vectorCheck(@_);
  $b->dot($c) == 0 or confess 'non rectangular rectangle specified';
  bless {a=>$a, b=>$b, c=>$c}; 
 }


=head3 rectangle

Create a rectangle from 3 vectors - synonym for L</new>.

=cut


sub rectangle($$$) {new($_[0],$_[1],$_[2])};


=head2 Methods


=head3 check

Check its a rectangle

=cut


sub check(@)
 {for my $r(@_)
   {confess "$r is not a rectangle" unless ref($r) eq __PACKAGE__;
   }
  return (@_)
 }


=head3 is

Test its a rectangle

=cut


sub is(@)
 {for my $r(@_)
   {return 0 unless ref($r) eq __PACKAGE__;
   }
  'rectangle';
 }


=head3 a,b,c

Components of rectangle

=cut


sub a($) {my ($r) = check(@_); $r->{a}}
sub b($) {my ($r) = check(@_); $r->{b}}
sub c($) {my ($r) = check(@_); $r->{c}}


=head3 clone

Create a rectangle from another rectangle

=cut


sub clone($)
 {my ($r) = check(@_); # Rectangles
  bless {a=>$r->a, b=>$r->b, c=>$r->c};
 }


=head3 accuracy

Get/Set accuracy for comparisons

=cut


my $accuracy = 1e-10;

sub accuracy
 {return $accuracy unless scalar(@_);
  $accuracy = shift();
 }


=head3 intersection

Intersect line between two vectors with plane defined by a rectangle

 r rectangle
 a start vector
 b end vector

Solve the simultaneous equations of the plane defined by the
rectangle and the line between the vectors:

   ra+l*rb+m*rc         = a+(b-a)*n 
 =>ra+l*rb+m*rc+n*(a-b) = a-ra 

Note:  no checks (yet) for line parallel to plane.

=cut


sub intersection($$$)
 {my ($r)     =       check(@_[0..0]); # Rectangles
  my ($a, $b) = vectorCheck(@_[1..2]); # Vectors
   
  $s = matrixNew3v($r->b, $r->c, $a-$b)/($a-$r->a);
 } 


=head3 intersects

# Test whether a line between two vectors intersects a rectangle
# Note:  no checks (yet) for line parallel to plane.

=cut


sub intersects($$$)
 {my ($r)     =       check(@_[0..0]); # Rectangles
  my ($a, $b) = vectorCheck(@_[1..2]); # Vectors
   
  my $s = $r->intersection($a, $b);
  return 1 if $s->x >=0 and $s->x < 1 and
              $s->y >=0 and $s->y < 1 and
              $s->z >=0 and $s->z < 1;
  0;
 } 


=head3 visible

# Visibility of a rectangle r hid by other rectangles R from a view
# point p.
# Rectangle r is divided up into I*J sub rectangles: each sub rectangle
# is tested for visibility from point p via the intervening rectangles.

=cut


sub visible($$@)
 {my ($p)     = vectorCheck(@_[0.. 0]);    # Vector
  my ($I, $J) =            (@_[1.. 2]);    # Number of divisions  
  my ($r, @R) =       check(@_[3..scalar(@_)-1]);  # Rectangles

  my $v;
  $v->{r} = $r;                              # Save rectangle data
  $v->{I} = $I;                              # 
  $v->{J} = $J;                              #

  for      my $i(1..$I)                      # Along one edge
   {L: for my $j(1..$J)                      # Along the other edge
     {my $c = $r->a+($r->b)*(($i-1/2)/$I)    # Test point
                   +($r->c)*(($j-1/2)/$J);
      
      for my $R(@R)                          # Each intervening rectangle
       {my ($x, $y, $z) = ($c->x, $c->y, $c->z);
        my $in = $R->intersects($p, $c);
        next L if $in;                       # Solid, intersected
       }
      $v->{v}{$i}{$j} = 1;
     }
   }
  $v;
 } 


=head3 project

# Project rectangle r onto rectangle R from a point p

=cut


sub project($$$)
 {my ($p)     = vectorCheck(@_[0.. 0]);    # Vector
  my ($r, $R) =            (@_[1.. 2]);    # Rectangles           
   
  my $A = $r->a;                             # Main  corner of r
  my $B = $r->a+$r->b;                       # One   corner of r
  my $C = $r->a+$r->c;                       # Other corner of r

  my $a = $R->intersection($p, $A);          # Main  corner of r on R
  my $b = $R->intersection($p, $B);          # One   corner of r on R
  my $c = $R->intersection($p, $C);          # Other corner of r on R

  $aR = $p+($A-$p)*$a->z;                    # Coordinates of main  corner of r on R
  $bR = $p+($B-$p)*$b->z;                    # Coordinates of one   corner of r on R
  $cR = $p+($C-$p)*$c->z;                    # Coordinates of other corner of r on R
  print "a=$aR\n";
  print "b=$bR\n";
  print "c=$cR\n";

  rectangle($aR, $bR, $cR);
 } 


=head3 projectInto

# Project rectangle r into rectangle R from a point p

=cut


sub projectInto($$$)
 {my ($r, $R) =            (@_[0..1]);    # Rectangles           
  my ($p)     = vectorCheck(@_[2..2]);    # Vector
   
  my $A = $r->a;                             # Main     corner of r
  my $B = $r->a+$r->b;                       # One      corner of r
  my $C = $r->a+$r->c;                       # Other    corner of r
  my $D = $r->a+$r->b+$r->c;                 # Opposite corner of r

  my $a = $R->intersection($p, $A);          # Main     corner of r on R
  my $b = $R->intersection($p, $B);          # One      corner of r on R
  my $c = $R->intersection($p, $C);          # Other    corner of r on R
  my $d = $R->intersection($p, $D);          # Opposite corner of r on R

  ($a, $b, $d, $c);
 } 


=head2 Exports

Export L</rectangle>                                      

=cut


use Math::Zap::Exports qw(
  rectangle ($$$)    
 );

#_ Rectangle __________________________________________________________
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
