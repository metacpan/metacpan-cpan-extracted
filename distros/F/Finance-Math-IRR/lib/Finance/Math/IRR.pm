#################################################################
#
#   Finance::Math::IRR - Calculate the internal rate of return of a cash flow
#
#   $Id: IRR.pm,v 1.5 2007/07/12 12:35:46 erwan_lemonnier Exp $
#
#   061215 erwan Started implementation
#   061218 erwan Differentiate bugs from failures when calling secant() and brent()
#   061218 erwan Handle precision correctly
#   061218 erwan Support cashflows with only 0 amounts
#   070220 erwan Support when secant converges toward a non root value
#   070404 erwan Cleanup cashflow from transactions of amount 0
#   070404 erwan Error if last transaction is a positive amount. Added $DEBUG
#   070411 erwan Return undef when cashflow has only 1 non zero transaction
#   070418 erwan Update license
#   070711 erwan Removed the restriction requiring the last transaction to be negative
#

package Finance::Math::IRR;

use 5.006;
use strict;
use warnings;
use Carp qw(confess croak);
use Data::Dumper;
use Math::Polynom;
use Date::Calc qw(Delta_Days);
use Scalar::Util qw(looks_like_number);
use base qw(Exporter);

our @EXPORT = qw(xirr);
our $VERSION = '0.10';
our $DEBUG = 0;

#----------------------------------------------------------------
#
#   parameters for secant and brent methods
#

my %ARGS_SECANT = ( p0 => 0.5,
		    p1 => 1,
		    max_depth => 100,
		  );

my %ARGS_BRENT = ( max_depth => 50 );

# how many couple of points to search for positive and negative values
my $MAX_POS_NEG_POINTS = 1024;

#----------------------------------------------------------------
#
#   _crash - die with a usable error description
#

sub _crash {
    my($method,$poly,$args,$err) = @_;

    croak "BUG: something went wrong while calling Math::Polynom::$method with the arguments:\n".
	Dumper($args)."on the polynomial:\n".
	Dumper($poly)."the error was: [$err]\n".
	"Please email all this output to erwan\@cpan.org\n";
}

#----------------------------------------------------------------
#
#   _debug
#

sub _debug {
    my $msg = shift;
    print STDOUT "Finance::Math::IRR: $msg\n" if ($DEBUG);
}

#----------------------------------------------------------------
#
#   xirr - calculate the internal rate of return of a cash flow
#

