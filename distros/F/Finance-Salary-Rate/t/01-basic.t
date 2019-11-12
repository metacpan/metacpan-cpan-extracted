use strict;
use warnings;
use Test::More 0.96;

use_ok("Finance::Salary::Rate");

my $rate = Finance::Salary::Rate->new(
    monthly_income       => 1750,
    vacation_perc        => 8,
    tax_perc             => 30,
    healthcare_perc      => 5.7,
    declarable_days_perc => 60,
    working_days         => 230,
    expenses             => 2000,
);

isa_ok($rate, 'Finance::Salary::Rate');

is($rate->monthly_income, 1750,      "Montly income is alright");
is($rate->income,         1750 * 12 * 1.08, ".. and yearly is ok too");

is($rate->gross_income, $rate->income * 1.30, "Gross income");
is(
    $rate->get_healthcare_fee,
    $rate->gross_income * 0.057,
    ".. plus healthcare"
);

is($rate->workable_hours, 230 * 8 * .6, "Workable hours is correct");

is(
    $rate->required_income,
    $rate->gross_income + $rate->expenses,
    "Total money required"
);

is(
    $rate->hourly_rate,
    $rate->required_income / $rate->workable_hours,
    "Pay up"
);

done_testing;
