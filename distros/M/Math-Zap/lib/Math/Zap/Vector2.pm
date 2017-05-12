
=head1 Vector2

Manipulate 2D vectors    
    
PhilipRBrenan@yahoo.com, 2004, Perl License


=head2 Synopsis

Example t/vector2.t

 #_ Vector _____________________________________________________________
 # Test 2d vectors    
 # philiprbrenan@yahoo.com, 2004, Perl License    
 #______________________________________________________________________
 
 use Math::Zap::Vector2 vector2=>v, units=>u;
 use Test::Simple tests=>7;
 
 my ($x, $y) = u();
 
 ok(!$x                    == 1);
 ok(2*$x+3*$y              == v( 2,  3));
 ok(-$x-$y                 == v(-1, -1));
 ok((2*$x+3*$y) + (-$x-$y) == v( 1,  2));
 ok((2*$x+3*$y) * (-$x-$y) == -5);  
 ok($x*2                   == v( 2,  0));
 ok($y/2                   == v( 0,  0.5));
 


=head2 Description

Manipulate 2D vectors    

=cut


package Math::Zap::Vector2; 
$VERSION=1.07;
use Math::Trig;
use Carp;
use constant debug => 0; # Debugging level


=head2 Constructors


=head3 new

Create a vector from numbers

=cut


sub new($$)
 {return bless {x=>$_[0], y=>$_[1]} unless debug;
  my ($x, $y) = @_; 
  round(bless({x=>$x, y=>$y})); 
 }


=head3 vector2

Create a vector from numbers - synonym for L</new>

=cut


sub vector2($$) {new($_[0],$_[1])}


=head3 units

Unit vectors                                        

=cut


$x = new(1,0);
$y = new(0,1);

sub units() {($x, $y)}


=head2 Methods


=head3 check

Check its a vector

=cut


sub check(@)
 {if (debug)
   {for my $v(@_)
     {confess "$v is not a vector2" unless ref($v) eq __PACKAGE__;
     }
   }
  return (@_)
 }


=head3 is

Test its a vector

=cut


sub is(@)
 {for my $v(@_)
   {return 0 unless ref($v) eq __PACKAGE__;
   }
  1;
 }


=head3 accuracy

Get/Set accuracy for comparisons

=cut


my $accuracy = 1e-10;

sub accuracy
 {return $accuracy unless scalar(@_);
  $accuracy = shift();
 }


=head3 round

Round: round to nearest integer if within accuracy of that integer 

=cut


sub round($)
 {unless (debug)
   {return $_[0];
   }
  else
   {my ($a) = @_;
    for my $k(keys(%$a))
     {my $n = $a->{$k};
      my $N = int($n);
      $a->{$k} = $N if abs($n-$N) < $accuracy;
     }
    return $a;
   }
 }


=head3 components

x,y components of vector

=cut


sub x($) {check(@_) if debug; $_[0]->{x}}
sub y($) {check(@_) if debug; $_[0]->{y}}


=head3 clone

Create a vector from another vector

=cut


sub clone($)
 {my ($v) = check(@_); # Vectors
  round bless {x=>$v->x, y=>$v->y}; 
 }


=head3 length

Length of a vector

=cut


sub length($)
 {check(@_[0..0]) if debug; # Vectors
  sqrt($_[0]->{x}**2+$_[0]->{y}**2);
 } 


=head3 print

Print vector

=cut


sub print($)
 {my ($v) = check(@_); # Vectors
  my ($x, $y) = ($v->x, $v->y);

  "vector2($x, $y)";
 } 


=head3 normalize

Normalize vector

=cut


sub norm($)
 {my ($v) = check(@_); # Vectors
  my $l = $v->length;

  $l > 0 or confess "Cannot normalize zero length vector $v";

  new($v->x / $l, $v->y / $l);
 }


=head3 rightAngle

At right angles

=cut


sub rightAngle($)
 {my ($v) = check(@_); # Vectors
  new(-$v->y, $v->x);
 } 


=head3 dot

Dot product

=cut


sub dot($$)
 {my ($a, $b) = check(@_); # Vectors
  $a->x*$b->x+$a->y*$b->y;
 } 


=head3 angle

Angle between two vectors

=cut


sub angle($$)
 {my ($a, $b) = check(@_); # Vectors
  acos($a->norm->dot($b->norm));
 } 


=head3 add

Add vectors

=cut


sub add($$)
 {my ($a, $b) = check(@_); # Vectors
  new($a->x+$b->x, $a->y+$b->y);
 }


=head3 subtract

Subtract vectors

=cut


sub subtract($$)
 {check(@_) if debug; # Vectors
  new($_[0]->{x}-$_[1]->{x}, $_[0]->{y}-$_[1]->{y});
 }


=head3 multiply

Vector times a scalar

=cut


sub multiply($$)
 {my ($a) = check(@_[0..0]); # Vector 
  my ($b) =       @_[1..1];  # Scalar
  
  confess "$b is not a scalar" if ref($b);
  new($a->x*$b, $a->y*$b);
 }


=head3 divide

Vector divided by a non zero scalar

=cut


sub divide($$)
 {my ($a) = check(@_[0..0]); # Vector 
  my ($b) =       @_[1..1];  # Scalar

  confess "$b is not a scalar" if ref($b);
  confess "$b is zero"         if $b == 0;
  new($a->x/$b, $a->y/$b);
 }


=head3 equals

Equals to within accuracy

=cut


sub equals($$)
 {my ($a, $b) = check(@_); # Vectors
  abs($a->x-$b->x) < $accuracy and
  abs($a->y-$b->y) < $accuracy;
 }


=head2 Operators

# Operator overloads

=cut


use overload
 '+'        => \&add3,      # Add two vectors
 '-'        => \&subtract3, # Subtract one vector from another
 '*'        => \&multiply3, # Times by a scalar, or vector dot product 
 '/'        => \&divide3,   # Divide by a scalar
 '<'        => \&angle3,    # Angle in radians between two vectors
 '>'        => \&angle3,    # Angle in radians between two vectors
 '=='       => \&equals3,   # Equals
 '""'       => \&print3,    # Print
 '!'        => \&length,    # Length
 'fallback' => FALSE;


=head3 add

Add operator.

=cut


sub add3
 {my ($a, $b) = @_;
  $a->add($b);
 }


=head3 subtract

Subtract operator.

=cut


sub subtract3
 {#my ($a, $b, $c) = @_;
  #return $a->subtract($b) if ref($b);
  return new($_[0]->{x}-$_[1]->{x}, $_[0]->{y}-$_[1]->{y}) if ref($_[1]);
  new(-$_[0]->{x}, -$_[0]->{y});
 }


=head3 multiply

Multiply operator.

=cut


sub multiply3
 {my ($a, $b) = @_;
  return $a->dot     ($b) if ref($b);
  return $a->multiply($b);
 }


=head3 divide

Divide operator.

=cut


sub divide3
 {my ($a, $b, $c) = @_;
  return $a->divide($b);
 }


=head3 angle

Angle between two vectors.

=cut


sub angle3
 {my ($a, $b, $c) = @_;
  return $a->angle($b);
 }


=head3 equals

Equals operator.

=cut


sub equals3
 {my ($a, $b, $c) = @_;
  return $a->equals($b);
 }


=head3 print

Print a vector.

=cut


sub print3
 {my ($a) = @_;
  return $a->print;
 }


=head2 Exports

Export L</vector2>, L</units>, L</check>, L</is>

=cut


use Math::Zap::Exports qw(                               
  vector2 ($$)  
  units   ()
  check   (@)
  is      (@)
 );

#_ Vector2 ____________________________________________________________
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
