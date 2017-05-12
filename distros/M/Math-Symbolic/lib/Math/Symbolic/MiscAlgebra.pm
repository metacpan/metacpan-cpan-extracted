
=encoding utf8

=head1 NAME

Math::Symbolic::MiscAlgebra - Miscellaneous algebra routines like det()

=head1 SYNOPSIS

  use Math::Symbolic qw/:all/;
  use Math::Symbolic::MiscAlgebra qw/:all/; # not loaded by Math::Symbolic
  
  @matrix = (['x*y', 'z*x', 'y*z'],['x', 'z', 'z'],['x', 'x', 'y']);
  $det = det @matrix;
  
  @vector = ('x', 'y', 'z');
  $solution = solve_linear(\@matrix, \@vector);
  
=head1 DESCRIPTION

This module provides several subroutines related to
algebra such as computing the determinant of quadratic matrices, solving
linear equation systems and computation of Bell Polynomials.

Please note that the code herein may or may not be refactored into
the OO-interface of the Math::Symbolic module in the future.

=head2 EXPORT

None by default.

You may choose to have any of the following routines exported to the
calling namespace. ':all' tag exports all of the following:

  det
  linear_solve
  bell_polynomial

=head1 SUBROUTINES

=cut

package Math::Symbolic::MiscAlgebra;

use 5.006;
use strict;
use warnings;

use Carp;
use Memoize;

use Math::Symbolic qw/:all/;

