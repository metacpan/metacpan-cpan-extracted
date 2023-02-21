use Test::More;
use strict;
use warnings;

use Finance::Loan::Repayment;


sub _get_loan_calc {
    my %opts = @_;
    my $loan = 1000;
    my $rate = 5;
    my $calc = Finance::Loan::Repayment->new(
        loan => $loan,
        rate => $rate,
        %opts,
    );
    isa_ok($calc, "Finance::Loan::Repayment");
    return $calc;
}

{
    my $calc = _get_loan_calc();

    my $interest = $calc->interest_per_month;
    is($interest, (1000 * (5 / 100 / 12)), "interest_per_month: $interest");

    my $principal = $calc->principal_per_month();
    is($principal, 0, "payoff_per_month: interest only: $principal");
}

{
    my $calc = _get_loan_calc(principal_payment => 1);
    my $principal = $calc->principal_per_month();
    is($principal, 1, "payoff_per_month: principal_payment: $principal");
}

{
    my $calc = _get_loan_calc(principal_payment => 1001);
    my $principal = $calc->principal_per_month();
    is($principal, 1000, "payoff_per_month: principal_payment more than loan equals loan");
}

{
    my $total = 5;
    my $calc = _get_loan_calc(total_payment => $total);

    my $interest = $calc->interest_per_month;
    my $payment = $total - $interest;

    my $principal = $calc->principal_per_month();

    is($principal, $payment,
        "payoff_per_month: total_payment makes principal $principal");
}

{
    my $val     = 1;
    my $payment = 240;
    my $calc = _get_loan_calc(interest_off => $val);

    my $interest = $calc->interest_per_month;

    my $principal = $calc->principal_per_month();

    is($principal, $payment,
        "payoff_per_month: reduce interest by 1 makes principal $principal");
}

{
    my $calc = _get_loan_calc(duration => 12);
    my $interest = $calc->interest_per_month;
    my $principal = $calc->principal_per_month();

    is(sprintf("%.02f", $interest), 4.17, "Interest is 4.17");
    is(sprintf("%.02f", $principal), 81.44, "Principal payment is 81.44");
}



done_testing;
