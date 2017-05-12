# Copyright (c) 2002-2008 Anders Johnson. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same terms
# as Perl itself. The author categorically disclaims any liability for this
# software.

=head1 NAME

Math::Business::BlackScholes - Black-Scholes option price model functions

=head1 SYNOPSIS

	use Math::Business::BlackScholes
	  qw/call_price call_put_prices implied_volatility_call/;

	my $volatility=implied_volatility_call(
	  $current_market_price, $option_price_in, $strike_price_in,
	  $remaining_term_in, $interest_rate, $fractional_yield
	);

	my $call=call_price(
	  $current_market_price, $volatility, $strike_price,
	  $remaining_term, $interest_rate, $fractional_yield
	);

	$volatility=Math::Business::BlackScholes::historical_volatility(
	  \@closing_prices, 251
	);

	my $put=Math::Business::BlackScholes::put_price(
	  $current_market_price, $volatility, $strike_price,
	  $remaining_term, $interest_rate
	); # $fractional_yield defaults to 0.0

	my ($c, $p)=call_put_prices(
	  $current_market_price, $volatility, $strike_price,
	  $remaining_term, $interest_rate, $fractional_yield
	);

	my $call_discrete_div=call_price(
	  $current_market_price, $volatility, $strike_price,
	  $remaining_term, $interest_rate,
	  { 0.3 => 0.35, 0.55 => 0.35 }
	);

=head1 DESCRIPTION

Estimates the fair market price of a European stock option
according to the Black-Scholes model.

call_price() returns the price of a call option.
put_price() returns the value of a put option.
call_put_prices() returns a 2-element array whose first element is the price
of a call option, and whose second element is the price of the put option
with the same parameters; it is expected to be computationally more efficient
than calling call_price() and put_price() sequentially with the same arguments.
Each of these routines accepts the same set of parameters:

C<$current_market_price> is the price for which the underlying security is
currently trading.
C<$volatility> is the standard deviation of the probability distribution of
the natural logarithm of the stock price one year in the future.
C<$strike_price> is the strike price of the option.
C<$remaining_term> is the time remaining until the option expires, in years.
C<$interest_rate> is the risk-free interest rate (per year) as a fraction.
C<$fractional_yield> is the fraction of the stock price that the stock
yields in dividends per year; it is assumed to be zero if unspecified.

=head2 Discrete Dividends

If C<$fractional_yield> is specified as a number, then the actual timing of
the ex-dividend dates relative to the current time and the option expiration
time can affect the option price by as much as the value of a single dividend.

C<$fractional_yield> may instead be specified as a hashref, each key of which
is the remaining amount of time before the dividend is paid, in years,
and each value of which is the dividend amount.
This produces more accurate results when the dividends that will be assigned
during the term of the option are reliably predictable.
The ex-dividend date of each dividend so represented is assumed to occur
within the I<remaining> term of the option, even if the dividend is paid
after the term expires.

=head2 Determining Parameter Values

C<$volatility> and C<$fractional_yield> are traditionally estimated based on
historical data.
C<$interest_rate> is traditionally equal to the current T-bill rate.
The model assumes that these parameters are stable over the term of the
option.

C<$volatility> (a.k.a. I<sigma>) is sometimes expressed as a percentage,
which is misleading because it's not a ratio.
If you have it as a percentage, then you'll need to divide it by 100 before
passing it to this module.
Ditto for C<$interest_rate> and C<$fractional_yield>.

Two ways to estimate C<$volatility> are provided.
historical_volatility() takes an arrayref of at least 10 (preferably 100 or
more) consecutive daily closing prices of the underlying security, in either
chronological or reverse chronological order.
It then multiplies the variance of the log of day-to-day returns by the number
of trading days per year specified by the second argument (or 250 by default).
The square-root of this yearly variance is returned.