sub xirr {
    my $precision = 0.001; # default precision seeked on irr, ie 0.1%
    my $guess = 0.1;
    my %cashflow;
    my $root;

    #
    # Parse input arguments and build the cashflow's polynomial
    #

    croak("ERROR: xirr() got an odd number of arguments. this can not be correct") if (!scalar(@_) || scalar(@_) % 2);

    %cashflow = @_;

    _debug("xirr() called with arguments:\n".Dumper(\%cashflow));

    # parse arguments
    if (exists $cashflow{precision}) {
	$precision = $cashflow{precision};
	delete $cashflow{precision};
    }

    if (!defined $precision || !looks_like_number($precision)) {
	croak "ERROR: precision is not a valid number";
    }

    # remove intermediary transactions with 0 amount from cashflow
    my @sorted_dates = sort keys %cashflow;
    croak "ERROR: you provided an empty cash flow" if (scalar @sorted_dates == 0);

    my $date_end = $sorted_dates[-1];

    foreach my $date (@sorted_dates) {
	my $amount = $cashflow{$date};
	croak "ERROR: the provided cashflow contains undefined values"           if (!defined $date || !defined $amount);
	croak "ERROR: invalid date in the provided cashflow [$date]"             if ($date !~ /^\d\d\d\d-\d\d-\d\d$/);
	croak "ERROR: invalid amount in the provided cashflow at date [$date]"   if (!looks_like_number($amount));

	# remove transaction from cashflow if it has a 0 amount
	if ($amount == 0 && $date ne $date_end) {
	    delete $cashflow{$date};
	}
    }

    if ($cashflow{$date_end} == 0) {
	# the last value is 0: we may be able to handle it
	# was the whole cashflow made of transactions with amount 0?
	if (scalar keys %cashflow == 1) {
	    _debug("all transactions in the cashflow have 0 in amount. IRR=0.");
	    return 0;
	}
    }

    if (scalar keys %cashflow < 2) {
	# we got a cashflow with only 1 entry and can't calculate an irr on it
	return undef;
    }

    # TODO: what if all transactions have the same sign?

    # we want $precision on the irr, but can only steer the precision of 1/(1+irr), hence this ratio, that
    # should insure us the given precision even on the irr for irrs up to 1000%
    $precision = $precision / 1000;

    # build the polynomial whose solution is x=1/(1+IRR)
    @sorted_dates = sort keys %cashflow;
    my @date_start = split(/-/,$sorted_dates[0]);
    croak "BUG: expected 3 arguments after splitting [".$sorted_dates[0]."]" if (scalar @date_start != 3);

    my %coeffs;

    while (my($date,$amount) = each %cashflow) {
	my $ddays = Delta_Days(@date_start, split(/-/,$date));
	$coeffs{$ddays/365} = $amount;
    }

    my $poly = Math::Polynom->new(%coeffs);

    #
    # Find a real root of the polynomial
    #

    $ARGS_SECANT{precision} = $precision;

    _debug("trying secant method on interval [".$ARGS_SECANT{p0}."-".$ARGS_SECANT{p1}."] with precision ".
	   $ARGS_SECANT{precision}." and max ".$ARGS_SECANT{max_depth}." iterations");

    # try finding the IRR with the secant metho
    eval {
	$root = $poly->secant(%ARGS_SECANT);
    };

    if ($@) {
	# secant failed. let's make sure it was not a bug
	my $error = $poly->error;
	if ( grep( /^$error$/,
		   Math::Polynom::ERROR_NAN,
		   Math::Polynom::ERROR_DIVIDE_BY_ZERO,
		   Math::Polynom::ERROR_MAX_DEPTH,
		   Math::Polynom::ERROR_NOT_A_ROOT ) ) {
	    _debug("secant failed on with error code $error");
	} else {
	    # ok, the method did not fail, something else did
	    _crash("secant", $poly, \%ARGS_SECANT, $@);
	}

	# let's find two points where the polynomial is positive respectively negative
	my $i = 1;
	while ( (!defined $poly->xneg || !defined $poly->xpos) && $i <= $MAX_POS_NEG_POINTS ) {
	    $poly->eval( $i );
	    $poly->eval( -1+10/($i+9) );
	    $i++;
	}

	# if we did not find 2 points where the polynomial is >0 and <0, we can't use Brent's method (nor the bisection)
	if ( !defined $poly->xneg || !defined $poly->xpos ) {
	    _debug("failed to find an interval on which polynomial is >0 and <0 at the boundaries");
	    return undef;
	}

	# try finding the IRR with Brent's method
	$ARGS_BRENT{precision} = $precision;
	$ARGS_BRENT{a} = $poly->xneg;
	$ARGS_BRENT{b} = $poly->xpos;

	_debug("trying Brent's method on interval [".$ARGS_BRENT{a}."-".$ARGS_BRENT{b}."] with precision ".
	   $ARGS_BRENT{precision}." and max ".$ARGS_BRENT{max_depth}." iterations");

	eval {
	    $root = $poly->brent(%ARGS_BRENT);
	};

	if ($@) {
	    # Brent's method failed
	    $error = $poly->error;
	    if ( grep( /^$error$/,
		       Math::Polynom::ERROR_NAN,
		       Math::Polynom::ERROR_MAX_DEPTH,
		       Math::Polynom::ERROR_NOT_A_ROOT )) {
		# Brent's method was unable to approximate the root
		_debug("brent failed with error code: $error");
		return undef;
	    } else {
		# looks like a bug, either in Math::Polynom's implementation of Brent of in the arguments we sent to it
		_crash("brent", $poly, \%ARGS_BRENT, $@);
	    }
	}
    }

    if ($root == 0) {
	# that would mean IRR = infinity, which is kind of not plausible
	_debug("got 0 as the root, meaning infinite IRR. impossible.");
	return undef;
    }

    # TODO: verify IRR against cashflow
    # TODO: is the IRR impossibly large?
    # TODO: try secant with other intervals
    # TODO: calculate the number of real roots of the polynomial, find them all and choose the most relevant? or die if more than 1?

    return -1 + 1/$root;
}

1;

__END__

=head1 NAME

Finance::Math::IRR - Calculate the internal rate of return of a cash flow

=head1 SYNOPSIS

    use Finance::Math::IRR;

    # we provide a cash flow
    my %cashflow = (
	'2001-01-01' => 100,
	'2001-03-15' => 250.45,
	'2001-03-20' => -50,
	'2001-06-23' => -763.12,  # the last transaction should always be <= 0
    );

    # and get the internal rate of return for this cashflow
    # we want a precision of 0.1%
    my $irr = xirr(%cashflow, precision => 0.001);

    # or simply: my $irr = xirr(%cashflow);

    if (!defined $irr) {
	die "ERROR: xirr() failed to calculate the IRR of this cashflow\n";
    }

=head1 DESCRIPTION

The internal rate of return (IRR) is a powerfull tool when
evaluating the behaviour of a cashflow. It is typically used
to assess whether an investment will yield profit. But since
you are reading those lines, I assume you already know what
an IRR is about.

