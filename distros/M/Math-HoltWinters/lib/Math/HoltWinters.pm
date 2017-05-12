
package Math::HoltWinters;

# Time series smoothing and forecasting with Holt-Winters exponential smoothing

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.03';

# ============================================================

sub single {
  my ( $alpha, $x0 ) = @_; # initial point, optional

  return sub {
    my ( $x ) = @_; # $x is optional (forecast if undef)

    unless( defined $x0 ) { # initialize $x0 if not done yet
      $x0 = $x;
      return $x0;
    }

    if( defined $x ) {      # only update for new data, no-op for forecast
      $x0 = $alpha*$x + (1-$alpha)*$x0
    }

    return $x0;
  }
}

sub double {
  my ( $alpha, $beta, $x0, $t0 ) = @_; # initial point and trend, both optional

  return sub {
    my ( $x ) = @_;

    # first point: $x0 not defined
    unless( defined $x0 ) {
      $x0 = $x;
      return $x0;
    }

    # second point: $x0 defined, $t0 not defined
    unless( defined $t0 ) {
      $t0 = $x - $x0;
      $x0 = $alpha*$x + (1-$alpha)*$x0; # sgl exponential smoothing!
      return $x0;
    }

    # other points: $0, $t0, $x all defined
    if( defined $x ) {
      my $old = $x0;
      $x0 = $alpha*$x + (1-$alpha)*($old + $t0);
      $t0 = $beta*($x0-$old) + (1-$beta)*$t0;
      return $x0;
    }

    # forecast: $x not defined
    if( !defined $x ) {
      $x0 += $t0;
      return $x0;
    }
  }
}

sub triple_add {
  my $alpha = shift;
  my $beta  = shift;
  my $gamma = shift;
  my $season = pop;      # seasonality information is alwas the LAST argument

  my ( $x0, $t0, @p );
  $x0 = shift if @_;
  $t0 = shift if @_;
  @p = ref $season ? @$season : (0) x $season;

# if( ref $season ) {
#   @p = @$season;            # perform deep copy
# } else {
#   @p = (0) x $season;
# }

  return sub {
    my ( $x ) = @_;

    my $p0 = shift @p;

    if( !defined $x0 ) {         # First point
      $x0 = $x;

    } elsif( !defined $t0 ) {    # Second point
      $t0 = $x - $x0;
      $x0 = $alpha*$x + (1-$alpha)*$x0;

    } elsif( defined $x ) {      # Smoothing
      my $old = $x0;

      $x0 = $alpha*($x - $p0) + (1-$alpha)*($old + $t0);
      $t0 = $beta*($x0 - $old) + (1-$beta)*$t0;
      $p0 = $gamma*($x - $x0) + (1-$gamma)*$p0;

    } else {                     # Forecasting
      $x0 += $t0;
    }
    push @p, $p0;

    return $x0 + $p0;
  }
}

sub triple_mul {
  my $alpha = shift;
  my $beta  = shift;
  my $gamma = shift;
  my $season = pop;      # seasonality information is alwas the LAST argument

  my ( $x0, $t0, @p );
  $x0 = shift if @_;
  $t0 = shift if @_;
  @p = ref $season ? @$season : (1) x $season;


  return sub {
    my ( $x ) = @_;

    my $p0 = shift @p;

    if( !defined $x0 ) {         # First point
      $x0 = $x;

    } elsif( !defined $t0 ) {    # Second point
      $t0 = $x - $x0;
      $x0 = $alpha*$x + (1-$alpha)*$x0;

    } elsif( defined $x ) {      # Smoothing
      my $old = $x0;

      # >>> What happens if either $p0 or $x0 is every zero? <<<
      $x0 = $alpha*$x/$p0 + (1-$alpha)*($old + $t0);
      $t0 = $beta*($x0 - $old) + (1-$beta)*$t0;
      $p0 = $gamma*$x/$x0 + (1-$gamma)*$p0;

    } else {                     # Forecasting
      $x0 += $t0;
    }
    push @p, $p0;

    return $x0*$p0;
  }
}

1;

__END__

=head1 NAME

Math::HoltWinters - Time series smoothing and forecasting using exponential smoothing


