#! /usr/bin/env  perl

=head1 NAME

privateloan.pl - Calculate repayments on a private loan under UK law

=head1 SYNOPSIS

 privateloan.pl --conf some-configuration-file

=head1 DESCRIPTION

This script calculates the repayments and tax schedule for a private
loan under UK law.  The output of the script is a repayment table with
a tax summary at the end of each finacial year.

At the time of writing, interest payments on a private loan (not from
a bank or building society) must be have tax deducted from them by the
borrower. The borrower is responsible for paying this tax to HMRC.

If the loan is for business purposes the borrower can then reclaim the
whole amount of interest paid (net amount paid to the lender plus the
tax paid) as a business expense.

The premium that is calculated by this module is not exact. It may over-
or under-pay slightly and an adjustment will be necessary in the
last few months. A configuration file enables you to set the tax rate,
interest rate, period of loan and the amount. The tax rate and the amount
lent may be subject to change during the period of the loan. Monthly 
interest is calculated as 1/12 of the  nominal annual rate; this is 
not mathematically acccurate, but it is the usual convention in the
financial world.


=head1 CONFIGURATION

The script uses Config::General. The format of a configuration files is the same
as for Apache.

<taxrate> and <loan> blocks may be repeated any number of times. They do
not have to be in date order, the program will sort them. In each block only
the date is mandatory; if any other field is omitted it will remain at
its previously set value.

Changes in amounts or rates that are made part way through a month are treated
as happening at the start of the month. We make no attempt to calculate daily
interest rates.

The loan period is used only for estimating the initial premium. The
actual period of the loan will only approximate to this period. A premium that
is defined in the configuration file overrides the calculated figure.

If there are advances on the loan during its period it is advisable to
set the premium manually, otherwise there is a risk that the loan will
never be paid off. 

yearend is used to determine when to print summaries.

For a bank loan, where you pay gross interest, set the tax rate to 0.

All dates must be in the yyyy-mm-dd format.

=head1 SAMPLE CONNFIGURATION FILE

 <taxrate>
    date	2012-04-05
    rate	20	# Correct rate at the time of writing
 </taxrate>

 # Initial loan amount
 <loan>
    date	2012-05-20
    amount	20000
    rate	3
    premium	200
 </loan>

 # Part way through change the tax and interest rates, and advance some more cash
 <loan>
    date	2015-07-20
    amount	500
    rate	10
    premium	250
 </loan>

 #Approximate loan period in years
 period		10

 # Start/end of the financial year, usually 5 April.
 yearend		2012-04-05

=cut

use strict;
use DateTime;
use DateTime::Duration;
use DateTime::Format::ISO8601;
use Getopt::Long;
use Config::General qw(ParseConfig);
use Finance::Loan::Private qw(premium sorter);

# Some useful intervals
my $Month	= DateTime::Duration->new(months=>1);
my $Year	= DateTime::Duration->new(years=>1);

# Working variales with default values.
my $Today	= DateTime->today();
my $TaxRate	= 20;
my $Period	= 10;
my $Principal	= 10000;
my $InterestRate	= 3.0;
my $ConfigFile	= "/dev/null";

my $rc = GetOptions(
	"conf:s"	=> \$ConfigFile,
);
if (!$rc) {
   print "Usage: privateloan.pl [ --conf /dev/null ]\n";
   die "Bad command line options";
}
my $Config	= Config::General->new(-ConfigFile=>$ConfigFile,
					-LowerCaseNames=> 1,
				    );
my %Config	= $Config->getall;
my $TaxRates	= (ref($Config{taxrate}) eq 'ARRAY') ? $Config{taxrate} : 
						[ $Config{taxrate} ];
my $Advances	= (ref($Config{loan}) eq 'ARRAY') ? $Config{loan} : 
						[ $Config{loan} ];
$Period	= $Config{period} if ($Config{period});
my $YearEnd	= DateTime::Format::ISO8601->parse_datetime($Config{yearend});

# Get things into date order
my @TaxRates	= sorter($TaxRates);
my @Advances	= sorter($Advances);
my ($Premium, $totalTax, $totalInterest);

# Now do the real work
main();
exit 0;

sub main {
    my ($nextTaxDate, $nextLoanDate);

    # Get the loan details
    $Principal	= $Advances[0]->{amount};
    $Today	= DateTime::Format::ISO8601->parse_datetime($Advances[0]->{date});
    $InterestRate	= $Advances[0]->{rate};
    $Premium	= int premium($Principal, $InterestRate, $Period);
    $Premium	= $Advances[0]->{premium} if exists $Advances[0]->{premium};
    shift @Advances;
    if (@Advances) {
	$nextLoanDate	= DateTime::Format::ISO8601->parse_datetime($Advances[0]->{date});
    }

    # Get the tax details
    $TaxRate	= $TaxRates[0]->{rate};
    shift @TaxRates;
    if (@TaxRates) {
	$nextTaxDate	= DateTime::Format::ISO8601->parse_datetime($TaxRates[0]->{date});
    }
    while ($Today > $YearEnd) {
        $YearEnd	+= $Year;
    }
    
    printf("Loan amount\t\t%d\n", $Principal);
    printf("Gross interest rate\t%.2f%%\n", $InterestRate);
    printf("Tax rate\t\t%.2f%%\n", $TaxRate);
    printf("Period\t\t\t%d years\n", $Period);
    print "\n";
    print "Date\t\tPrincipal\tGross interest due\tTax due\tAmount paid\tPrincipal repaid\n";
    while (1) {
    	printf("%s\t%8.2f\t",  $Today->ymd(), $Principal);
	my $interest	= $Principal*$InterestRate/1200.0;
	my $tax		= $interest*$TaxRate/100.0;
	$totalTax	+= $tax;
	$totalInterest	+= $interest;
	my $repayment	= $Premium -$interest + $tax;
	if ($repayment >= $Principal) {
	    $Premium	= $Principal + $interest - $tax;
	    $repayment	= $Principal;
	    printf("%8.2f\t\t%6.2f\t%6.2f\t\t%8.2f\n", $interest, $tax, $Premium, $repayment);
	    last;
	}
	printf("%8.2f\t\t%6.2f\t%6.2f\t\t%8.2f\n", $interest, $tax, $Premium, $repayment);
	$Principal	-= $repayment;
	$Today		+= $Month;
	yearEndSummary() if ($Today >= $YearEnd);
	updateLoan() if ($nextLoanDate && $Today >= $nextLoanDate);
	updateTax() if ($nextTaxDate && $Today >= $nextTaxDate);
    }

    yearEndSummary();
}

sub yearEndSummary {
    printf ("Gross interest paid in the past year\t%8.2f\n", $totalInterest);
    printf("Total tax deducted in the past year\t%8.2f\n", $totalTax);
    print "\n";
    $totalTax	= 0;
    $totalInterest	=0;
    $YearEnd	+= $Year;
    print "Date\t\tPrincipal\tGross interest due\tTax due\tAmount paid\tPrincipal repaid\n";
}

sub updateLoan {
    $InterestRate	= $Advances[0]->{rate} if exists($Advances[0]->{rate});
    $Principal	+= $Advances[0]->{amount} if exists($Advances[0]->{amount});
    $Premium	= $Advances[0]->{premium} if exists($Advances[0]->{premium});
    shift @Advances;
}

sub updateTax {
    $TaxRate	= $TaxRates[0]->{rate} if exists($TaxRates[0]->{rate});
    shift @TaxRates;
}

=head1 AUTHOR

Raphael Mankin <rapmankin@cpan.org>
