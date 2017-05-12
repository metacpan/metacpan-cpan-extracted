package Finance::Loan;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.06';


# Technique for new class borrowed from Effective Perl Programming by Hall / Schwartz pp 211
sub new{
  my $pkg = shift;
  # bless package variables
  bless{
  principle => 0.00,
  interest_rate => 0.00,
  number_of_months => 0,
  @_}, $pkg;
}

# Forecasting With Your Microcomputer pp 198
sub getMonthlyPayment{
  my $self = shift;
  my $flag = shift || 1;
  # P = Principle
  # r = interest Rate Per Month (eg. 14%/12)
  # S = Monthly Payemnt
  # n = Number of Months

  my $P = $self->{principle};
  my $r = $self->{interest_rate}/12;
  my $n = $self->{number_of_months};
  if ($flag==1)
  {
    my $almost_val = ($P*$r*((1+$r)**$n))/(((1+$r)**$n)-1.0);
    my $retval = sprintf("%0.2f",$almost_val);
    return($retval);
  }
  else
  {
    return($P*$r*((1+$r)**$n))/(((1+$r)**$n)-1.0);
  }
}

# Forecasting With Your Microcomputer pp198
sub getInterestPaid{
  my $self = shift;  
  # (n*s)-P
  my $n = $self->{number_of_months};
  my $S = getMonthlyPayment($self,2);
  my $P = $self->{principle};
  my $almost_val = ($n*$S)-$P;
  my $retval = sprintf("%0.2f",$almost_val);
  return($retval);
}

sub getDailyInterest{
  my $self = shift;
  my $P = $self->{principle};
  my $i = $self->{interest_rate};
  my $val = $P * $i / 365;
  my $retval = sprintf("%0.2f",$val);
  return($retval);
}

1;
__END__

=head1 NAME

Finance::Loan - Calculates monthly payment, interest paid, and simple interest on a loan.

=head1 SYNOPSIS

  use Finance::Loan;
  my $loan = new Finance::Loan(principle=>1000,interest_rate=>.07,number_of_months=>36); # 7% interest rate for 36 months.
  my $monthlyPayment = $loan->getMonthlyPayment(); # 30.88
  my $interestPaid=$loan->getInterestPaid(); # Total interest 111.58
  my $simpleDailyInterest = $loan->getDailyInterest(); # 0.19


=head1 DESCRIPTION

=head2 Note: Try to use another module than this one for Finances.

I thought there was no other modules when I wrote this module that dealt with calcualting loans.  Turns out, there are many.  Please consider using one of the other modules if you need to calculate something more complicated.

=head2 new Finance::Loan(principle=>1000,interest_rate=>.07,number_of_months=>36)

Creates a new loan object.  Ensure that interest_rate is a decimal.  So, a 7 percent interest rate is .07 while a 14 percent
interest rate is .14

=head2 $loan->getMonthlyPayment()

Returns the monthly payment on the loan.

=head2 $loan->getInterestPaid()

Returns the total amount of interest that needs to be paid on the loan.

=head2 $loan->getDailyInterest();

Returns the daily interest on the loan.

=head1 BUGS

* The function get payment after payment N was broken, so I removed the function.

=head1 DISCLAIMER

Calculations are presumed to be reliable, but not guaranteed.  

=head1 AUTHOR

Zachary Zebrowski zakz@cpan.org 
NOTE: Please include the word Finance in the subject of the message to beat the spam filter.

=head1 SEE ALSO

Nickell, Daniel - Forecasting With Your Microcomputer, Tab Books (C) 1983.

=cut