=head1 SYNOPSIS

  use Math::HoltWinters;

  $s = Math::HoltWinters::single( $alpha );
  $s = Math::HoltWinters::single( $alpha, $x0 );

  $s = Math::HoltWinters::double( $alpha, $beta );
  $s = Math::HoltWinters::double( $alpha, $beta, $x0 );
  $s = Math::HoltWinters::double( $alpha, $beta, $x0, $t0 );

  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, $n );
  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, $x0, $n );
  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, $x0, $t0, $n );

  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, \@p );
  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, $x0, \@p );
  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, $x0, $t0, \@p );

  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, $n );
  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, $x0, $n );
  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, $x0, $t0, $n );

  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, \@p );
  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, $x0, \@p );
  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, $x0, $t0, \@p );


  # Smoothing data:
  for( @data ) {
    push @smoothed, $s->( $_ );
  }

  # Forecasting five steps:
  for( 1..5 ) {
    push @forecast, $s->();
  }

  # Alternative syntax (including both smoothing and forecasting):
  @result = map { $s->( $_ ) } ( @data, (undef) x 5 );


=head1 DESCRIPTION

This module provides functions to perform exponential smoothing and
forecasting for time series data (Holt-Winters method). The module
supports I<single> (for stationary time series without trend), I<double>
(for time series with trend) and I<triple> (for time series with trend
and seasonality) exponential smoothing. Separate methods exist to
handle additive and multiplicative seasonality.

This module provides four functions (one for each form of exponential
smoothing), which instantiate a I<function reference>. When applied
to the raw time series data, this function reference will return the
smoothed value of the time series; when applied to an undefined
argument, the function reference will return a forecast.

B<Caveat:> The function references maintain state between invocations!
(This is how they do their job). It is therefore necessary to let them
operate on the input data only once and in the proper order. The function
references can not be reused - if you want to redo a calculation (for
instance with different values for the smoothing parameters), you must
instantiate new function references.


=head2 DETAILS

All functions in this module return a function reference, which can be
used for smoothing and forecasting. All functions take between one and
three I<smoothing parameters> (C<$alpha>, C<$beta>, C<$gamma>), which
control the amount of smoothing applied. These parameters are mandatory,
and their values should (but are not required to) fall between 0 and 1.
All functions also take optional values which are used to start up the
recursion; if they are not supplied, appropriate values are inferred
from the data. (These hints are typically only necessary for very short
data sets.)

  $s = Math::HoltWinters::single( $alpha );
  $s = Math::HoltWinters::single( $alpha, $x0 );

Instantiates a function reference that performs single exponential
smoothing, with smoothing parameter C<$alpha>. The value to be used
for the initial smoothed point can be supplied as an optional parameter,
if it not provided, the initial data point is used as the initial smoothed
value.

  $s = Math::HoltWinters::double( $alpha, $beta );
  $s = Math::HoltWinters::double( $alpha, $beta, $x0 );
  $s = Math::HoltWinters::double( $alpha, $beta, $x0, $t0 );

Instantiates a function reference that performs double exponential
smoothing, with smoothing parameter C<$alpha> and C<$beta>. Values for
the initial smoothed point and the initial smoothed trend can be supplied
as optional parameters. If they are not provided, they are calculated from
the first points of the data.

  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, $n );
  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, $x0, $n );
  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, $x0, $t0, $n );

  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, \@p );
  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, $x0, \@p );
  $s = Math::HoltWinters::triple_add( $alpha, $beta, $gamma, $x0, $t0, \@p );

Instantiates a function reference that performs triple exponential
smoothing, assuming additive seasonality, with smoothing parameter
C<$alpha>, C<$beta>, and C<$gamma>. Values for the initial smoothed
point and the initial smoothed trend can be supplied as optional
parameters. If they are not provided, they are calculated from the
first points of the data.

The number of points per season I<must> be provided for triple
exponential smoothing; this information is always supplied through the
I<last> argument to the constructor. There are two ways to supply this
seasonality information: if the last argument is a scalar, it is
interpreted as the number of points per season and the remaining
information is inferred from the data. Alternatively, the last
argument can be reference to an array of the appropriate length (that
is, as many elements as there are points in a season) holding initial
values for the magnitude of the seasonality effect.

  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, $n );
  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, $x0, $n );
  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, $x0, $t0, $n );

  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, \@p );
  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, $x0, \@p );
  $s = Math::HoltWinters::triple_mul( $alpha, $beta, $gamma, $x0, $t0, \@p );

Instantiates a function reference that performs triple exponential
smoothing, assuming multiplicative seasonality, with smoothing parameter
C<$alpha>, C<$beta>, and C<$gamma>. Values for the initial smoothed
point and the initial smoothed trend can be supplied as optional
parameters. If they are not provided, they are calculated from the
first points of the data.

