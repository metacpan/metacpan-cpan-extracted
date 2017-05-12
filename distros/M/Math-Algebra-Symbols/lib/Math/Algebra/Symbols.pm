=pod

=head1 Name

  Math::Algebra::Symbols

=head1 Synopsis

  Symbolic Algebra in Pure Perl

  use Math::Algebra::Symbols hyper=>1;
  use Test::Simple tests=>5;

  ($n, $x, $y) = symbols(qw(n x y));

  $a     += ($x**8 - 1)/($x-1);
  $b     +=  sin($x)**2 + cos($x)**2;
  $c     += (sin($n*$x) + cos($n*$x))->d->d->d->d / (sin($n*$x)+cos($n*$x));
  $d      =  tanh($x+$y) == (tanh($x)+tanh($y))/(1+tanh($x)*tanh($y));
  ($e,$f) =  @{($x**2 eq 5*$x-6) > $x};

  print "$a\n$b\n$c\n$d\n$e,$f\n";

  ok("$a"    eq '$x+$x**2+$x**3+$x**4+$x**5+$x**6+$x**7+1');
  ok("$b"    eq '1');
  ok("$c"    eq '$n**4');
  ok("$d"    eq '1');
  ok("$e,$f" eq '2,3');

  The focii to locus round trip of an ellipse has a length of twice the
  major radius:

  use Math::Algebra::Symbols;
  use Test::More tests => 1;
  my ($R, $f, $x, $i) = symbols(qw(R f x i)); # Major radius, focii

  my $y  = sqrt($R*$R-$f*$f - $x*$x +$f*$f*$x*$x / ($R*$R));  # Ellipse: rr=RR-ff
  my $a = $x+$i*$y - $f;            # Vector from focus1 to a point on the locus
  my $b = $x+$i*$y + $f;            # Vector from focus2 to same point on the locus

  ok(abs($a) + abs($b) ==  2*$R, 'Focus trip is constant 2R');

  Floating point calculations on a triangle with angles of 22.5, 45, 112.5
  degrees to determine whether two of the diameters of the nine point circle
  are at right angles yield (on my computer) the following inconclusive result
  when the dot product between the diameters is formed numerically:

  my $o = 1;
  my $a = sqrt($o/2);                              # X position of apex
  my $b = $o - $a;                                 # Y position of apex
  my $s = ($a*$a+$b*$b-$a)/2/$b;
  my ($nx, $ny) = ($o/4 + $a/2, $b/2 - $s/2);      # Nine point centre
  my ($px, $py) = ($o/2, 0);                       # Diameter from mid point
  my ($qx, $qy) = ($o/2 + $a/2, $b/2);             # Diameter from mid point

  my $d = ($px-$nx)*($qx-$nx)+($py-$ny)*($qy-$ny); # Dot product should be zero
  print +($d == 0)||0, "\n$d\n";                   # Definitively zero if 1

  # 0                                              # Not exactly zero
  # -6.93889390390723e-18                          # Is this significant or not?

  By contrast with Math::Algebra::Symbols I get the much more convincing:

  my ($o, $i) = symbols(qw(1 i));                  # Units in x,y
  my $a = sqrt($o/2);                              # X position of apex
  my $b = $o - $a;                                 # Y position of apex
  my $s = ($a*$a+$b*$b-$a)/2/$b;
  my $n = $o/4 + $a/2 +$i*($b/2 - $s/2);           # Nine point centre
  my $p = $o/2;                                    # Diameter from mid point
  my $q = $o/2 + $a/2 +$i* $b/2;                   # Diameter from mid point

  my $d = (($p-$n) ^ ($q-$n));                     # Dot product should be zero
  print +($d == 0)||0, "\n$d\n";                   # Definitively zero if 1

  # 1
  # 17/32/(-2*sqrt(1/2)+3/2)-3/4/(-2*sqrt(1/2)+3/2)*sqrt(1/2)-7/16/(-sqrt(1/2)+1)
  # +5/8/(-sqrt(1/2)+1)*sqrt(1/2)-1/8*sqrt(1/2)+1/16

