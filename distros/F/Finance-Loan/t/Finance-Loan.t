# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Finance-Loan.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { use_ok('Finance::Loan') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $loan = new Finance::Loan(principle=>69437.92,interest_rate=>0.0275,number_of_months=>120); # 2.75% interest rate for 120 months.
my $monthlyPayment = $loan->getMonthlyPayment(); #
my $interestPaid=$loan->getInterestPaid(); # Total interest
my $simpleDailyInterest = $loan->getDailyInterest();

ok($monthlyPayment == 662.51);
ok($interestPaid == 10063.80);
ok($simpleDailyInterest == 5.23);
