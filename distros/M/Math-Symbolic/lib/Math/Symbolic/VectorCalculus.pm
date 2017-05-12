
=encoding utf8

=head1 NAME

Math::Symbolic::VectorCalculus - Symbolically comp. grad, Jacobi matrices etc.

=head1 SYNOPSIS

  use Math::Symbolic qw/:all/;
  use Math::Symbolic::VectorCalculus; # not loaded by Math::Symbolic
  
  @gradient = grad 'x+y*z';
  # or:
  $function = parse_from_string('a*b^c');
  @gradient = grad $function;
  # or:
  @signature = qw(x y z);
  @gradient = grad 'a*x+b*y+c*z', @signature; # Gradient only for x, y, z
  # or:
  @gradient = grad $function, @signature;
  
  # Similar syntax variations as with the gradient:
  $divergence = div @functions;
  $divergence = div @functions, @signature;
  
  # Again, similar DWIM syntax variations as with grad:
  @rotation = rot @functions;
  @rotation = rot @functions, @signature;
  
  # Signatures always inferred from the functions here:
  @matrix = Jacobi @functions;
  # $matrix is now array of array references. These hold
  # Math::Symbolic trees. Or:
  @matrix = Jacobi @functions, @signature;
  
  # Similar to Jacobi:
  @matrix = Hesse $function;
  # or:
  @matrix = Hesse $function, @signature;
  
  $wronsky_determinant = WronskyDet @functions, @vars;
  # or:
  $wronsky_determinant = WronskyDet @functions; # functions of 1 variable
  
  $differential = TotalDifferential $function;
  $differential = TotalDifferential $function, @signature;
  $differential = TotalDifferential $function, @signature, @point;
  
  $dir_deriv = DirectionalDerivative $function, @vector;
  $dir_deriv = DirectionalDerivative $function, @vector, @signature;
  
  $taylor = TaylorPolyTwoDim $function, $var1, $var2, $degree;
  $taylor = TaylorPolyTwoDim $function, $var1, $var2,
                             $degree, $var1_0, $var2_0; 
  # example:
  $taylor = TaylorPolyTwoDim 'sin(x)*cos(y)', 'x', 'y', 2;

=head1 DESCRIPTION

This module provides several subroutines related to
vector calculus such as computing gradients, divergence, rotation,
and Jacobi/Hesse Matrices of Math::Symbolic trees.
Furthermore it provides means of computing directional derivatives
and the total differential of a scalar function and the
Wronsky Determinant of a set of n scalar functions.

Please note that the code herein may or may not be refactored into
the OO-interface of the Math::Symbolic module in the future.

=head2 EXPORT

None by default.

You may choose to have any of the following routines exported to the
calling namespace. ':all' tag exports all of the following:

  grad
  div
  rot
  Jacobi
  Hesse
  WronskyDet
  TotalDifferential
  DirectionalDerivative
  TaylorPolyTwoDim

=head1 SUBROUTINES

=cut

package Math::Symbolic::VectorCalculus;

use 5.006;
use strict;
use warnings;

use Carp;

use Math::Symbolic qw/:all/;
use Math::Symbolic::MiscAlgebra qw/det/;