implied_volatility_call() computes the implied volatility based on the known
trading price of a "reference" call option on the same underlying security with
a different strike price and/or term, using the Newton-Raphson method, or the
bisection method if it fails to converge otherwise.
It's invoked like call_price(), except that the second argument is taken as
the price of the call option, and the volatility is returned.
You can override the default option price tolerance of 1e-4 by passing an
additional argument beyond C<$fractional_yield>.
If called in an array context, the second element of the return value is an
estimate of the error magnitude, and the third element is the number of
iterations required to obtain the result.
The error magnitude may be quite large unless you use a
reference option whose price exceeds its intrinsic value by an amount larger
than or comparable to the absolute difference of the market price and the
strike price, and it is undefined if the price of the reference option is
less than what would be calculated with zero volatility.
If the price of the reference option is greater than what would be calculated
with infinite volatility, then both the result and the error estimate are
undefined.
An exception is thrown if it fails to converge within
C<$Math::Business::BlackScholes::max_iter> (100 by default) iterations.
An analogous implied_volatility_put() is also available.

=head2 American Options

Whereas a European stock option may be exercised only when it expires,
an American option may be exercised any time prior to its expiration.
The price of an American option can be approximated as the maximum price
of similar European options over all possible remaining terms not greater
than the remaining term of the American option.
This maximum usually occurs at the end of the remaining term, or just before
or just after the final ex-dividend date within the remaining term.

=head2 Negative Market Value

An underlying security with a negative market value is assumed to be a short.
Buying a short is equivalent to selling the security, so a call option on
a short is equivalent to a put option.
This is somewhat confusing, and arguably a warning ought to be generated if
it gets invoked.

=head1 DIAGNOSTICS

Attempting to evaluate an option with a negative term will result in a croak(),
because that's meaningless.
Passing suspicious arguments (I<e.g.> a negative interest rate) will result
in descriptive warning messages.
To disable such messages, try this:

	{
		local($SIG{__WARN__})=sub{};
		$value=call_price( ... );
	}

=head1 CAVEATS

=over 2

=item *

This module requires C<Math::CDF>.

=item *

The fractional computational error of call_price() and put_price() is
usually negligible.
However, while the computational error of second result of call_put_prices()
is typically small in comparison to the current market price, it might be
significant in comparison to the result itself.
That's probably unimportant for most purposes.

=item *

historical_volatility() tends to produce misleading results because the
behavior of the underlying security is most likely not truly log-normal.
In particular, the price varies predictably after a dividend is distributed,
and the daily variance is expected to be greater after financial announcements
are made.
Also, a large number of data points are required to obtain statistically
meaningful results, but having a large number of data points implies that the
results are outdated.

=item *

The author categorically disclaims any liability for this module.

=back

=head1 BUGS

=over 2

=item *

The length of the namespace component "BlackScholes" is said to cause
unspecified portability problems for DOS and other 8.3 filesystems,
but the consensus of the Perl community was that it is more important
to have a descriptive name.

=item *

You can't passed a blessed reference with the C<0+> (numeric conversion)
operator overloaded (see L<overload>) as a numerical C<$fractional_yield>.
Instead, convert it into a numeric scalar before calling these functions.

=back

=head1 SEE ALSO

L<Math::CDF|Math::CDF>

=head1 AUTHOR

Anders Johnson <F<anders@ieee.org>>

=head1 ACKNOWLEDGMENTS

Thanks to Richard Solberg for helping to debug the implied volatility
functions.

=cut

package Math::Business::BlackScholes;

use strict;

BEGIN {
	use Exporter;
	use vars qw/$VERSION @ISA @EXPORT_OK/;
	$VERSION = 1.01;
	@ISA = qw/Exporter/;
	@EXPORT_OK = (
	  qw/call_price put_price call_put_prices/,
	  qw/historical_volatility/,
	  qw/implied_volatility_call implied_volatility_put/
	);
}

use Math::CDF qw/pnorm/;
use Carp;