=head1 Description

  This package supplies a set of functions and operators to manipulate operator
  expressions algebraically using the familiar Perl syntax.

  These expressions are constructed from L</Symbols>, L</Operators>, and
  L</Functions>, and processed via L</Methods>.  For examples, see:
  L</Examples>.

=head2 Symbols

  Symbols are created with the exported B<symbols()> constructor routine:

  use Math::Algebra::Symbols;
  use Test::Simple tests=>1;

  my ($x, $y, $i, $o, $pi) = symbols(qw(x y i 1 pi));

  ok( "$x $y $i $o $pi"   eq   '$x $y i 1 $pi'  );

  The B<symbols()> routine constructs references to symbolic variables and
  symbolic constants from a list of names and integer constants.

  It is often useful to declare a variable B<$o> to contain the unit B<1> with
  which to start symbolic expressions, thus:

  $o/2 is a symbolic expression for one half where-as:

  1/2 == 0.5 is merely the numeric representation of one half.

  The special symbol B<i> is recognized as the square root of B<-1>.

  The special symbol B<pi> is recognized as the smallest positive real that
  satisfies:

  use Math::Algebra::Symbols;
  use Test::Simple tests=>2;

  my ($i, $pi) = symbols(qw(i pi));

  ok(  exp($i*$pi)  ==   -1  );
  ok(  exp($i*$pi) <=>  '-1' );

