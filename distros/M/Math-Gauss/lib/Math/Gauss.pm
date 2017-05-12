package Math::Gauss;

use 5.010000;
use strict;
use warnings;
use Carp;

require Exporter;
our @ISA = qw( Exporter );
our %EXPORT_TAGS = ( 'all' => [qw( pdf cdf inv_cdf )] );
Exporter::export_ok_tags( 'all' );

our $VERSION = '0.01';

my $SQRT2PI = 2.506628274631;

sub pdf {
  my ( $x, $m, $s ) = ( 0, 0, 1 );
  $x = shift if @_;
  $m = shift if @_;
  $s = shift if @_;

  if( $s <= 0 ) {
    croak( "Can't evaluate Math::Gauss:pdf for \$s=$s not strictly positive" );
  }

  my $z = ($x-$m)/$s;

  return exp(-0.5*$z*$z)/($SQRT2PI*$s);
}

sub cdf {
  my ( $x, $m, $s ) = ( 0, 0, 1 );
  $x = shift if @_;
  $m = shift if @_;
  $s = shift if @_;

  # Abramowitz & Stegun, 26.2.17
  # absolute error less than 7.5e-8 for all x

  if( $s <= 0 ) {
    croak( "Can't evaluate Math::Gauss:cdf for \$s=$s not strictly positive" );
  }

  my $z = ($x-$m)/$s;

  my $t = 1.0/(1.0 + 0.2316419*abs($z));
  my $y = $t*(0.319381530
	      + $t*(-0.356563782
		    + $t*(1.781477937
			  + $t*(-1.821255978
				+ $t*1.330274429 ))));
  if( $z > 0 ) {
    return 1.0 - pdf( $z )*$y;
  } else {
    return pdf( $z )*$y;
  }
}

sub inv_cdf {
  my ( $x ) = @_;

  if( $x<=0.0 || $x>=1.0 ) {
    croak( "Can't evaluate Math::Gauss::inv_cdf for \$x=$x outside ]0,1[" );
  }

  # Abramowitz & Stegun, 26.2.23
  # absolute error less than 4.5e-4 for all x

  my $t;
  if( $x < 0.5 ) {
    $t = sqrt( -2.0*log($x) );
  } else {
    $t = sqrt( -2.0*log(1.0 - $x) );
  }

  my $y = (2.515517 + $t*(0.802853 + $t*0.010328));
  $y /= 1.0 + $t*(1.432788 + $t*(0.189269 + $t*0.001308));

  if( $x<0.5 ) {
    return ( $y - $t );
  } else {
    return ( $t - $y );
  }
}

1;
__END__


# Rationale:
#
# - Simple, straightforward interface
# - Pure Perl implementation for portability
# - Include the inverse CDF (occasionally required, but hard to find)
# - Good-enough accuracy, in return for simple, fast, non-iterative
#     implementations


=head1 NAME

Math::Gauss - Gaussian distribution function and its inverse

=head1 SYNOPSIS

  use Math::Gauss ':all';

  $p = pdf( $z );
  $p = pdf( $x, $m, $s );

  $c = cdf( $z );
  $c = cdf( $x, $m, $s );

  $z = inv_cdf( $z );

=head1 DESCRIPTION

This module calculates the Gaussian probability density, the cumulative
distribution function (Gaussian distribution function), and the inverse
Gaussian distribution function.

=head2 EXPORT

None by default. The C<:all> tag is recognized, or import individual
functions.

=head2 FUNCTIONS

B<C<pdf( $x, $m, $s )>>

The Gaussian probability density function (pdf)

  exp( -0.5 ( (x-m)/s )**2 )/sqrt(2*pi*s**2)

Only the first argument is mandatory, the other two are optional. If they
are not supplied, they default as follows: C<pdf( $z ) == pdf( $x, 0, 1 )>.

The parameter C<$s> must be strictly positive, C<$x> and C<$m> can be
arbitrary.

If you choose to supply the z-score, C<$z = ($x-$m)/$s> as argument to
the pdf() instead of supplying the mean and the standard deviation as
separate arguments, you must divide the return value by the standard
deviation to obtain a properly normalized result. The following is true:

  pdf( $x, $m, $s ) == pdf( ($x-$m)/$s )/$s


B<C<cdf( $x, $m, $s )>>

The Gaussian cumulative distribution function (cdf). This is the integral
of pdf(t,m,s) from -infinity to x over t:

  int_{-infty}^x exp( -0.5 ( (t-m)/s )**2 )/sqrt(2*pi*s**2) dt

Only the first argument is mandatory, the other two are optional. If they
are not supplied, they default as follows: C<cdf( $z ) == cdf( $x, 0, 1 )>.

The parameter C<$s> must be strictly positive, C<$x> and C<$m> can be
arbitrary.

The implementation is guaranteed to have a maximum absolute error of less
than 7.5e-8 for all x.


B<C<inv_cdf( $z )>>

The inverse of the Gaussian cumulative distribution function. This
function is only defined for arguments strictly greater than 0 and
strictly less than 1: C<0 < $z < 1>.

The implementation is guaranteed to have a maximum absolute error of
less than 4.5e-4 for all x.


=head1 USAGE NOTES

This module favors simplicity and portability over accuracy. The
accuracy should be good enough for most applications; if you need
higher accuracy, see the resources below.

The cumulative distribution function and its inverse defined by this
module are the so-called "probability function" versions. They are
related to the "error function" C<erf()> and its inverse C<inverf()>
by:

  erf(x) = 2 cdf( sqrt(2)*x ) - 1
  inverf(x) = inv_cdf( (x+1)/2 )/sqrt(2)


=head1 SEE ALSO

The numerical algorithms are taken from:

I<Handbook of Mathematical Functions: with Formulas, Graphs, and
Mathematical Tables> by Milton Abramowitz and Irene A. Stegun;
Dover (1965).

Alternative algorithms (including a high-accuracy algorithm for the
inverse distribution functions) can be found here:

=over 4

=item

http://home.online.no/~pjacklam/notes/invnorm/

=item

http://homepages.physik.uni-muenchen.de/~Winitzki/erf-approx.pdf

=back


=head1 AUTHOR

Philipp K. Janert, E<lt>janert at ieee dot orgE<gt>, http://www.beyondcode.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Philipp K. Janert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut



































