
=encoding utf8

=head1 NAME

Math::Symbolic::MiscCalculus - Miscellaneous calculus routines (eg Taylor poly)

=head1 SYNOPSIS

  use Math::Symbolic qw/:all/;
  use Math::Symbolic::MiscCalculus qw/:all/; # not loaded by Math::Symbolic
  
  $taylor_poly = TaylorPolynomial $function, $degree, $variable;
  # or:
  $taylor_poly = TaylorPolynomial $function, $degree, $variable, $pos;
  
  $lagrange_error = TaylorErrorLagrange $function, $degree, $variable;
  # or:
  $lagrange_error = TaylorErrorLagrange $function, $degree, $variable, $pos;
  # or:
  $lagrange_error = TaylorErrorLagrange $function, $degree, $variable, $pos,
                                        $name_for_range_variable;
  
  # This has the same syntax variations as the Lagrange error:
  $cauchy_error = TaylorErrorLagrange $function, $degree, $variable;

=head1 DESCRIPTION

This module provides several subroutines related to
calculus such as computing Taylor polynomials and errors the
associated errors from Math::Symbolic trees.

Please note that the code herein may or may not be refactored into
the OO-interface of the Math::Symbolic module in the future.

=head2 EXPORT

None by default.

You may choose to have any of the following routines exported to the
calling namespace. ':all' tag exports all of the following:

  TaylorPolynomial
  TaylorErrorLagrange
  TaylorErrorCauchy

=head1 SUBROUTINES

=cut

package Math::Symbolic::MiscCalculus;

use 5.006;
use strict;
use warnings;

use Carp;

use Math::Symbolic qw/:all/;

