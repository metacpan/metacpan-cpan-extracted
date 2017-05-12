
=head1 Matrix

3*3 matrix manipulation    

PhilipRBrenan@yahoo.com, 2004, Perl License


=head2 Synopsis

Example t/matrix.t

 #_ Matrix _____________________________________________________________
 # Test 3*3 matrices    
 # philiprbrenan@yahoo.com, 2004, Perl License    
 #______________________________________________________________________
 
 use Math::Zap::Matrix identity=>i;
 use Math::Zap::Vector;
 use Test::Simple tests=>8;
 
 my ($a, $b, $c, $v);
 
 $a = matrix
  (8, 0, 0,
   0, 8, 0,
   0, 0, 8
  );
 
 $b = matrix
  (4, 2, 0,
   2, 4, 2,
   0, 2, 4
  );
 
 $c = matrix
  (4, 2, 1,
   2, 4, 2,
   1, 2, 4
  );
 
 $v = vector(1,2,3);
 
 ok($a/$a           == i());
 ok($b/$b           == i());
 ok($c/$c           == i());
 ok(2/$a*$a/2       == i());
 ok(($a+$b)/($a+$b) == i());
 ok(($a-$c)/($a-$c) == i());
 ok(-$a/-$a         == i());
 ok(1/$a*($a*$v)    == $v);
 



=head2 Description

3*3 matrix manipulation    

=cut


package Math::Zap::Matrix;
$VERSION=1.07;
use Math::Zap::Vector check=>'vectorCheck', is=>'vectorIs';
use Carp;
use constant debug => 0; # Debugging level


=head2 Constructors


=head3 new

Create a matrix

=cut


sub new($$$$$$$$$)
 {my
  ($a11, $a12, $a13,
   $a21, $a22, $a23,
   $a31, $a32, $a33,
  ) = @_;

  my $m = round(bless(
   {11=>$a11, 12=>$a12, 13=>$a13,
    21=>$a21, 22=>$a22, 23=>$a23,
    31=>$a31, 32=>$a32, 33=>$a33,
   })); 
  singular($m, 1);
  $m;
 }


=head3 matrix

Create a matrix = synonym for L</new>

=cut


sub matrix($$$$$$$$$)
 {new($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],$_[6],$_[7],$_[8]);
 }


=head3 new3v

Create a matrix from three vectors

=cut


sub new3v($$$)
 {my ($a, $b, $c) = @_; 
  vectorCheck(@_) if debug; 
  my $m = round(bless(
   {11=>$a->x, 12=>$b->x, 13=>$c->x,
    21=>$a->y, 22=>$b->y, 23=>$c->y,
    31=>$a->z, 32=>$b->z, 33=>$c->z,
   }));
  singular($m, 1);
  $m;
 }


=head3 new3vnc

Create a matrix from three vectors without checking

=cut


sub new3vnc($$$)
 {my ($a, $b, $c) = vectorCheck(@_); 
  my $m = round(bless(
   {11=>$a->x, 12=>$b->x, 13=>$c->x,
    21=>$a->y, 22=>$b->y, 23=>$c->y,
    31=>$a->z, 32=>$b->z, 33=>$c->z,
   }));
  $m;
 }


=head2 Methods


=head3 check

Check its a matrix

=cut


sub check(@)
 {if (debug)
   {for my $m(@_)
     {confess "$m is not a matrix" unless ref($m) eq __PACKAGE__;
     }
    }
  return (@_)
 }


=head3 is

Test its a matrix

=cut


sub is(@)
 {for my $m(@_)
   {return 0 unless ref($m) eq __PACKAGE__;
   }
  'matrix';
 }


=head3 singular

Singular matrix?

=cut