require Exporter;
our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
    'all' => [
        qw(
          grad
          div
          rot
          Jacobi
          Hesse
          TotalDifferential
          DirectionalDerivative
          TaylorPolyTwoDim
          WronskyDet
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.612';

=begin comment

_combined_signature returns the combined signature of unique variable names
of all Math::Symbolic trees passed to it.

=end comment

=cut

sub _combined_signature {
    my %seen = map { ( $_, undef ) } map { ( $_->signature() ) } @_;
    return [ sort keys %seen ];
}

=head2 grad

This subroutine computes the gradient of a Math::Symbolic tree representing
a function.

The gradient of a function f(x1, x2, ..., xn) is defined as the vector:

  ( df(x1, x2, ..., xn) / d(x1),
    df(x1, x2, ..., xn) / d(x2),
    ...,
    df(x1, x2, ..., xn) / d(xn) )

(These are all partial derivatives.) Any good book on calculus will have
more details on this.

grad uses prototypes to allow for a variety of usages. In its most basic form,
it accepts only one argument which may either be a Math::Symbolic tree or a
string both of which will be interpreted as the function to compute the
gradient for. Optionally, you may specify a second argument which must
be a (literal) array of Math::Symbolic::Variable objects or valid
Math::Symbolic variable names (strings). These variables will the be used for
the gradient instead of the x1, ..., xn inferred from the function signature.

=cut

sub grad ($;\@) {
    my $original = shift;
    $original = parse_from_string($original)
      unless ref($original) =~ /^Math::Symbolic/;
    my $signature = shift;

    my @funcs;
    my @signature =
      ( defined $signature ? @$signature : $original->signature() );

    foreach (@signature) {
        my $var  = Math::Symbolic::Variable->new($_);
        my $func = Math::Symbolic::Operator->new(
            {
                type     => U_P_DERIVATIVE,
                operands => [ $original->new(), $var ],
            }
        );
        push @funcs, $func;
    }
    return @funcs;
}

=head2 div

This subroutine computes the divergence of a set of Math::Symbolic trees
representing a vectorial function.

The divergence of a vectorial function
F = (f1(x1, ..., xn), ..., fn(x1, ..., xn)) is defined like follows:

  sum_from_i=1_to_n( dfi(x1, ..., xn) / dxi )

That is, the sum of all partial derivatives of the i-th component function
to the i-th coordinate. See your favourite book on calculus for details.
Obviously, it is important to keep in mind that the number of function
components must be equal to the number of variables/coordinates.

Similar to grad, div uses prototypes to offer a comfortable interface.
First argument must be a (literal) array of strings and Math::Symbolic trees
which represent the vectorial function's components. If no second argument
is passed, the variables used for computing the divergence will be
inferred from the functions. That means the function signatures will be
joined to form a signature for the vectorial function.

If the optional second argument is specified, it has to be a (literal)
array of Math::Symbolic::Variable objects and valid variable names (strings).
These will then be interpreted as the list of variables for computing the
divergence.

=cut

sub div (\@;\@) {
    my @originals =
      map { ( ref($_) =~ /^Math::Symbolic/ ) ? $_ : parse_from_string($_) }
      @{ +shift };

    my $signature = shift;
    $signature = _combined_signature(@originals)
      if not defined $signature;

    if ( @$signature != @originals ) {
        die "Variable count does not function count for divergence.";
    }

    my @signature = map { Math::Symbolic::Variable->new($_) } @$signature;

    my $div = Math::Symbolic::Operator->new(
        {
            type     => U_P_DERIVATIVE,
            operands => [ shift(@originals)->new(), shift @signature ],
        }
    );

    foreach (@originals) {
        $div = Math::Symbolic::Operator->new(
            '+', $div,
            Math::Symbolic::Operator->new(
                {
                    type     => U_P_DERIVATIVE,
                    operands => [ $_->new(), shift @signature ],
                }
            )
        );
    }
    return $div;
}

=head2 rot

This subroutine computes the rotation of a set of three Math::Symbolic trees
representing a vectorial function.

The rotation of a vectorial function
F = (f1(x1, x2, x3), f2(x1, x2, x3), f3(x1, x2, x3)) is defined as the
following vector:

  ( ( df3/dx2 - df2/dx3 ),
    ( df1/dx3 - df3/dx1 ),
    ( df2/dx1 - df1/dx2 ) )

Or "nabla x F" for short. Again, I have to refer to the literature for
the details on what rotation is. Please note that there have to be
exactly three function components and three coordinates because the cross
product and hence rotation is only defined in three dimensions.

As with the previously introduced subroutines div and grad, rot
offers a prototyped interface.
First argument must be a (literal) array of strings and Math::Symbolic trees
which represent the vectorial function's components. If no second argument
is passed, the variables used for computing the rotation will be
inferred from the functions. That means the function signatures will be
joined to form a signature for the vectorial function.

If the optional second argument is specified, it has to be a (literal)
array of Math::Symbolic::Variable objects and valid variable names (strings).
These will then be interpreted as the list of variables for computing the
rotation. (And please excuse my copying the last two paragraphs from above.)

=cut

sub rot (\@;\@) {
    my $originals = shift;
    my @originals =
      map { ( ref($_) =~ /^Math::Symbolic/ ) ? $_ : parse_from_string($_) }
      @$originals;

    my $signature = shift;
    $signature = _combined_signature(@originals)
      unless defined $signature;

    if ( @originals != 3 ) {
        die "Rotation only defined for functions of three components.";
    }
    if ( @$signature != 3 ) {
        die "Rotation only defined for three variables.";
    }

    return (
        Math::Symbolic::Operator->new(
            '-',
            Math::Symbolic::Operator->new(
                {
                    type     => U_P_DERIVATIVE,
                    operands => [ $originals[2]->new(), $signature->[1] ],
                }
            ),
            Math::Symbolic::Operator->new(
                {
                    type     => U_P_DERIVATIVE,
                    operands => [ $originals[1]->new(), $signature->[2] ],
                }
            )
        ),
        Math::Symbolic::Operator->new(
            '-',
            Math::Symbolic::Operator->new(
                {
                    type     => U_P_DERIVATIVE,
                    operands => [ $originals[0]->new(), $signature->[2] ],
                }
            ),
            Math::Symbolic::Operator->new(
                {
                    type     => U_P_DERIVATIVE,
                    operands => [ $originals[2]->new(), $signature->[0] ],
                }
            )
        ),
        Math::Symbolic::Operator->new(
            '-',
            Math::Symbolic::Operator->new(
                {
                    type     => U_P_DERIVATIVE,
                    operands => [ $originals[1]->new(), $signature->[0] ],
                }
            ),
            Math::Symbolic::Operator->new(
                {
                    type     => U_P_DERIVATIVE,
                    operands => [ $originals[0]->new(), $signature->[1] ],
                }
            )
        )
    );
}

=head2 Jacobi

Jacobi() returns the Jacobi matrix of a given vectorial function.
It expects any number of arguments (strings and/or Math::Symbolic trees)
which will be interpreted as the vectorial function's components.
Variables used for computing the matrix are, by default, inferred from the
combined signature of the components. By specifying a second literal
array of variable names as (second) argument, you may override this
behaviour.

The Jacobi matrix is the vector of gradient vectors of the vectorial
function's components.

=cut

sub Jacobi (\@;\@) {
    my @funcs =
      map { ( ref($_) =~ /^Math::Symbolic/ ) ? $_ : parse_from_string($_) }
      @{ +shift() };

    my $signature = shift;
    my @signature = (
        defined $signature
        ? (
            map {
                ( ref($_) =~ /^Math::Symbolic/ )
                  ? $_
                  : parse_from_string($_)
              } @$signature
          )
        : ( @{ +_combined_signature(@funcs) } )
    );

    return map { [ grad $_, @signature ] } @funcs;
}

=head2 Hesse

Hesse() returns the Hesse matrix of a given scalar function. First
argument must be a string (to be parsed as a Math::Symbolic tree)
or a Math::Symbolic tree. As with Jacobi(), Hesse() optionally
accepts an array of signature variables as second argument.

The Hesse matrix is the Jacobi matrix of the gradient of a scalar function.

=cut

sub Hesse ($;\@) {
    my $function = shift;
    $function = parse_from_string($function)
      unless ref($function) =~ /^Math::Symbolic/;
    my $signature = shift;
    my @signature = (
        defined $signature
        ? (
            map {
                ( ref($_) =~ /^Math::Symbolic/ )
                  ? $_
                  : parse_from_string($_)
              } @$signature
          )
        : $function->signature()
    );

    my @gradient = grad $function, @signature;
    return Jacobi @gradient, @signature;
}

=head2 TotalDifferential

This function computes the total differential of a scalar function of
multiple variables in a certain point.

First argument must be the function to derive. The second argument is
an optional (literal) array of variable names (strings) and
Math::Symbolic::Variable objects to be used for deriving. If the argument
is not specified, the functions signature will be used. The third argument
is also an optional array and denotes the set of variable (names) to use for
indicating the point for which to evaluate the differential. It must have
the same number of elements as the second argument.
If not specified the variable names used as coordinated (the second argument)
with an appended '_0' will be used as the point's components.

=cut

sub TotalDifferential ($;\@\@) {
    my $function = shift;
    $function = parse_from_string($function)
      unless ref($function) =~ /^Math::Symbolic/;

    my $sig = shift;
    $sig = [ $function->signature() ] if not defined $sig;
    my @sig = map { Math::Symbolic::Variable->new($_) } @$sig;

    my $point = shift;
    $point = [ map { $_->name() . '_0' } @sig ] if not defined $point;
    my @point = map { Math::Symbolic::Variable->new($_) } @$point;

    if ( @point != @sig ) {
        croak "Signature dimension does not match point dimension.";
    }

    my @grad = grad $function, @sig;
    if ( @grad != @sig ) {
        croak "Signature dimension does not match function grad dim.";
    }

    foreach (@grad) {
        my @point_copy = @point;
        $_->implement( map { ( $_->name() => shift(@point_copy) ) } @sig );
    }

    my $d =
      Math::Symbolic::Operator->new( '*', shift(@grad),
        Math::Symbolic::Operator->new( '-', shift(@sig), shift(@point) ) );

    $d +=
      Math::Symbolic::Operator->new( '*', shift(@grad),
        Math::Symbolic::Operator->new( '-', shift(@sig), shift(@point) ) )
      while @grad;

    return $d;
}

=head2 DirectionalDerivative

DirectionalDerivative computes the directional derivative of a scalar function
in the direction of a specified vector. With f being the function and X, A being
vectors, it looks like this: (this is a partial derivative)

  df(X)/dA = grad(f(X)) * (A / |A|)

First argument must be the function to derive (either a string or a valid
Math::Symbolic tree). Second argument must be vector into whose direction to
derive. It is to be specified as an array of variable names and objects.
Third argument is the optional signature to be used for computing the gradient.
Please see the documentation of the grad function for details. It's
dimension must match that of the directional vector.

=cut

sub DirectionalDerivative ($\@;\@) {
    my $function = shift;
    $function = parse_from_string($function)
      unless ref($function) =~ /^Math::Symbolic/;

    my $vec = shift;
    my @vec = map { Math::Symbolic::Variable->new($_) } @$vec;

    my $sig = shift;
    $sig = [ $function->signature() ] if not defined $sig;
    my @sig = map { Math::Symbolic::Variable->new($_) } @$sig;

    if ( @vec != @sig ) {
        croak "Signature dimension does not match vector dimension.";
    }

    my @grad = grad $function, @sig;
    if ( @grad != @sig ) {
        croak "Signature dimension does not match function grad dim.";
    }

    my $two     = Math::Symbolic::Constant->new(2);
    my @squares =
      map { Math::Symbolic::Operator->new( '^', $_, $two ) } @vec;

    my $abs_vec = shift @squares;
    $abs_vec += shift(@squares) while @squares;

    $abs_vec =
      Math::Symbolic::Operator->new( '^', $abs_vec,
        Math::Symbolic::Constant->new( 1 / 2 ) );

    @vec = map { $_ / $abs_vec } @vec;

    my $dd = Math::Symbolic::Operator->new( '*', shift(@grad), shift(@vec) );

    $dd += Math::Symbolic::Operator->new( '*', shift(@grad), shift(@vec) )
      while @grad;

    return $dd;
}

=begin comment

This computes the taylor binomial

  (d/dx*(x-x0)+d/dy*(y-y0))^n * f(x0, y0)

=end comment

=cut

sub _taylor_binomial {
    my $f  = shift;
    my $a  = shift;
    my $b  = shift;
    my $a0 = shift;
    my $b0 = shift;
    my $n  = shift;

    $f = $f->new();
    my $da = $a - $a0;
    my $db = $b - $b0;

    $f->implement( $a->name() => $a0, $b->name() => $b0 );

    return Math::Symbolic::Constant->one() if $n == 0;
    return $da *
      Math::Symbolic::Operator->new( 'partial_derivative', $f->new(), $a0 ) +
      $db *
      Math::Symbolic::Operator->new( 'partial_derivative', $f->new(), $b0 )
      if $n == 1;

    my $n_obj = Math::Symbolic::Constant->new($n);

    my $p_a_deriv = $f->new();
    $p_a_deriv =
      Math::Symbolic::Operator->new( 'partial_derivative', $p_a_deriv, $a0 )
      for 1 .. $n;

    my $res =
      Math::Symbolic::Operator->new( '*', $p_a_deriv,
        Math::Symbolic::Operator->new( '^', $da, $n_obj ) );

    foreach my $k ( 1 .. $n - 1 ) {
        $p_a_deriv = $p_a_deriv->op1()->new();

        my $deriv = $p_a_deriv;
        $deriv =
          Math::Symbolic::Operator->new( 'partial_derivative', $deriv, $b0 )
          for 1 .. $k;

        my $k_obj = Math::Symbolic::Constant->new($k);
        $res += Math::Symbolic::Operator->new(
            '*',
            Math::Symbolic::Constant->new( _over( $n, $k ) ),
            Math::Symbolic::Operator->new(
                '*', $deriv,
                Math::Symbolic::Operator->new(
                    '*',
                    Math::Symbolic::Operator->new(
                        '^', $da, Math::Symbolic::Constant->new( $n - $k )
                    ),
                    Math::Symbolic::Operator->new( '^', $db, $k_obj )
                )
            )
        );
    }

    my $p_b_deriv = $f->new();
    $p_b_deriv =
      Math::Symbolic::Operator->new( 'partial_derivative', $p_b_deriv, $b0 )
      for 1 .. $n;

    $res +=
      Math::Symbolic::Operator->new( '*', $p_b_deriv,
        Math::Symbolic::Operator->new( '^', $db, $n_obj ) );

    return $res;
}

=begin comment

This computes

  / n \
  |   |
  \ k /

=end comment

=cut

sub _over {
    my $n = shift;
    my $k = shift;

    return 1 if $k == 0;
    return _over( $n, $n - $k ) if $k > $n / 2;

    my $prod = 1;
    my $i    = $n;
    my $j    = $k;
    while ( $i > $k ) {
        $prod *= $i;
        $prod /= $j if $j > 1;
        $i--;
        $j--;
    }

    return ($prod);
}

=begin comment

_faculty() computes the product that is the faculty of the
first argument.

=end comment

=cut

sub _faculty {
    my $num = shift;
    croak "Cannot calculate faculty of negative numbers."
      if $num < 0;
    my $fac = Math::Symbolic::Constant->one();
    return $fac if $num <= 1;
    for ( my $i = 2 ; $i <= $num ; $i++ ) {
        $fac *= Math::Symbolic::Constant->new($i);
    }
    return $fac;
}

=head2 TaylorPolyTwoDim

This subroutine computes the Taylor Polynomial for functions of two
variables. Please refer to the documentation of the TaylorPolynomial
function in the Math::Symbolic::MiscCalculus package for an explanation
of single dimensional Taylor Polynomials. This is the counterpart in
two dimensions.

First argument must be the function to approximate with the Taylor Polynomial
either as a string or a Math::Symbolic tree. Second and third argument
must be the names of the two coordinates. (These may alternatively be
Math::Symbolic::Variable objects.) Fourth argument must be
the degree of the Taylor Polynomial. Fifth and Sixth arguments are optional
and specify the names of the variables to introduce as the point of
approximation. These default to the names of the coordinates with '_0'
appended.

=cut

sub TaylorPolyTwoDim ($$$$;$$) {
    my $function = shift;
    $function = parse_from_string($function)
      unless ref($function) =~ /^Math::Symbolic/;

    my $x1 = shift;
    $x1 = Math::Symbolic::Variable->new($x1)
      unless ref($x1) eq 'Math::Symbolic::Variable';
    my $x2 = shift;
    $x2 = Math::Symbolic::Variable->new($x2)
      unless ref($x2) eq 'Math::Symbolic::Variable';

    my $n = shift;

    my $x1_0 = shift;
    $x1_0 = $x1->name() . '_0' if not defined $x1_0;
    $x1_0 = Math::Symbolic::Variable->new($x1_0)
      unless ref($x1_0) eq 'Math::Symbolic::Variable';

    my $x2_0 = shift;
    $x2_0 = $x2->name() . '_0' if not defined $x2_0;
    $x2_0 = Math::Symbolic::Variable->new($x2_0)
      unless ref($x2_0) eq 'Math::Symbolic::Variable';

    my $x1_n = $x1->name();
    my $x2_n = $x2->name();

    my $dx1 = $x1 - $x1_0;
    my $dx2 = $x2 - $x2_0;

    my $copy = $function->new();
    $copy->implement( $x1_n => $x1_0, $x2_n => $x2_0 );

    my $taylor = $copy;

    return $taylor if $n == 0;

    foreach my $k ( 1 .. $n ) {
        $taylor +=
          Math::Symbolic::Operator->new( '/',
            _taylor_binomial( $function->new(), $x1, $x2, $x1_0, $x2_0, $k ),
            _faculty($k) );
    }

    return $taylor;
}

=head2 WronskyDet

WronskyDet() computes the Wronsky Determinant of a set of n functions.

First argument is required and a (literal) array of n functions. Second
argument is optional and a (literal) array of n variables or variable names.
If the second argument is omitted, the variables used for deriving are inferred
from function signatures. This requires, however, that the function signatures
have exactly one element. (And the function this exactly one variable.)

=cut

sub WronskyDet (\@;\@) {
    my $functions = shift;
    my @functions =
      map { ( ref($_) =~ /^Math::Symbolic/ ) ? $_ : parse_from_string($_) }
      @$functions;
    my $vars = shift;
    my @vars = ( defined $vars ? @$vars : () );
    @vars = map {
        my @sig = $_->signature();
        croak "Cannot infer function signature for WronskyDet."
          if @sig != 1;
        shift @sig;
    } @functions if not defined $vars;
    @vars = map { Math::Symbolic::Variable->new($_) } @vars;
    croak "Number of vars doesn't match num of functions in WronskyDet."
      if not @vars == @functions;

    my @matrix;
    push @matrix, [@functions];
    foreach ( 2 .. @functions ) {
        my $i = 0;
        @functions = map {
            Math::Symbolic::Operator->new( 'partial_derivative', $_,
                $vars[ $i++ ] )
        } @functions;
        push @matrix, [@functions];
    }
    return det @matrix;
}

1;
__END__

=head1 AUTHOR

Please send feedback, bug reports, and support requests to the Math::Symbolic
support mailing list:
math-symbolic-support at lists dot sourceforge dot net. Please
consider letting us know how you use Math::Symbolic. Thank you.

If you're interested in helping with the development or extending the
module's functionality, please contact the developers' mailing list:
math-symbolic-develop at lists dot sourceforge dot net.

List of contributors:

  Steffen Müller, symbolic-module at steffen-mueller dot net
  Stray Toaster, mwk at users dot sourceforge dot net
  Oliver Ebenhöh

=head1 SEE ALSO

New versions of this module can be found on
http://steffen-mueller.net or CPAN. The module development takes place on
Sourceforge at http://sourceforge.net/projects/math-symbolic/

L<Math::Symbolic>

=cut