In this module, the internal rate of return is calculated in a similar way
as in the function XIRR present in both Excell and Gnumeric. This
means that cash flows where transactions come at irregular intervals
are well supported, and the rate is a yearly rate.

An IRR is obtained by finding the root of a polynomial where each coefficient is
the amount of one transaction in the cash flow, and the power of the
corresponding coefficient is the number of days between that transaction
and the first transaction divided by 365 (one year). Note that it isn't
a polynomial in the traditional meaning since its powers may have decimals or
be less than 1.

There is no universal way to solve this equation analytically. Instead,
we have to find the polynomial's root with various root finding algorithms.
That's where the fun starts...

The approach of Finance::Math::IRR is to try to approximate one of the polynomial's
roots with the secant method. If it fails, Brent's method is tried. However, Brent's
method requires to know of an interval such that the polynomial is positive on one
end of the interval and negative on the other. Finance::Math::IRR searches for such
an interval by trying systematically a sequence of points. But it may fail to find
such an interval and therefore fail to approximate the cashflow's IRR:


=head1 API

=over 4

=item xirr(%cashflow, precision => $float)

Calculates an approximation of the internal rate of return (IRR) of
the provided cashflow. The returned IRR will be within I<$float>
of the exact IRR. The cashflow is a hash with the following structure:

    my %cashflow = (
	# date => transaction_amount
	'2006-01-01' => 15,
	'2006-01-15' => -5,
	'2006-03-15' => -8,
    );

To get the IRR in percent, multiply xirr's result by 100.

If I<precision> is omitted, it defaults to 0.001, yielding 0.1%
precision on the resulting IRR.

I<xirr> may fail to find the IRR, in which case it returns undef.

I<xirr> will croak if you feed it with junk.

I<xirr> removes all transactions with amount 0 from the cashflow.
If the resulting cashflow is empty, an irr of 0% is returned.
If the resulting cashflow contains only one non 0 transaction,
undef is returned.

=back

=head1 DISCUSSION

Finding the right strategy to solve the IRR equation is tricky.
Finance::Math::IRR uses a slightly different technique than the
corresponding XIRR function in Gnumeric.

Gnumeric uses first Newton's method to approximate the IRR. If
it fails, it evaluates the polynomial on a sequence of points
( '-1 + 10/(i+9)' and 'i' with i from 1 to 1024), hoping to find
2 points where the polynomial
is respectively positive and negative. If it finds 2 such points,
gnumeric's XIRR then uses the bisection method on their interval.

Finance::Math::IRR has a slightly different strategy. It uses the
secant method instead of Newton's, and Brent's method instead of
the bisection. Both methods are believed to be superior to their
Gnumeric counterparts. Finance::Math::IRR performs additional
controls to guaranty the validity of the result, such as controlling
that the root candidate returned by Secant and Brent really are roots.

=head1 DEBUG

To display debug information, set in your code:

    local $Finance::Math::IRR::DEBUG = 1;

=head1 BUGS AND LIMITATIONS

This module has been used in recquiring production
environments and thoroughly tested. It is therefore
believed to be robust.

Yet, the method used in xirr may fail to find the IRR even
on cashflows that do have an IRR. If you happen to find
such an example, please email it to the author at
C<< <erwan@cpan.org> >>.

=head1 REPOSITORY

The source of Finance::Math::IRR is hosted at sourceforge as part of the xirr4perl project. You can access
it at https://sourceforge.net/projects/xirr4perl/.

=head1 SEE ALSO

See Math::Polynom, Math::Function::Roots.

=head1 VERSION

$Id: IRR.pm,v 1.5 2007/07/12 12:35:46 erwan_lemonnier Exp $

=head1 THANKS

Kind thanks to Gautam Satpathy (C<< gautam@satpathy.in >>) who provided me with his port of
Gnumeric's XIRR to Java. Its source can be found at http://www.satpathy.in/jxirr/index.html.

Thanks to the team of Gnumeric for releasing their implementation of XIRR
in open source. For the curious, the code for XIRR is available in
the sources of Gnumeric in the file 'plugins/fn-financial/functions.c' (as
of Gnumeric 1.6.3).

More thanks to Nicholas Caratzas for his efficient help and sharp financial and mathematical insight!

=head1 AUTHOR

Erwan Lemonnier C<< <erwan@cpan.org> >>,
as part of the Pluto developer group at the Swedish Premium Pension Authority.

=head1 LICENSE

This code was developed at the Swedish Premium Pension Authority as part of
the Authority's software development activities. This code is distributed
under the same terms as Perl itself. We encourage you to help us improving
this code by sending feedback and bug reports to the author(s).

This code comes with no warranty. The Swedish Premium Pension Authority and the author(s)
decline any responsibility regarding the possible use of this code or any consequence
of its use.

=cut