sub singular($$)
 {my $m = shift;  # Matrix   
  my $a = 1e-2;   # Accuracy
  my $A = shift;  # Action 0: return indicator, 1: confess 

  my $n = abs
   ($m->{11}*$m->{22}*$m->{33}
   -$m->{11}*$m->{23}*$m->{32}
   -$m->{12}*$m->{21}*$m->{33}
   +$m->{12}*$m->{23}*$m->{31}
   +$m->{13}*$m->{21}*$m->{32}
   -$m->{13}*$m->{22}*$m->{31})
   < $a;
  confess "Singular matrix2" if $n and $A;
  $n;      
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
 {my ($a) = @_;
  check(@_) if debug; 
  my ($n, $N);
  for my $k(qw(11 12 13  21 22 23 31 32 33))
   {$n = $a->{$k};
    $N = int($n);
    $a->{$k} = $N if abs($n-$N) < $accuracy;
   }
  $a;
 }


=head3 clone

Create a matrix from another matrix

=cut


sub clone($)
 {my ($m) = check(@_); # Matrix
  round bless
   {11=>$m->{11}, 12=>$m->{12}, 13=>$m->{13},
    21=>$m->{21}, 22=>$m->{22}, 23=>$m->{23},
    31=>$m->{31}, 32=>$m->{32}, 33=>$m->{33},
   }; 
 }


=head3 print

Print matrix

=cut


sub print($)
 {my ($m) = check(@_); # Matrix 
  'matrix('.$m->{11}.', '.$m->{12}.', '.$m->{13}.
       ', '.$m->{21}.', '.$m->{22}.', '.$m->{23}.
       ', '.$m->{31}.', '.$m->{32}.', '.$m->{33}.
  ')';
 } 


=head3 add

Add matrices

=cut


sub add($$)
 {my ($a, $b) = check(@_); # Matrices
  round bless
   {11=>$a->{11}+$b->{11}, 12=>$a->{12}+$b->{12}, 13=>$a->{13}+$b->{13},
    21=>$a->{21}+$b->{21}, 22=>$a->{22}+$b->{22}, 23=>$a->{23}+$b->{23},
    31=>$a->{31}+$b->{31}, 32=>$a->{32}+$b->{32}, 33=>$a->{33}+$b->{33},
   }; 
 }


=head3 negate

Negate matrix

=cut


sub negate($)
 {my ($a) = check(@_); # Matrices
  round bless
   {11=>-$a->{11}, 12=>-$a->{12}, 13=>-$a->{13},
    21=>-$a->{21}, 22=>-$a->{22}, 23=>-$a->{23},
    31=>-$a->{31}, 32=>-$a->{32}, 33=>-$a->{33},
   }; 
 }


=head3 subtract

Subtract matrices

=cut


sub subtract($$)
 {my ($a, $b) = check(@_); # Matrices
  round bless
   {11=>$a->{11}-$b->{11}, 12=>$a->{12}-$b->{12}, 13=>$a->{13}-$b->{13},
    21=>$a->{21}-$b->{21}, 22=>$a->{22}-$b->{22}, 23=>$a->{23}-$b->{23},
    31=>$a->{31}-$b->{31}, 32=>$a->{32}-$b->{32}, 33=>$a->{33}-$b->{33},
   }; 
 }


=head3 matrixVectorMultiply

Vector = Matrix * Vector     

=cut


sub matrixVectorMultiply($$)
 {my ($a) =       check(@_[0..0]); # Matrix
  my ($b) = vectorCheck(@_[1..1]); # Vector 
  vector
   ($a->{11}*$b->x+$a->{12}*$b->y+$a->{13}*$b->z,
    $a->{21}*$b->x+$a->{22}*$b->y+$a->{23}*$b->z,
    $a->{31}*$b->x+$a->{32}*$b->y+$a->{33}*$b->z,
   );
 }


=head3 matrixScalarMultiply

Matrix = Matrix * scalar      

=cut


sub matrixScalarMultiply($$)
 {my ($a) = check(@_[0..0]); # Matrix
  my ($b) =       @_[1..1];  # Scalar
  confess "$b is not a scalar" if ref($b);   
  round bless
   {11=>$a->{11}*$b, 12=>$a->{12}*$b, 13=>$a->{13}*$b,
    21=>$a->{21}*$b, 22=>$a->{22}*$b, 23=>$a->{23}*$b,
    31=>$a->{31}*$b, 32=>$a->{32}*$b, 33=>$a->{33}*$b,
   }; 
 }


=head3 matrixMatrixMultiply

Matrix = Matrix * Matrix      

=cut


sub matrixMatrixMultiply($$)
 {my ($a, $b) = check(@_); # Matrices
  round bless
   {11=>$a->{11}*$b->{11}+$a->{12}*$b->{21}+$a->{13}*$b->{31}, 12=>$a->{11}*$b->{12}+$a->{12}*$b->{22}+$a->{13}*$b->{32}, 13=>$a->{11}*$b->{13}+$a->{12}*$b->{23}+$a->{13}*$b->{33},
    21=>$a->{21}*$b->{11}+$a->{22}*$b->{21}+$a->{23}*$b->{31}, 22=>$a->{21}*$b->{12}+$a->{22}*$b->{22}+$a->{23}*$b->{32}, 23=>$a->{21}*$b->{13}+$a->{22}*$b->{23}+$a->{23}*$b->{33},
    31=>$a->{31}*$b->{11}+$a->{32}*$b->{21}+$a->{33}*$b->{31}, 32=>$a->{31}*$b->{12}+$a->{32}*$b->{22}+$a->{33}*$b->{32}, 33=>$a->{31}*$b->{13}+$a->{32}*$b->{23}+$a->{33}*$b->{33},
   }; 
 }


=head3 matrixScalarDivide

Matrix=Matrix / non zero scalar

=cut


sub matrixScalarDivide($$)
 {my ($a) = check(@_[0..0]); # Matrices
  my ($b) = @_[1..1];        # Scalar
  confess "$b is not a scalar" if ref($b);   
  confess "$b is zero"         if $b == 0;   
  round bless
   {11=>$a->{11}/$b, 12=>$a->{12}/$b, 13=>$a->{13}/$b,
    21=>$a->{21}/$b, 22=>$a->{22}/$b, 23=>$a->{23}/$b,
    31=>$a->{31}/$b, 32=>$a->{32}/$b, 33=>$a->{33}/$b,
   }; 
 }


=head3 det

Determinant of matrix.

=cut


sub det($)
 {my ($a) = @_;       # Matrix
  check(@_) if debug; # Check

+$a->{11}*$a->{22}*$a->{33}
-$a->{11}*$a->{23}*$a->{32}
-$a->{12}*$a->{21}*$a->{33}
+$a->{12}*$a->{23}*$a->{31}
+$a->{13}*$a->{21}*$a->{32}
-$a->{13}*$a->{22}*$a->{31};
 }


=head3 d2

Determinant of 2*2 matrix

=cut


sub d2($$$$)
 {my ($a, $b, $c, $d) = @_;    
  $a*$d-$b*$c;
 }


=head3 inverse

Inverse of matrix

=cut


sub inverse($)
 {my ($a) = @_;       # Matrix
  check(@_) if debug; # Check
  return $a->{inverse} if defined($a->{inverse});

  my $d = det($a);
  return undef if $d == 0;

  my $i = round bless
   {11=>d2($a->{22}, $a->{32}, $a->{23}, $a->{33})/$d,
    21=>d2($a->{23}, $a->{33}, $a->{21}, $a->{31})/$d,
    31=>d2($a->{21}, $a->{31}, $a->{22}, $a->{32})/$d,

    12=>d2($a->{13}, $a->{33}, $a->{12}, $a->{32})/$d,
    22=>d2($a->{11}, $a->{31}, $a->{13}, $a->{33})/$d,
    32=>d2($a->{12}, $a->{32}, $a->{11}, $a->{31})/$d,

    13=>d2($a->{12}, $a->{22}, $a->{13}, $a->{23})/$d,
    23=>d2($a->{13}, $a->{23}, $a->{11}, $a->{21})/$d,
    33=>d2($a->{11}, $a->{21}, $a->{12}, $a->{22})/$d,
   };
  $a->{inverse} = $i;
  $i;
 }


=head3 identity

Identity matrix

=cut


sub identity()
 {bless
   {11=>1, 21=>0, 31=>0,                              
    12=>0, 22=>1, 32=>0,                              
    13=>0, 23=>0, 33=>1,
   }; 
 }


=head3 equals

Equals to within accuracy

=cut


sub equals($$)
 {my ($a, $b) = check(@_); # Matrices
  abs($a->{11}-$b->{11}) < $accuracy and
  abs($a->{12}-$b->{12}) < $accuracy and
  abs($a->{13}-$b->{13}) < $accuracy and

  abs($a->{21}-$b->{21}) < $accuracy and
  abs($a->{22}-$b->{22}) < $accuracy and
  abs($a->{23}-$b->{23}) < $accuracy and

  abs($a->{31}-$b->{31}) < $accuracy and
  abs($a->{32}-$b->{32}) < $accuracy and
  abs($a->{33}-$b->{33}) < $accuracy;
 }


=head3 Operator

Operator overloads

=cut


use overload
 '+'        => \&add3,      # Add two vectors
 '-'        => \&subtract3, # Subtract one vector from another
 '*'        => \&multiply3, # Times by a scalar, or vector dot product 
 '/'        => \&divide3,   # Divide by a scalar
 '!'        => \&det3,      # Determinant                       
 '=='       => \&equals3,   # Equals (to accuracy)
 '""'       => \&print3,    # Print
 'fallback' => FALSE;


=head3 Add operator

Add operator.

=cut


sub add3
 {my ($a, $b) = @_;
  $a->add($b);
 }


=head3 subtract operator

Negate operator.

=cut


sub subtract3
 {my ($a, $b, $c) = @_;

  return $a->subtract($b) if $b;
  negate($a);
 }


=head3 multiply operator

Multiply operator.

=cut


sub multiply3
 {my ($a, $b) = @_;
  return $a->matrixScalarMultiply($b) unless ref($b);
  return $a->matrixVectorMultiply($b) if vectorIs($b);
  return $a->matrixMatrixMultiply($b) if is($b);
  confess "Cannot multiply $a by $b\n";
 }


=head3 divide operator

Divide operator.

=cut


sub divide3
 {my ($a, $b, $c) = @_;
  if (!ref($b))
   {return $a->matrixScalarDivide($b)            unless $c;
    return $a->inverse->matrixScalarMultiply($b) if     $c;
   }
  else 
   {return $a->inverse->matrixVectorMultiply($b) if vectorIs($b);
    return $a->matrixMatrixMultiply($b->inverse) if is($b);
    confess "Cannot multiply $a by $b\n";
   }
 }


=head3 equals operator

Equals operator.

=cut


sub equals3
 {my ($a, $b, $c) = @_;
  return $a->equals($b);
 }


=head3 det operator

Determinant of a matrix

=cut


sub det3
 {my ($a, $b, $c) = @_;
  $a->det;
 }


=head3 print vector

Print a vector.

=cut


sub print3
 {my ($a) = @_;
  return $a->print;
 }


=head2 Exports

Export L</matrix>, L</identity>, L</new3v>, L</new3vnc>

=cut


use Math::Zap::Exports qw(
  matrix   ($$$$$$$$$)
  identity ()
  new3v    ($$$)
  new3vnc  ($$$)
 );

#_ Matrix _____________________________________________________________
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