require Exporter;
our @ISA         = qw(Exporter);
our %EXPORT_TAGS = (
    'all' => [
        qw(
          det
          bell_polynomial
          linear_solve
          )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = '0.612';

=head2 det

det() computes the determinant of a matrix of Math::Symbolic trees (or strings
that can be parsed as such). First argument must be a literal array:
"det @matrix", where @matrix is an n x n matrix.

Please note that calculating determinants of matrices using the
straightforward Laplace algorithm is a slow (O(n!))
operation. This implementation cannot make use of the various optimizations
resulting from the determinant properties since we are dealing with
symbolic matrix elements. If you have a matrix of reals, it is strongly
suggested that you use Math::MatrixReal or Math::Pari to get the determinant
which can be calculated using LR decomposition much faster.

On a related note: Calculating the determinant of a 20x20 matrix would take
over 77146 years if your Perl could do 1 million calculations per second.
Given that we're talking about several method calls per calculation, that's
much more than todays computers could do. On the other hand, if you'd be
using this straightforward algorithm with numbers only and in C, you might
be done in 26 years alright, so please go for the smarter route (better
algorithm) instead if you have numbers only.

=cut

sub det (\@) {
    my $matrix = shift;
    my $size   = @$matrix;

    foreach (@$matrix) {
        croak "det(Matrix) requires n x n matrix!" if @$_ != $size;
        foreach (@$_) {
            $_ = Math::Symbolic::parse_from_string($_)
              if ref($_) !~ /^Math::Symbolic/;
        }
    }

    return $matrix->[0][0] if $size == 1;
    return $matrix->[0][0] * $matrix->[1][1] - $matrix->[1][0] * $matrix->[0][1]
      if $size == 2;
    return _det_helper( $matrix, $size );
}

sub _det_helper {
    my $matrix = shift;
    my $size   = shift;

    return $matrix->[0][0] * $matrix->[1][1] * $matrix->[2][2] + $matrix->[1][0]
      * $matrix->[2][1] * $matrix->[0][2] + $matrix->[2][0] * $matrix->[0][1] *
      $matrix->[1][2] - $matrix->[0][2] * $matrix->[1][1] * $matrix->[2][0] -
      $matrix->[1][2] * $matrix->[2][1] * $matrix->[0][0] - $matrix->[2][2] *
      $matrix->[0][1] * $matrix->[1][0]
      if $size == 3;

    my $det;
    foreach ( 0 .. $size - 1 ) {
        if ( $_ % 2 ) {
            $det -=
              $matrix->[0][$_] *
              _det_helper( _matrix_slice( $matrix, 0, $_ ), $size - 1 );
        }
        else {
            $det +=
              $matrix->[0][$_] *
              _det_helper( _matrix_slice( $matrix, 0, $_ ), $size - 1 );
        }
    }
    return $det;
}

sub _matrix_slice {
    my $matrix = shift;
    my $x      = shift;
    my $y      = shift;

    return [ map { [ @{$_}[ 0 .. $y - 1, $y + 1 ... $#$_ ] ] }
          @{$matrix}[ 0 .. $x - 1, $x + 1 .. $#$matrix ] ];
}

=head2 linear_solve

Calculates the solutions x (vector) of a linear equation system of the form
C<Ax = b> with C<A> being a matrix, C<b> a vector and the solution C<x> a
vector. Due to implementation limitations, C<A> must be a quadratic matrix and
C<b> must have a dimension that is equivalent to that of C<A>. Furthermore,
the determinant of C<A> must be non-zero. The algorithm used is devised from
Cramer's Rule and thus inefficient. The preferred algorithm for this task is
Gaussian Elimination. If you have a matrix and a vector of real numbers, please
consider using either Math::MatrixReal or Math::Pari instead.

First argument must be a reference to a matrix (array of arrays) of symbolic
terms, second argument must be a reference to a vector (array) of symbolic
terms. Strings will be automatically converted to Math::Symbolic trees.
Returns a reference to the solution vector.

=cut

sub linear_solve {
    my ( $m, $v ) = @_;
    my $dim = @$v;

    croak "linear_solve(Matrix, Vector) requires n x n matrix and n-vector!"
      if @$m != $dim;
    foreach (@$m) {
        croak "linear_solve(Matrix, Vector) requires n x n matrix and n-vector!"
          if @$_ != $dim;
        foreach (@$_) {
            $_ = Math::Symbolic::parse_from_string($_)
              if ref($_) !~ /^Math::Symbolic/;
        }
    }
    foreach (@$v) {
        $_ = Math::Symbolic::parse_from_string($_)
          if ref($_) !~ /^Math::Symbolic/;
    }

    my $det = det @$m;

    my @vec;

    foreach my $i ( 0 .. $#$m ) {
        my $nm = _replace_col( $m, $v, $i );
        my $det_i = det @$nm;
        push @vec, $det_i / $det;
    }

    return \@vec;
}

sub _replace_col {
    my $m   = shift;
    my $v   = shift;
    my $col = shift;
    my $nm  = [];
    foreach my $i ( 0 .. $#$m ) {
        $nm->[$i] = [
            @{ $m->[$i] }[ 0 .. $col - 1 ],
            $v->[$i],
            @{ $m->[$i] }[ $col + 1 .. $#$m ]
        ];
    }
    return $nm;
}

=head2 bell_polynomial

This functions returns the nth Bell Polynomial. It uses memoization for
speed increase.

First argument is the n. Second (optional) argument is the variable or
variable name to use in the polynomial. Defaults to 'x'.

The Bell Polynomial is defined as follows:

  phi_0  (x) = 1
  phi_n+1(x) = x * ( phi_n(x) + partial_derivative( phi_n(x), x ) )

Bell Polynomials are Exponential Polynimals with phi_n(1) = the nth bell
number. Please refer to the bell_number() function in the
Math::Symbolic::AuxFunctions module for a method of generating these numbers.

=cut

memoize('bell_polynomial');

sub bell_polynomial {
    my $n   = shift;
    my $var = shift;
    $var = 'x' if not defined $var;
    $var = Math::Symbolic::Variable->new($var);

    return undef                            if $n < 0;
    return Math::Symbolic::Constant->new(1) if $n == 0;
    return $var                             if $n == 1;

    my $bell = bell_polynomial( $n - 1 );
    $bell = Math::Symbolic::Operator->new(
        '+',
        Math::Symbolic::Operator->new( '*', $var, $bell )->simplify(),
        Math::Symbolic::Operator->new(
            '*',
            $var,
            Math::Symbolic::Operator->new( 'partial_derivative', $bell, $var )
              ->apply_derivatives()->simplify()
          )->simplify()
    );
    return $bell;
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

