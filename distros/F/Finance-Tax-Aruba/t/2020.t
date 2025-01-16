use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::TestFinanceAW qw(:all);

my @tests = (
    {
        year    => 2020,
        isa     => 'Finance::Tax::Aruba::Income::2020',
        income  => 1000,
        results => {
            wervingskosten  => 360,
            aov_employee    => 564,
            azv_employee    => 180.48,
            zuiver_jaarloon => 10_535.52,
            taxable_wage    => 0,

            pension_employee => 360,
            pension_employer => 360,

            aov_employer => 1184.4,
            azv_employer => 1003.92,

            azv_yearly_income => 11_280,
            aov_yearly_income => 11_280,

            taxfree_amount => 10_535.52,

            tax_fixed   => 0,
            tax_rate    => 14,
        },
    },
    {
        year    => 2020,
        isa     => 'Finance::Tax::Aruba::Income::2020',
        income  => 6000,
        results => {
            wervingskosten    => 1500,
            aov_yearly_income => 68340,
            azv_yearly_income => 68340,

            tax_fixed => 4890.20,
            tax_rate  => 25,
        },
    },
    {
        year    => 2020,
        isa     => 'Finance::Tax::Aruba::Income::2020',
        income  => 9000,
        results => {
            tax_fixed => 12633.70,
            tax_rate  => 42,
        },
    },
    {
        year    => 2020,
        isa     => 'Finance::Tax::Aruba::Income::2020',
        income  => 16000,
        results => {
            tax_fixed => 46884.70,
            tax_rate  => 52,
        },
    },
);

foreach (@tests) {
    subtest sprintf("Running test for year %s with monthly income of %d",
        $_->{year}, $_->{income}) => sub {
        test_yearly_income(%{$_});
    }
}

done_testing;

1;