The number of points per season I<must> be provided for triple
exponential smoothing; this information is always supplied through the
I<last> argument to the constructor. There are two ways to supply this
seasonality information: if the last argument is a scalar, it is
interpreted as the number of points per season and the remaining
information is inferred from the data. Alternatively, the last
argument can be reference to an array of the appropriate length (that
is, as many elements as there are points in a season) holding initial
values for the magnitude of the seasonality effect.


=head2 USAGE

The function reference returned from any of the four functions can be
applied to any numeric value, returning a numeric (smoothed) value. If
the function reference is invoked with an undefined argument (or none),
it returns the best forecast, based on its most recent state. This
feature can be used to extend a smoothed time series past the last
data point.

  # Smoothing:
  for( @data ) {
    push @smoothed, $s->( $_ );
  }

  # Forecasting five steps:
  for( 1..5 ) {
    push @forecast, $s->();
  }

Because the function reference maintains state between invocations,
it must be invoked exactly once for each data point, and the data
points must be supplied in proper time order (from earliest to latest).
Similarly, to create a forecast, the function reference has to be
invoked (with undefined argument) immediately after it has been applied
to the available data.

It is not possible to make the function reference go backward in time,
or to reuse it for a second smoothing run. Instead, create a new function
reference from scratch.

However, it is possible to have several function references in existence
and operating concurrently - no state is shared across instances.


=head2 EXPORT

This module does not export any functions.


=head2 LIMITATIONS AND RATIONALE

The functions provided by this module only implement the Holt-Winters
methods for smoothing and forecasting. They do neither provide
functionality to evaluate the error between the smoothed and the raw
data, nor to determine the "optimal" values of the smoothing
parameters (alpha, beta, gamma).

The fitting parameters (alpha, beta, gamma) need to specified at
initialization time and cannot be changed later. This is intentional,
for two reasons: first of all, it corresponds to the typical use case
of Holt-Winters methods (it is rare to change these parameters in the
middle of a data set). More importantly, it serves as a reminder that
the (stateful) function references cannot be reused: if you want to
change the parameters, you have to obtain a new function reference.


=head2 MATHEMATICAL REFERENCE

The exponential smoothing calculations can be defined in several different
ways. This module uses the following conventions, where C<d[i]> is the raw
data at time step C<i>, and C<y[i+k]> is the returned value (smoothed or
forecasted) at time step C<i+k>, and C<n> is the number of points per
season:

  # Single
  x[i] = alpha*d[i] + (1-alpha)*x[i-1]
  y[i+k] = x[i]                k=0, 1, 2, ...

  # Double
  x[i] = alpha*d[i] + (1-alpha)*(x[i-1] + t[i-1])
  t[i] = beta*(x[i] - x[i-1]) + (1-beta)*t[i-1]
  y[i+k] = x[i] + k*t[i]       k=0, 1, 2, ...

  # Triple, additive
  x[i] = alpha*(d[i] - p[i-n]) + (1-alpha)*(x[i-1] + t[i-1])
  t[i] = beta*(x[i] - x[i-1]) + (1-beta)*t[i-1]
  p[i] = gamma*(d[i] - s[i]) + (1-gamma)*p[i-n]
  y[i+k] = x[i] + k*t[i] + p[i-n+k]

  # Triple, multiplicative
  x[i] = alpha*d[i]/p[i-n] + (1-alpha)*(x[i-1] + t[i-1])
  t[i] = beta*(x[i] - x[i-1]) + (1-beta)*t[i-1]
  p[i] = gamma*d[i]/s[i] + (1-gamma)*p[i-n]
  y[i+k] = (x[i] + k*t[i])*p[i-n+k]


=head1 SEE ALSO

=over 4

=item *
Data Analysis with Open Source Tools by Philipp K. Janert; O'Reilly, 2010
I<For a general introduction to data analysis. Time series analysis, 
including Holt-Winters methods, are treated in chapter 4.>

=item *
The Analysis of Time Series: An Introduction by Chris Chatfield;
Chapman & Hall, 6th ed, 2003
I<A more in-depth, yet practical and accessible introduction to time series
analysis.>

=item *
NIST/SEMATECH e-Handbook of Statistical Methods
(L<http://www.itl.nist.gov/div898/handbook/index.htm>)
I<An online reference to statistical methods; section 6.4.3 introduces
Holt-Winters methods.>

=back


=head1 AUTHOR

Philipp K. Janert, E<lt>janert at ieee dot orgE<gt>, http://www.beyondcode.org


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Philipp K. Janert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
