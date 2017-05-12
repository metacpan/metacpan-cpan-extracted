
=head1 Cube 

Cubes in 3d space
    
PhilipRBrenan@yahoo.com, 2004, Perl License


=head2 Synopsis

Example t/cube.t

 #_ Cube _______________________________________________________________
 # Test cube      
 # philiprbrenan@yahoo.com, 2004, Perl License    
 #______________________________________________________________________
 
 use Math::Zap::Cube unit=>u;
 use Test::Simple tests=>5;
 
 ok(u    eq 'cube(vector(0, 0, 0), vector(1, 0, 0), vector(0, 1, 0), vector(0, 0, 1))');
 ok(u->a eq 'vector(0, 0, 0)');
 ok(u->x eq 'vector(1, 0, 0)');
 ok(u->y eq 'vector(0, 1, 0)');
 ok(u->z eq 'vector(0, 0, 1)');
 


=head2 Description

Define and manipulate a cube in 3 dimensions

=cut


package Math::Zap::Cube;
$VERSION=1.07;
use Math::Zap::Unique;
use Math::Zap::Triangle;
use Math::Zap::Vector check=>vectorCheck;     
use Carp;


=head2 Constructors


=head3 new

Create a rectangle from 3 vectors:

=over



=item a position of corner



=item x first side



=item y second side



=item z third side



=back



=cut


sub new($$$$)
 {my ($a, $x, $y, $z) = vectorCheck(@_);
  bless {a=>$a, x=>$x, y=>$y, z=>$z}; 
 }


=head3 cube

Synonym for L</new>

=cut


sub cube($$$$) {new($_[0], $_[1], $_[2], $_[3])};


=head3 unit

Unit cube                   

=cut


sub unit()
 {cube(vector(0,0,0), vector(1,0,0), vector(0,1,0), vector(0,0,1));
 }


=head2 Methods


=head3 Check

Check that an anonymous reference is a reference to a cube and confess
if it is not.

=cut


sub check(@)
 {for my $c(@_)
   {confess "$c is not a cube" unless ref($c) eq __PACKAGE__;
   }
  return (@_)
 }


=head3 is

Same as L</check> but return the result to the caller.   

=cut


sub is(@)
 {for my $r(@_)
   {return 0 unless ref($r) eq __PACKAGE__;
   }
  'cube';
 }


=head3 a, x, y, z

Components of cube

=cut


sub a($) {my ($c) = check(@_); $c->{a}}
sub x($) {my ($c) = check(@_); $c->{x}}
sub y($) {my ($c) = check(@_); $c->{y}}
sub z($) {my ($c) = check(@_); $c->{z}}


=head3 Clone

Create a cube from another cube

=cut


sub clone($)
 {my ($c) = check(@_); # Cube
  bless {a=>$c->a, x=>$c->x, y=>$c->y, z=>$c->z};
 }


=head3 Accuracy

Get/Set accuracy for comparisons

=cut


my $accuracy = 1e-10;

sub accuracy
 {return $accuracy unless scalar(@_);
  $accuracy = shift();
 }


=head3 Add

Add a vector to a cube                   

=cut


sub add($$)
 {my ($c) =       check(@_[0..0]); # Cube       
  my ($v) = vectorCheck(@_[1..1]); # Vector     
  new($c->a+$v, $c->x, $c->y, $c->z);                         
 }


=head3 Subtract

Subtract a vector from a cube                   

=cut


sub subtract($$)
 {my ($c) =       check(@_[0..0]); # Cube       
  my ($v) = vectorCheck(@_[1..1]); # Vector     
  new($c->a-$v, $c->x, $c->y, $c->z);                         
 }


=head3 Multiply

Cube times a scalar

=cut


sub multiply($$)
 {my ($a) = check(@_[0..0]); # Cube   
  my ($b) =       @_[1..1];  # Scalar
  
  new($a->a, $a->x*$b, $a->y*$b, $a->z*$b);
 }


=head3 Divide

Cube divided by a non zero scalar

=cut


sub divide($$)
 {my ($a) = check(@_[0..0]); # Cube   
  my ($b) =       @_[1..1];  # Scalar
  
  confess "$b is zero" if $b == 0;
  new($a->a, $a->x/$b, $a->y/$b, $a->z/$b);
 }


=head3 Print

Print cube     

=cut