require Exporter;
our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
    'all' => [
        qw(
          TaylorPolynomial
          TaylorErrorLagrange
          TaylorErrorCauchy
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.612';

=begin comment

_faculty() computes the (symbolic) product that is the faculty of the
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

=head2 TaylorPolynomial

This function (symbolically) computes the nth-degree Taylor Polynomial
of a given function. Generally speaking, the Taylor Polynomial is an
n-th degree polynomial that approximates the original function. It does
so particularly well in the proximity of a certain point x0.
(Since my mathematical English jargon is lacking, I strongly suggest you
read up on what this is in a book.)

Mathematically speaking, the Taylor Polynomial of the function f(x) looks
like this:

  Tn(f, x, x0) =
    sum_from_k=0_to_n(
        n-th_total_derivative(f)(x0) / k! * (x-x0)^k
    )

First argument to the subroutine must be the function to approximate. It may
be given either as a string to be parsed or as a valid Math::Symbolic tree.
Second argument must be an integer indicating to which degree to approximate.
The third argument is the last required argument and denotes the variable
to use for approximation either as a string (name) or as a
Math::Symbolic::Variable object. That's the 'x' above.
The fourth argument is optional and specifies the name of the variable to
introduce as the point of approximation. May also be a variable object.
It's the 'x0' above. If not specified, the name of this variable will be
assumed to be the name of the function variable (the 'x') with '_0' appended.

This routine is for functions of one variable only. There is an equivalent
for functions of two variables in the Math::Symbolic::VectorCalculus package.

=cut

sub TaylorPolynomial ($$$;$) {
    my $func   = shift;
    my $degree = shift;
    my $var    = shift;
    my $pos    = shift;

    $func = parse_from_string($func)
      unless ref($func) =~ /^Math::Symbolic/;
    $var = Math::Symbolic::Variable->new($var)
      unless ref($var) =~ /^Math::Symbolic::Variable$/;
    $pos = Math::Symbolic::Variable->new( $var->name() . '_0' )
      unless ref($pos) =~ /^Math::Symbolic::Variable$/;

    my $copy = $func->new();
    $copy->implement( $var->name() => $pos );
    my $taylor = $copy;

    return $taylor if $degree == 0;

    my $diff = Math::Symbolic::Operator->new( '-', $var, $pos );

    my $partial = $func->new();
    foreach my $d ( 1 .. $degree ) {
        $partial =
          Math::Symbolic::Operator->new( 'total_derivative', $partial, $var );
        $partial = $partial->apply_derivatives()->simplify();
        my $copy = $partial->new()->implement( $var->name() => $pos );
        $taylor += Math::Symbolic::Operator->new(
            '*',
            Math::Symbolic::Operator->new( '/', $copy, _faculty($d) ),
            Math::Symbolic::Operator->new(
                '^', $diff, Math::Symbolic::Constant->new($d)
            )
        );
    }
    return $taylor;
}

=head2 TaylorErrorLagrange

TaylorErrorLagrange computes and returns the formula for the Taylor
Polynomial's approximation error after Lagrange. (Again, my English
terminology is lacking.) It looks similar to this:

  Rn(f, x, x0) =
    n+1-th_total_derivative(f)( x0 + theta * (x-x0) ) / (n+1)! * (x-x0)^(n+1)

Please refer to your favourite book on the topic. 'theta' may be
any number between 0 and 1.

The calling conventions for TaylorErrorLagrange are similar to those of
TaylorPolynomial, but TaylorErrorLagrange takes an extra optional argument
specifying the name of 'theta'. If it isn't specified explicitly, the
variable will be named 'theta' as in the formula above.

=cut

sub TaylorErrorLagrange ($$$;$$) {
    my $func   = shift;
    my $degree = shift;
    my $var    = shift;
    my $pos    = shift;
    my $theta  = shift;

    $func = parse_from_string($func)
      unless ref($func) =~ /^Math::Symbolic/;
    $var = Math::Symbolic::Variable->new($var)
      unless ref($var) =~ /^Math::Symbolic::Variable$/;
    $pos = Math::Symbolic::Variable->new( $var->name() . '_0' )
      unless ref($pos) =~ /^Math::Symbolic::Variable$/;
    $theta = Math::Symbolic::Variable->new('theta')
      unless ref($theta) =~ /^Math::Symbolic::Variable$/;

    my $error =
      Math::Symbolic::Operator->new( 'total_derivative', $func->new(), $var );

    foreach ( 1 .. $degree + 1 ) {
        $error =
          Math::Symbolic::Operator->new( 'total_derivative', $error, $var );
        $error = $error->apply_derivatives()->simplify();
    }

    # We want to avoid endless recursion at all cost!
    my @sig  = $func->signature();
    my $last = $sig[-1] . '_not_taken';

    $error->implement( $var->name() => Math::Symbolic::Variable->new($last) );
    my $xhi = Math::Symbolic::Operator->new(
        '+', $pos,
        Math::Symbolic::Operator->new(
            '*', $theta, Math::Symbolic::Operator->new( '-', $var, $pos )
        )
    );
    $error->implement( $last => $xhi );

    $error = Math::Symbolic::Operator->new(
        '*', $error,
        Math::Symbolic::Operator->new(
            '/',
            Math::Symbolic::Operator->new(
                '^',
                Math::Symbolic::Operator->new( '-', $var, $pos ),
                Math::Symbolic::Constant->new( $degree + 1 )
            ),
            _faculty( $degree + 1 )
        )
    );
    return $error;
}

=head2 TaylorErrorCauchy

TaylorErrorCauchy computes and returns the formula for the Taylor
Polynomial's approximation error after (guess who!) Cauchy.
(Again, my English terminology is lacking.) It looks similar to this:

  Rn(f, x, x0) = TaylorErrorLagrange(...) * (1 - theta)^n

Please refer to your favourite book on the topic and the documentation for
TaylorErrorLagrange. 'theta' may be any number between 0 and 1.

The calling conventions for TaylorErrorCauchy are identical to those of
TaylorErrorLagrange.

=cut

sub TaylorErrorCauchy ($$$;$$) {
    my $func   = shift;
    my $degree = shift;
    my $var    = shift;
    my $pos    = shift;
    my $theta  = shift;

    $func = parse_from_string($func)
      unless ref($func) =~ /^Math::Symbolic/;
    $var = Math::Symbolic::Variable->new($var)
      unless ref($var) =~ /^Math::Symbolic::Variable$/;
    $pos = Math::Symbolic::Variable->new( $var->name() . '_0' )
      unless ref($pos) =~ /^Math::Symbolic::Variable$/;
    $theta = Math::Symbolic::Variable->new('theta')
      unless ref($theta) =~ /^Math::Symbolic::Variable$/;

    my $error = TaylorErrorLagrange( $func, $degree, $var, $pos, $theta );

    $error = Math::Symbolic::Operator->new(
        '*', $error,
        Math::Symbolic::Operator->new(
            '^',
            Math::Symbolic::Operator->new(
                '-', Math::Symbolic::Constant->one(), $theta
            ),
            $degree
        )
    );
    return $error;
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

