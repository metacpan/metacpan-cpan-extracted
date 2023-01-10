use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::TestFinanceAW qw(:all);

my @tests = (
    {
        year    => 2023,
        isa     => 'Finance::Tax::Aruba::Income::2023',
        income  => 1000,
        results => {
            taxfree_max => 30_000,

            wervingskosten    => 360,
            aov_yearly_income => 11280,
            azv_yearly_income => 11280,

            # 3% both
            pension_employee => 360,
            pension_employer => 360,

            #net_yearly_income => 81423.84,
            tax_fixed => 0,
            tax_rate  => 12,
        },
    },
    {
        year    => 2023,
        isa     => 'Finance::Tax::Aruba::Income::2023',
        income  => 7000,
        results => {
            wervingskosten    => 1500,
            aov_yearly_income => 79980,
            azv_yearly_income => 79980,

            tax_fixed => 3493,
            tax_rate  => 21,
        },
    },
    {
        year    => 2023,
        isa     => 'Finance::Tax::Aruba::Income::2023',
        income  => 9000,
        results => {
            tax_fixed => 9577.5,
            tax_rate  => 42,
        },
    },
    {
        year    => 2023,
        isa     => 'Finance::Tax::Aruba::Income::2023',
        income  => 15000,
        results => {
            tax_fixed => 39659.20,
            tax_rate  => 52,
        },
    },
);

my %mapping = (
    wervingskosten    => "Wervingskosten",
    aov_yearly_income => "AOV yearly income",
    azv_yearly_income => "AZV yearly income",
    taxfree_max       => "Tax free amount",
    pension_employee  => "Employee pension amount",
    pension_employer  => "Employer pension amount",
    net_yearly_income => "Yearly income (net)",
    tax_fixed         => "Income tax (fixed)",
    tax_variable      => "Income tax (variable)",
    tax_rate          => "Tax rate",
);

foreach (@tests) {
    subtest sprintf("Running test for year %s with monthly income of %d",
        $_->{year}, $_->{income}) => sub {
        test_yearly_income(%{$_});
    }
}



done_testing;