# Don't call this directly -- it might change without notice
sub _precompute1 {
	my (
	  $st, $lsx, $put, $adj_market, $sigma, $strike, $term,
	  $interest, $adj_yield
	)=@_;

	my $seyt=$adj_market * exp(-$adj_yield * $term);
	my $xert=$strike * exp(-$interest * $term);
	my $d1;
	my $nd1;
	my $nd2;
	if($sigma==0.0 || $term==0.0 || $adj_market==0.0 || $strike<=0.0) {
		if($seyt > $xert) {
			($nd1, $nd2) = $put ? (0.0, 0.0) : (1.0, 1.0);
		}
		else {
			($nd1, $nd2) = $put ? (-1.0, -1.0) : (0.0, 0.0);
		}
	}
	else {
		my $ssrt=$sigma * $st;
		$d1=(
		  $lsx + ($interest - $adj_yield + 0.5*$sigma*$sigma)*$term
		) / $ssrt;
		my $d2=$d1 - $ssrt;
		($nd1, $nd2) = $put ?
		  (-pnorm(-$d1), -pnorm(-$d2)) : (pnorm($d1), pnorm($d2));
	}
	return ($seyt*$nd1 - $xert*$nd2, $seyt, $xert, $d1);
}

# Don't call this directly -- it might change without notice
sub _precompute {
	@_<6 && carp("Too few arguments");
	my ($put, $market, $sigma, $strike, $term, $interest, $yield)=@_;

	$market>=0.0 || croak("Negative market price");
	if($sigma<0.0) {
		carp("Negative volatility (using absolute value instead)");
		$sigma=-$sigma;
	}
	$strike>=0.0 || carp("Negative strike price");
	$term>=0.0 || croak("Negative remaining term");
	$interest>=0.0 || carp("Negative interest rate");
	my ($adj_market, $adj_yield) = ($market, $yield);
	if(ref $yield) {
		my $warned;
		for my $when (keys %$yield) {
			unless($when>=0) {
				unless($warned++) {
					carp("Negative dividend time");
				}
			}
			$adj_market -= $yield->{$when}*exp(-$interest * $when);
		}
		$adj_yield=0.0;
	}
	elsif(!defined $yield) {
		$adj_yield=0.0;
	}
	$adj_yield>=0.0 || carp("Negative yield");
	@_>7 && carp("Ignoring additional arguments");

	my $st=sqrt($term);
	my $sx=$adj_market / $strike;
	my $lsx=log($sx) if $sx>0;
	return (
	  _precompute1(
	    $st, $lsx, $put, $adj_market, $sigma, $strike, $term,
	    $interest, $adj_yield
	  ), $st, $lsx, $adj_market, $adj_yield
	);
}