sub print($)
 {my ($t) = check(@_); # Cube       
  my ($a, $x, $y, $z) = ($t->a, $t->x, $t->y, $t->z);
  "cube($a, $x, $y, $z)";
 }


=head3 Triangulate

Triangulate cube

=cut


sub triangulate($$)
 {my ($c)     = check(@_[0..0]); # Cube
  my ($color) =       @_[1..1];  # Color           
  my  $plane;                    # Plane    
   
  my @t;
  $plane = unique();           
  push @t, {triangle=>triangle($c->a,                   $c->a+$c->x,       $c->a+$c->y),       color=>$color, plane=>$plane};
  push @t, {triangle=>triangle($c->a+$c->x+$c->y,       $c->a+$c->x,       $c->a+$c->y),       color=>$color, plane=>$plane};
  $plane = unique();           
  push @t, {triangle=>triangle($c->a+$c->z,             $c->a+$c->x+$c->z, $c->a+$c->y+$c->z), color=>$color, plane=>$plane};
  push @t, {triangle=>triangle($c->a+$c->x+$c->y+$c->z, $c->a+$c->x+$c->z, $c->a+$c->y+$c->z), color=>$color, plane=>$plane};

# x y z 
# y z x
  $plane = unique();           
  push @t, {triangle=>triangle($c->a,                   $c->a+$c->y,       $c->a+$c->z),       color=>$color, plane=>$plane};
  push @t, {triangle=>triangle($c->a+$c->y+$c->z,       $c->a+$c->y,       $c->a+$c->z),       color=>$color, plane=>$plane};
  $plane = unique();           
  push @t, {triangle=>triangle($c->a+$c->x,             $c->a+$c->y+$c->x, $c->a+$c->z+$c->x), color=>$color, plane=>$plane};
  push @t, {triangle=>triangle($c->a+$c->y+$c->z+$c->x, $c->a+$c->y+$c->x, $c->a+$c->z+$c->x), color=>$color, plane=>$plane};

# x y z 
# z x y
  $plane = unique();           
  push @t, {triangle=>triangle($c->a,                   $c->a+$c->z,       $c->a+$c->x),       color=>$color, plane=>$plane};
  push @t, {triangle=>triangle($c->a+$c->z+$c->x,       $c->a+$c->z,       $c->a+$c->x),       color=>$color, plane=>$plane};
  $plane = unique();           
  push @t, {triangle=>triangle($c->a+$c->y,             $c->a+$c->z+$c->y, $c->a+$c->x+$c->y), color=>$color, plane=>$plane};
  push @t, {triangle=>triangle($c->a+$c->z+$c->x+$c->y, $c->a+$c->z+$c->y, $c->a+$c->x+$c->y), color=>$color, plane=>$plane};
  @t;
 }

unless (caller())
 {$c = cube(vector(0,0,0), vector(1,0,0), vector(0,1,0), vector(0,0,1));
  @t = $c->triangulate('red');
  print "Done";
 }


=head2 Operator Overloads

Operator overloads

=cut


use overload
 '+',       => \&add3,      # Add a vector
 '-',       => \&sub3,      # Subtract a vector
 '*',       => \&multiply3, # Multiply by scalar
 '/',       => \&divide3,   # Divide by scalar 
 '=='       => \&equals3,   # Equals
 '""'       => \&print3,    # Print
 'fallback' => FALSE;


=head3 Add

Add operator.

=cut

sub add3
 {my ($a, $b, $c) = @_;
  return $a->add($b);
 }


=head3 Subtract

Subtract operator.

=cut


sub sub3
 {my ($a, $b, $c) = @_;
  return $a->subtract($b);
 }


=head3 Multiply

Multiply operator.

=cut


sub multiply3
 {my ($a, $b) = @_;
  return $a->multiply($b);
 }


=head3 Divide

Divide operator.

=cut


sub divide3
 {my ($a, $b, $c) = @_;
  return $a->divide($b);
 }


=head3 Equals

Equals operator.

=cut


sub equals3
 {my ($a, $b, $c) = @_;
  return $a->equals($b);
 }


=head3 Print

Print a cube

=cut


sub print3
 {my ($a) = @_;
  return $a->print;
 }


=head2 Exports

Export L</cube>, L</unit>

=cut


use Math::Zap::Exports qw(                               
  cube ($$$)  
  unit ()
 );

#______________________________________________________________________
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
