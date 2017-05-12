use Finance::Loan;

print "Principal amount: ";
my $p = <STDIN>;
print "Please enter the interest rate as a percentage.\n";
print "Enter 3% as 0.03\n";
print "Enter 2.5% as 0.025\n";
print "Interest Percentage: ";
my $i = <STDIN>;
print "Number of months: ";
my $m = <STDIN>;

my $loan = new Finance::Loan(principle=>$p,interest_rate=>$i,number_of_months=>$m);
my $monthlyPayment = $loan->getMonthlyPayment(); 
print "Monthly payment: " . $loan->getMonthlyPayment() . "\n";
print "Total amount of interest paid: " . $loan->getInterestPaid . "\n";
my $simpleDailyInterest = $loan->getDailyInterest();
print "Simple Daily Interest (For the first day of the loan: $simpleDailyInterest\n";

1;
exit(0);
__END__

=head1 NAME

example.pl 

=head1 SYNOPSIS

A simple sample program to demonstrate the module.
Enter the principal amount, interest rate, and number of months.
It will display monthly payment amount, total interest paid over the course of the loand
and the amount of simply daily interest.

=cut