sub call_price {
	if($_[0]<0.0) {
		return put_price(-$_[0], $_[1], -$_[2], @_[3..$#_]);
	}
	my ($price) = _precompute(0, @_);
	return $price;
}

sub put_price {
	if($_[0]<0.0) {
		return call_price(-$_[0], $_[1], -$_[2], @_[3..$#_]);
	}
	my ($price) = _precompute(1, @_);
	return $price;
}

sub call_put_prices {
	if($_[0]<0.0) {
		my ($put, $call)=call_put_prices(
		  -$_[0], $_[1], -$_[2], @_[3..$#_]
		);
		return ($call, $put);
	}
	my ($call, $seyt, $xert) = _precompute(0, @_);
	return ($call, $call - $seyt + $xert);
}

sub historical_volatility {
	my ($close, $days)=@_;
	$days=250 unless defined $days;
	my @close=@$close; # Don't clobber the argument
	if(@close<10) {
		croak "Not enough data points"
	}
	my ($tot, $sqtot, $n)=(0.0, 0.0, 0);
	my $last=log(shift(@close));
	while(@close) {
		my $next=log(shift(@close));
		my $ret=$next-$last;
		$tot+=$ret;
		$sqtot+=$ret*$ret;
		$n++;
		$last=$next;
	}
	return sqrt($days * ($sqtot - $tot*$tot/$n)/($n-1));
}

sub implied_volatility_call {
	if($_[0]<0.0) {
		return implied_volatility_put(
		  -$_[0], $_[1], -$_[2], @_[3..$#_]
		);
	}
	return _implied_volatility(0, @_);
}

sub implied_volatility_put {
	if($_[0]<0.0) {
		return implied_volatility_call(
		  -$_[0], $_[1], -$_[2], @_[3..$#_]
		);
	}
	return _implied_volatility(1, @_);
}

use vars qw/$max_iter/;
$max_iter=100;
my $pipi; # becomes 1/sqrt(2*PI) when needed
# Don't call this directly -- it might change without notice
sub _implied_volatility {
	my $put=shift;
	my ($market, $option_price, $strike, $term, $interest, $yield, $tol)=@_;
	$yield=0 unless defined $yield;
	if(@_>7) {
		carp("Ignoring additional arguments");
		pop(@_) while @_>7;
	}
	pop(@_) if defined $tol;
	$tol=1e-4 unless defined $tol;
	$tol=abs($tol);
	$market>0.0 ||
	  croak("Positive market price required to determine volatility");
	$strike>0.0 ||
	  croak("Positive strike price required to determine volatility");
	$term>0.0 || croak("Positive term required to determine volatility");
	$option_price>0.0 || croak("Option price must be positive");
	my $sigma_low=0.0;
	my ($price_low, $seyt, $xert, $d1, $st, $lsx, $adj_market, $adj_yield) =
	  _precompute(
	    $put, $market, 0.0, @_[2..$#_]
	  );
	my @precomp_args = @_[2..$#_];
	$precomp_args[3] = $adj_yield;
	return wantarray ? (0.0, undef, 0) : 0.0 if $price_low > $option_price;
	return wantarray ? (undef, undef, 0) : undef
	  if $option_price > ($put ? $xert : $seyt);
	my $sigma_high=($option_price)/(0.398*$market*$st);
	my $price_high;
	my $n=0;
	while($n<$max_iter) {
		($price_high, $seyt, $xert, $d1) = _precompute1(
		  $st, $lsx, $put, $adj_market, $sigma_high, @precomp_args
		);
		last if $price_high > $option_price-$tol;
		($sigma_low, $price_low) = ($sigma_high, $price_high);
		$sigma_high += $sigma_high;
		$n++;
	}
	$pipi=1/sqrt(4*atan2(1,0)) unless defined $pipi;
	my ($sigma, $price)=($sigma_high, $price_high);
	while(1) {
		my $diff=$option_price - $price;
 		my $done=abs($diff) < $tol;
		return $sigma if $done && !wantarray;
		if($diff>0.0) {
			($sigma_low, $price_low)=($sigma, $price);
		}
		else {
			($sigma_high, $price_high)=($sigma, $price);
		}
		my $npd1=defined($d1) ? $pipi * exp(-0.5*$d1*$d1) : 0.0;
		my $vega=$seyt * $st * $npd1;
		return ($sigma, $vega==0.0 ? undef : $tol/$vega, $n) if $done;
		last if $vega==0.0;
		$sigma+=$diff/$vega;
		$sigma=$sigma_low if $sigma<$sigma_low;
		last if $diff>0.0 && $sigma>0.5*($sigma_low+$sigma_high);
		$n++;
		last if $n>=$max_iter;
		($price, $seyt, $xert, $d1) = _precompute1(
		  $st, $lsx, $put, $adj_market, $sigma, @precomp_args
		);
	}

	# If Newton-Raphson fails, try the bisection method
	while($n<$max_iter) {
		$sigma=0.5 * ($sigma_low + $sigma_high);
		($price) = _precompute1(
		  $st, $lsx, $put, $adj_market, $sigma, @precomp_args
		);
		if(abs($option_price - $price) < $tol) {
			return wantarray ?
  ($sigma, $tol * ($sigma_high-$sigma_low) / ($price_high-$price_low), $n) :
			  $sigma;
		}
		if($price > $option_price) {
			($sigma_high, $price_high) = ($sigma, $price);
		}
		else {
			($sigma_low, $price_low) = ($sigma, $price);
		}
		$n++;
	}
	confess "_implied_volatility() failed to converge";
}

1;

