package Finance::Amortization;

use strict;
use warnings;

our $VERSION = '0.5';

=head1 NAME

Finance::Amortization - Simple Amortization Schedules

=head1 SYNOPSIS

use Finance::Amortization

# make a new schedule

$amortization = new Finance::Amortization(principal => 100000, rate = 0.06/12,
	periods = 360);

# get the balance after a the twelveth period

$balance = $amortization->balance(12)

# get the interest paid during the twelfth period

$interest = $amortization->interest(12);

=head1 DESCRIPTION

Finance::Amortization is a simple object oriented interface to an
amortization table.  Pass in the principal to be amortized, the number
of payments to be made, and the interest rate per payment.  It will
calculate the rest on demand, and provides a few methods to ask
for the state of the table after a given number of periods.

Finance::Amortization is written in pure perl and does not depend
on any other modules.  It exports no functions; all access is via
methods called on an amortization object.  (Except for new(), of course.)

=cut

=head2 new()

$am = Finance::Amortization->new(principal => 0, rate => 0, periods => 0,
	compounding => 12, precision => 2);

Creates a new amortization object.  Calling interface is hash style.
The fields principal, rate, and periods are available, all defaulting
to zero.

Compounding is a parameter which sets how many periods the rate is compounded
over.  Thus, if each amortization period is one month, setting compounding
to 12 (the default), will make the rate an annual rate.  That is, the
interest rate per period is the rate specified, divided by the compounding.

So, to get an amortization for 30 years on 200000, with a 6% annual rate,
you would call new(principal => 200000, periods => 12*30, rate => 0.06),
the compounding will default to 12, and so the rate will work out right
for monthly payments.

precision is used to specify the number of decimal places to round to
when returning answers.  It defaults to 2, which is appropriate for
US currency and many others.

=cut

sub new {
	my $pkg = shift;
	# bless package variables
	my %conf = (
		principal => 0.00,
		rate => 0.00,
		compounding => 12,
		precision => 2, # how many decimals to round
		@_
	);
	if (!defined $conf{'periods'}) {
		$conf{'periods'} = $conf{'length'} * $conf{'compounding'};
	}
	if (defined($conf{'compounding'})) {
		$conf{'rate'} /= $conf{'compounding'};
	}

	bless {
		%conf
	}, $pkg;
}

=head2 rate()

$rate_per_period = $am->rate()

returns the interest rate per period.  Ignores any arguments.

=cut

sub rate {
	my $am = shift;
	return $am->{'rate'};
}	

=head2 principal()

$initial_value = $am->principal()

returns the initial principal being amortized.  Ignores any arguments.

=cut

sub principal {
	my $am = shift;
	return sprintf('%.*f', $am->{'precision'}, $am->{'principal'});
}	

=head2 periods()

$number_of_periods = $am->periods()

returns the number of periods in which the principal is being amortized.
Ignores any arguments.

=cut

sub periods {
	my $am = shift;
	return $am->{'periods'};
}	

#P = r*L*(1+r)^n/{(1+r)^n - 1}

=head2 payment()

$pmt = $am->payment()

returns the payment per period.  This method will cache the value the
first time it is called.

=cut

sub payment {
	my $am = shift;

	if ($am->{'payment'}) {
		return $am->{'payment'}
	}

	my $r = $am->rate;
	my $r1 = $r + 1;
	my $n = $am->periods();
	my $p = $am->principal;

	if ($r == 0) {
		return $am->{'payment'} = $p / $n;
	}

	$am->{'payment'} = sprintf('%.2f', $r * $p * $r1**$n / ($r1**$n-1));
}

=head2 balance(n)

$balance = $am->balance(12);

Returns the balance of the amortization after the period given in the
argument

=cut

sub balance {
	my $am = shift;
	my $period = shift;
	return $am->principal() if $period == 0;

	return 0 if ($period < 1 or $period > $am->periods);

	my $rate = $am->rate;
	my $rate1 = $rate + 1;
	my $periods = $am->periods();
	my $principal = $am->principal;
	my $pmt = $am->payment();

	return sprintf('%.*f', $am->{'precision'},
		 $principal*$rate1**$period-$pmt*($rate1**$period - 1)/$rate);

}

=head2 interest(n)

$interest = $am->interest(12);

Returns the interest paid in the period given in the argument

=cut

sub interest {
	my $am = shift;
	my $period = shift;

	return 0 if ($period < 1 or $period > $am->periods);

	my $rate = $am->rate;

	return sprintf('%.*f', $am->{'precision'},
		$rate * $am->balance($period - 1));
}

=head1 BUGS

This module uses perl's floating point for financial calculations.  This
may introduce inaccuracies and/or make this module unsuitable for serious
financial applications.

Please report any bugs or feature requests to
C<bug-finance-amortization at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-Amortization>.

=head1 TODO

Use Math::BigRat for the calculations.

Provide amortizers for present value, future value, annuities, etc.

Allow for caching calculated values.

Provide output methods and converters to various table modules.
HTML::Table, Text::Table, and Data::Table come to mind.

Write better test scripts.

Better checking for errors and out of range input.  Return undef
in these cases.

Use a locale dependent value to set an appropriate default for precision
in the new() method.

=head1 LICENSE

None.  This entire module is in the public domain.

=head1 AUTHOR

Nathan Wagner <nw@hydaspes.if.org>

This entire module is written by me and placed into the public domain.

=cut

1;

__END__