=head3 Constructor Routine Name

  If you wish to use a different name for the constructor routine, say
  B<S>:

  use Math::Algebra::Symbols symbols=>'S';
  use Test::Simple tests=>2;

  my ($i, $pi) = S(qw(i pi));

  ok(  exp($i*$pi)  ==   -1  );
  ok(  exp($i*$pi) <=//>  '-1' );


=head3 Big Integers

  Symbols automatically uses big integers if needed.

  use Math::Algebra::Symbols;
  use Test::Simple tests=>1;

  my $z = symbols('1234567890987654321/1234567890987654321');

  ok( eval $z eq '1');

=head2 Operators

  L</Symbols> can be combined with L</Operators> to create symbolic
  expressions:

=head3 Arithmetic operators


=head4 Arithmetic Operators: B<+> B<-> B<*> B</> B<**>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>3;

  my ($x, $y) = symbols(qw(x y));

  ok(  ($x**2-$y**2)/($x-$y)  ==  $x+$y  );
  ok(  ($x**2-$y**2)/($x-$y)  !=  $x-$y  );
  ok(  ($x**2-$y**2)/($x-$y) <=> '$x+$y' );

  The operators: B<+=> B<-=> B<*=> B</=> are overloaded to work symbolically
  rather than numerically. If you need numeric results, you can always
  B<eval()> the resulting symbolic expression.

=head4 Square root Operator: B<sqrt>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>2;

  my ($x, $i) = symbols(qw(x i));

  ok(  sqrt(-$x**2)  ==  $i*$x  );
  ok(  sqrt(-$x**2)  <=> 'i*$x' );

  The square root is represented by the symbol B<i>, which allows complex
  expressions to be processed by Math::Complex.

=head4 Exponential Operator: B<exp>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>2;

  my ($x, $i) = symbols(qw(x i));

  ok(   exp($x)->d($x)  ==   exp($x)  );
  ok(   exp($x)->d($x) <=>  'exp($x)' );

  The exponential operator.

=head4 Logarithm Operator: B<log>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>1;

  my ($x) = symbols(qw(x));

  ok(   log($x) <=>  'log($x)' );

  Logarithm to base B<e>.

  Note: the above result is only true for x > 0.  B<Symbols> does not include
  domain and range specifications of the functions it uses.

=head4 Sine and Cosine Operators: B<sin> and B<cos>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>3;

  my ($x) = symbols(qw(x));

  ok(  sin($x)**2 + cos($x)**2  ==  1  );
  ok(  sin($x)**2 + cos($x)**2  !=  0  );
  ok(  sin($x)**2 + cos($x)**2 <=> '1' );

  This famous trigonometric identity is not preprogrammed into B<Symbols> as it
  is in commercial products.

  Instead: an expression for B<sin()> is constructed using the complex
  exponential: L</exp>, said expression is algebraically multiplied out to
  prove the identity. The proof steps involve large intermediate expressions in
  each step, as yet I have not provided a means to neatly lay out these
  intermediate steps and thus provide a more compelling demonstration of the
  ability of B<Symbols> to verify such statements from first principles.

=head3 Relational operators

=head4 Relational operators: B<==>, B<!=>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>3;

  my ($x, $y) = symbols(qw(x y));

  ok(  ($x**2-$y**2)/($x-$y)  ==  $x+$y  );
  ok(  ($x**2-$y**2)/($x-$y)  !=  $x-$y  );
  ok(  ($x**2-$y**2)/($x-$y) <=> '$x+$y' );

  The relational equality operator B<==> compares two symbolic expressions and
  returns TRUE(1) or FALSE(0) accordingly. B<!=> produces the opposite result.

=head4 Relational operator: B<eq>

  my ($x, $v, $t) = symbols(qw(x v t));

  ok(  ($v eq $x / $t)->solve(qw(x in terms of v t))  ==  $v*$t  );
  ok(  ($v eq $x / $t)->solve(qw(x in terms of v t))  !=  $v+$t  );
  ok(  ($v eq $x / $t)->solve(qw(x in terms of v t)) <=> '$t*$v' );

  The relational operator B<eq> is a synonym for the minus B<-> operator, with
  the expectation that later on the L<solve()|/Solving equations> function will
  be used to simplify and rearrange the equation. You may prefer to use B<eq>
  instead of B<-> to enhance readability, there is no functional difference.

=head3 Complex operators

=head4 Complex operators: the B<dot> operator: B<^>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>3;

  my ($a, $b, $i) = symbols(qw(a b i));

  ok(  (($a+$i*$b)^($a-$i*$b))  ==  $a**2-$b**2  );
  ok(  (($a+$i*$b)^($a-$i*$b))  !=  $a**2+$b**2  );
  ok(  (($a+$i*$b)^($a-$i*$b)) <=> '$a**2-$b**2' );

  Please note the use of brackets:  The B<^> operator has low priority.

  The B<^> operator treats its left hand and right hand arguments as complex
  numbers, which in turn are regarded as two dimensional vectors to which the
  vector dot product is applied.

=head4 Complex operators: the B<cross> operator: B<x>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>3;

  my ($x, $i) = symbols(qw(x i));

  ok(  $i*$x x $x  ==  $x**2  );
  ok(  $i*$x x $x  !=  $x**3  );
  ok(  $i*$x x $x <=> '$x**2' );

  The B<x> operator treats its left hand and right hand arguments as complex
  numbers, which in turn are regarded as two dimensional vectors defining the
  sides of a parallelogram. The B<x> operator returns the area of this
  parallelogram.

  Note the space before the B<x>, otherwise Perl is unable to disambiguate the
  expression correctly.

=head4 Complex operators: the B<conjugate> operator: B<~>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>3;

  my ($x, $y, $i) = symbols(qw(x y i));

  ok(  ~($x+$i*$y)  ==  $x-$i*$y  );
  ok(  ~($x-$i*$y)  ==  $x+$i*$y  );
  ok(  (($x+$i*$y)^($x-$i*$y)) <=> '$x**2-$y**2' );

  The B<~> operator returns the complex conjugate of its right hand side.

=head4 Complex operators: the B<modulus> operator: B<abs>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>3;

  my ($x, $i) = symbols(qw(x i));

  ok(  abs($x+$i*$x)  ==  sqrt(2*$x**2)  );
  ok(  abs($x+$i*$x)  !=  sqrt(2*$x**3)  );
  ok(  abs($x+$i*$x) <=> 'sqrt(2*$x**2)' );

  The B<abs> operator returns the modulus (length) of its right hand side.

=head4 Complex operators: the B<unit> operator: B<!>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>4;

  my ($i) = symbols(qw(i));

  ok(  !$i      == $i                         );
  ok(  !$i     <=> 'i'                        );
  ok(  !($i+1) <=>  '1/(sqrt(2))+i/(sqrt(2))' );
  ok(  !($i-1) <=> '-1/(sqrt(2))+i/(sqrt(2))' );

  The B<!> operator returns a complex number of unit length pointing in the
  same direction as its right hand side.

=head3 Equation Manipulation Operators

=head4 Equation Manipulation Operators: B<Simplify> operator: B<+=>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>2;

  my ($x) = symbols(qw(x));

  ok(  ($x**8 - 1)/($x-1)  ==  $x+$x**2+$x**3+$x**4+$x**5+$x**6+$x**7+1  );
  ok(  ($x**8 - 1)/($x-1) <=> '$x+$x**2+$x**3+$x**4+$x**5+$x**6+$x**7+1' );

  The simplify operator B<+=> is a synonym for the
  L<simplify()|/"simplifying_equations:_simplify()"> method, if and only if,
  the target on the left hand side initially has a value of undef.

  Admittedly this is very strange behaviour: it arises due to the shortage of
  over-ride-able operators in Perl: in particular it arises due to the shortage
  of over-ride-able unary operators in Perl. Never-the-less: this operator is
  useful as can be seen in the L<Synopsis|/"synopsis">, and the desired
  pre-condition can always achieved by using B<my>.

=head4 Equation Manipulation Operators: B<Solve> operator: B<E<gt>>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>2;

  my ($t) = symbols(qw(t));

  my $rabbit  = 10 + 5 * $t;
  my $fox     = 7 * $t * $t;
  my ($a, $b) = @{($rabbit eq $fox) > $t};

  ok( "$a" eq  '1/14*sqrt(305)+5/14'  );
  ok( "$b" eq '-1/14*sqrt(305)+5/14'  );

  The solve operator B<E<gt>> is a synonym for the
  L<solve()|/"Solving_equations:_solve()"> method.

  The priority of B<E<gt>> is higher than that of B<eq>, so the brackets around
  the equation to be solved are necessary until Perl provides a mechanism for
  adjusting operator priority (cf. Algol 68).

  If the equation is in a single variable, the single variable may be named
  after the B<E<gt>> operator without the use of [...]:

  use Math::Algebra::Symbols;

  my $rabbit  = 10 + 5 * $t;
  my $fox     = 7 * $t * $t;
  my ($a, $b) = @{($rabbit eq $fox) > $t};

  print "$a\n";

  # 1/14*sqrt(305)+5/14

  If there are multiple solutions, (as in the case of polynomials), B<E<gt>>
  returns an array of symbolic expressions containing the solutions.

  This example was provided by Mike Schilli m@perlmeister.com.

=head2 Functions

  Perl operator overloading is very useful for producing compact
  representations of algebraic expressions. Unfortunately there are only a
  small number of operators that Perl allows to be overloaded. The following
  functions are used to provide capabilities not easily expressed via Perl
  operator overloading.

  These functions may either be called as methods from symbols constructed by
  the L</Symbols> construction routine, or they may be exported into the user's
  name space as described in L</EXPORT>.

=head3 Trigonometric and Hyperbolic functions

=head4 Trigonometric functions

  use Math::Algebra::Symbols;
  use Test::Simple tests=>1;

  my ($x, $y) = symbols(qw(x y));

  ok( (sin($x)**2 == (1-cos(2*$x))/2) );

  The trigonometric functions B<cos>, B<sin>, B<tan>, B<sec>, B<csc>, B<cot>
  are available, either as exports to the caller's name space, or as methods.

=head4 Hyperbolic functions

  use Math::Algebra::Symbols hyper=>1;
  use Test::Simple tests=>1;

  my ($x, $y) = symbols(qw(x y));

  ok( tanh($x+$y)==(tanh($x)+tanh($y))/(1+tanh($x)*tanh($y)));

  The hyperbolic functions B<cosh>, B<sinh>, B<tanh>, B<sech>, B<csch>, B<coth>
  are available, either as exports to the caller's name space, or as methods.

=head3 Complex functions

=head4 Complex functions: B<re> and B<im>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>2;

  my ($x, $i) = symbols(qw(x i));

  ok( ($i*$x)->re   <=>  0    );
  ok( ($i*$x)->im   <=>  '$x' );

  The B<re> and B<im> functions return an expression which represents the real
  and imaginary parts of the expression, assuming that symbolic variables
  represent real numbers.

=head4 Complex functions: B<dot> and B<cross>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>2;

  my $i = symbols(qw(i));

  ok( ($i+1)->cross($i-1)   <=>  2 );
  ok( ($i+1)->dot  ($i-1)   <=>  0 );

  The B<dot> and B<cross> operators are available as functions, either as
  exports to the caller's name space, or as methods.

=head4 Complex functions: B<conjugate>, B<modulus> and B<unit>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>3;

  my $i = symbols(qw(i));

  ok( ($i+1)->unit      <=>  '1/(sqrt(2))+i/(sqrt(2))' );
  ok( ($i+1)->modulus   <=>  'sqrt(2)'                 );
  ok( ($i+1)->conjugate <=>  '1-i'                     );

  The B<conjugate>, B<abs> and B<unit> operators are available as functions:
  B<conjugate>, B<modulus> and B<unit>, either as exports to the caller's name
  space, or as methods. The confusion over the naming of: the B<abs> operator
  being the same as the B<modulus> complex function; arises over the limited
  set of Perl operator names available for overloading.

=head2 Methods

=head3 Methods for manipulating Equations

=head4 Simplifying equations: B<simplify()>

Example t/simplify2.t

  use Math::Algebra::Symbols;
  use Test::Simple tests=>2;

  my ($x) = symbols(qw(x));

  my $y  = (($x**8 - 1)/($x-1))->simplify();  # Simplify method
  my $z +=  ($x**8 - 1)/($x-1);               # Simplify via +=

  ok( "$y" eq '$x+$x**2+$x**3+$x**4+$x**5+$x**6+$x**7+1' );
  ok( "$z" eq '$x+$x**2+$x**3+$x**4+$x**5+$x**6+$x**7+1' );

  B<Simplify()> attempts to simplify an expression. There is no general
  simplification algorithm: consequently simplifications are carried out on
  ad-hoc basis. You may not even agree that the proposed simplification for a
  given expressions is indeed any simpler than the original. It is for these
  reasons that simplification has to be explicitly requested rather than being
  performed auto-magically.

  At the moment, simplifications consist of polynomial division: when the
  expression consists, in essence, of one polynomial divided by another, an
  attempt is made to perform polynomial division, the result is returned if
  there is no remainder.

  The B<+=> operator may be used to simplify and assign an expression to a Perl
  variable. Perl operator overloading precludes the use of B<=> in this manner.

=head4 Substituting into equations: B<sub()>

  use Math::Algebra::Symbols;
  use Test::Simple tests=>2;

  my ($x, $y) = symbols(qw(x y));

  my $e  = 1+$x+$x**2/2+$x**3/6+$x**4/24+$x**5/120;

  ok(  $e->sub(x=>$y**2, z=>2)  <=> '$y**2+1/2*$y**4+1/6*$y**6+1/24*$y**8+1/120*$y**10+1'  );
  ok(  $e->sub(x=>1)            <=>  '163/60');

  The B<sub()> function example on line B<#1> demonstrates replacing variables
  with expressions. The replacement specified for B<z> has no effect as B<z> is
  not present in this equation.

  Line B<#2> demonstrates the resulting rational fraction that arises when all
  the variables have been replaced by constants. This package does not convert
  fractions to decimal expressions in case there is a loss of accuracy,
  however:

  my $e2 = $e->sub(x=>1);
  $result = eval "$e2";

  or similar will produce approximate results.

  At the moment only variables can be replaced by expressions. Mike Schilli,
  m@perlmeister.com, has proposed that substitutions for expressions should
  also be allowed, as in:

  $x/$y => $z


=head4 Solving equations: B<solve()>

   use Math::Algebra::Symbols;
   use Test::Simple tests=>3;

   my ($x, $v, $t) = symbols(qw(x v t));

   ok(   ($v eq $x / $t)->solve(qw(x in terms of v t))  ==  $v*$t  );
   ok(   ($v eq $x / $t)->solve(qw(x in terms of v t))  !=  $v/$t  );
   ok(   ($v eq $x / $t)->solve(qw(x in terms of v t)) <=> '$t*$v' );

  B<solve()> assumes that the equation on the left hand side is equal to zero,
  applies various simplifications, then attempts to rearrange the equation to
  obtain an equation for the first variable in the parameter list assuming that
  the other terms mentioned in the parameter list are known constants. There
  may of course be other unknown free variables in the equation to be solved:
  the proposed solution is automatically tested against the original equation
  to check that the proposed solution removes these variables, an error is
  reported via B<die()> if it does not.

  use Math::Algebra::Symbols;
  use Test::Simple tests => 2;

  my ($x) = symbols(qw(x));

  my  $p = $x**2-5*$x+6;        # Quadratic polynomial
  my ($a, $b) = @{($p > $x )};  # Solve for x

  print "x=$a,$b\n";            # Roots

  ok($a == 2);
  ok($b == 3);

  If there are multiple solutions, (as in the case of polynomials), B<solve()>
  returns an array of symbolic expressions containing the solutions.

=head3 Methods for performing Calculus

=head4 Differentiation: B<d()>

  use Math::Algebra::Symbols;
  use Test::More tests => 5;

  $x = symbols(qw(x));

  ok(  sin($x)    ==  sin($x)->d->d->d->d);
  ok(  cos($x)    ==  cos($x)->d->d->d->d);
  ok(  exp($x)    ==  exp($x)->d($x)->d('x')->d->d);
  ok( (1/$x)->d   == -1/$x**2);
  ok(  exp($x)->d->d->d->d <=> 'exp($x)' );

  B<d()> differentiates the equation on the left hand side by the named
  variable.

  The variable to be differentiated by may be explicitly specified, either as a
  string or as single symbol; or it may be heuristically guessed as follows:

  If the equation to be differentiated refers to only one symbol, then that
  symbol is used. If several symbols are present in the equation, but only one
  of B<t>, B<x>, B<y>, B<z> is present, then that variable is used in honour of
  Newton, Leibnitz, Cauchy.

=head2 Example of Equation Solving: the focii of a hyperbola:

  use Math::Algebra::Symbols;

  my ($a, $b, $x, $y, $i, $o) = symbols(qw(a b x y i 1));

  print
  "Hyperbola: Constant difference between distances from focii to locus of y=1/x",
  "\n  Assume by symmetry the focii are on ",
  "\n    the line y=x:                     ",  $f1 = $x + $i * $x,
  "\n  and equidistant from the origin:    ",  $f2 = -$f1,
  "\n  Choose a convenient point on y=1/x: ",  $a = $o+$i,
  "\n        and a general point on y=1/x: ",  $b = $y+$i/$y,
  "\n  Difference in distances from focii",
  "\n    From convenient point:            ",  $A = abs($a - $f2) - abs($a - $f1),
  "\n    From general point:               ",  $B = abs($b - $f2) + abs($b - $f1),
  "\n\n  Solving for x we get:            x=", ($A - $B) > $x,
  "\n                         (should be: sqrt(2))",
  "\n  Which is indeed constant, as was to be demonstrated\n";

  This example demonstrates the power of symbolic processing by finding the
  focii of the curve B<y=1/x>, and incidentally, demonstrating that this curve
  is a hyperbola.

=head1 Exports

 use Math::Algebra::Symbols
   symbols=>'s',
   trig   => 1,
   hyper  => 1,
   complex=> 1;

=over

=item symbols=>'s'

  Create a function with name B<s()> in the callers name space to create new
  symbols. The default is B<symbols()>.

=item trig=>0

  The default, do not export trigonometric functions.

=item trig=>1

  Export trigonometric functions: B<tan>, B<sec>, B<csc>, B<cot> to the
  caller's name space. B<sin>, B<cos> are created by default by overloading the
  existing Perl B<sin> and B<cos> operators.

=item B<trigonometric>

  Alias of B<trig>

=item hyperbolic=>0

  The default, do not export hyperbolic functions.

=item hyper=>1

  Export hyperbolic functions: B<sinh>, B<cosh>, B<tanh>, B<sech>,
  B<csch>, B<coth> to the caller's name space.

=item B<hyperbolic>

  Alias of B<hyper>

=item complex=>0

  The default, do not export complex functions

=item complex=>1

  Export complex functions: B<conjugate>, B<cross>, B<dot>, B<im>, B<modulus>,
  B<re>, B<unit> to the caller's name space.

=back

=cut

package Math::Algebra::Symbols;
use strict;
our $VERSION=1.27;
use Math::Algebra::Symbols::Sum;
use Carp;

sub import
 {my %P = (program=>@_);
  my %p; $p{lc()} = $P{$_} for(keys(%P));

#_ Symbols _____________________________________________________________
# New symbols term constructor - export to calling package.
#_______________________________________________________________________

  my $s = "package XXXX;\n". <<'END';
no warnings 'redefine';
sub NNNN
 {return SSSSsum(@_);
 }
END

#_ Symbols _____________________________________________________________
# Complex functions: re, im, dot, cross, conjugate, modulus
#_______________________________________________________________________

  if (exists($p{complex}))
   {$s .= <<'END';
sub conjugate($)  {$_[0]->conjugate()}
sub cross    ($$) {$_[0]->cross    ($_[1])}
sub dot      ($$) {$_[0]->dot      ($_[1])}
sub im       ($)  {$_[0]->im       ()}
sub modulus  ($)  {$_[0]->modulus  ()}
sub re       ($)  {$_[0]->re       ()}
sub unit     ($)  {$_[0]->unit     ()}
END
   }

#_ Symbols _____________________________________________________________
# Trigonometric functions: tan, sec, csc, cot
#_______________________________________________________________________

  if (exists($p{trig}) or exists($p{trigonometric}))
   {$s .= <<'END';
sub tan($) {$_[0]->tan()}
sub sec($) {$_[0]->sec()}
sub csc($) {$_[0]->csc()}
sub cot($) {$_[0]->cot()}
END
   }
  if (exists($p{trig}) and exists($p{trigonometric}))
   {croak 'Please use specify just one of trig or trigonometric';
   }

#_ Symbols _____________________________________________________________
# Hyperbolic functions: sinh, cosh, tanh, sech, csch, coth
#_______________________________________________________________________

 if (exists($p{hyper}) or exists($p{hyperbolic}))
  {$s .= <<'END';
sub sinh($) {$_[0]->sinh()}
sub cosh($) {$_[0]->cosh()}
sub tanh($) {$_[0]->tanh()}
sub sech($) {$_[0]->sech()}
sub csch($) {$_[0]->csch()}
sub coth($) {$_[0]->coth()}
END
  }
 if (exists($p{hyper}) and exists($p{hyperbolic}))
  {croak 'Please specify just one of hyper or hyperbolic';
  }

#_ Symbols _____________________________________________________________
# Export to calling package.
#_______________________________________________________________________

    $s .= <<'END';
use warnings 'redefine';
END

  my $name   = 'symbols';
     $name   = $p{symbols} if exists($p{symbols});
  my ($main) = caller();
  my $pack   = __PACKAGE__. '::';

  $s=~ s/XXXX/$main/g;
  $s=~ s/NNNN/$name/g;
  $s=~ s/SSSS/$pack/g;
  eval($s);

#_ Symbols _____________________________________________________________
# Check options supplied by user
#_______________________________________________________________________

  delete @p{qw(
symbols program trig trigonometric hyper hyperbolic complex
)};

  croak "Unknown option(s): ". join(' ', keys(%p))."\n\n". <<'END' if keys(%p);

Valid options are:

  symbols=>'symbols' Create a routine with this name in the callers
                  name space to create new symbols. The default is
                  'symbols'.


  trig   =>0      The default, no trigonometric functions
  trig   =>1      Export trigonometric functions: tan, sec, csc, cot.
                  sin, cos are created by default by overloading
                  the existing Perl sin and cos operators.

  trigonometric can be used instead of trig.


  hyper  =>0      The default, no hyperbolic functions
  hyper  =>1      Export hyperbolic functions:
                    sinh, cosh, tanh, sech, csch, coth.

  hyperbolic can be used instead of hyper.


  complex=>0      The default, no complex functions
  complex=>1      Export complex functions:
                    conjugate, cross, dot, im, modulus, re,  unit

END
 }

#_ Symbols _____________________________________________________________
# Package installed successfully
#_______________________________________________________________________

1;

=pod

=head1 Packages

  The B<Symbols> packages manipulate a sum of products representation of an
  algebraic equation. The B<Symbols> package is the user interface to the
  functionality supplied by the B<Symbols::Sum> and B<Symbols::Term> packages.

=head2 Math::Algebra::Symbols::Term

  B<Symbols::Term> represents a product term. A product term consists of the
  number B<1>, optionally multiplied by:

=over

=item Variables

  Any number of variables raised to integer powers.

=item Coefficient

  An integer coefficient optionally divided by a positive integer divisor, both
  represented as BigInts if necessary.

=item Sqrt

  The sqrt of of any symbolic expression representable by the B<Symbols>
  package, including minus one: represented as B<i>.

=item Reciprocal

  The multiplicative inverse of any symbolic expression representable by the
  B<Symbols> package: i.e. a B<SymbolsTerm> may be divided by any symbolic
  expression representable by the B<Symbols> package.

=item Exp

  The number B<e> raised to the power of any symbolic expression representable
  by the B<Symbols> package.

=item Log

  The logarithm to base B<e> of any symbolic expression representable by the
  B<Symbols> package.

=back

  Thus B<SymbolsTerm> can represent expressions like:

    2/3*$x**2*$y**-3*exp($i*$pi)*sqrt($z**3) / $x

  but not:

    $x + $y

  for which package B<Symbols::Sum> is required.


=head2 Math::Algebra::Symbols::Sum

  B<Symbols::Sum> represents a sum of product terms supplied by
  B<Symbols::Term> and thus behaves as a polynomial. Operations such as
  equation solving and differentiation are applied at this level.

=head1 Installation

 Standard Module::Build process for building and installing modules:

   perl Build.PL
   ./Build
   ./Build test
   ./Build install

=head1 Copyright

  Philip R Brenan at B<PhilipRBrenan@gmail.com> 2004-2016

=head1 License

  Perl License.

=cut
