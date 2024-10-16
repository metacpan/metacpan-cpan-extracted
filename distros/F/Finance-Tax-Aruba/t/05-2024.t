use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::TestFinanceAW qw(:all);

my @tests = (
    {
        year    => 2024,
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

            net_yearly_income => 10535.52,
            tax_fixed         => 0,
            tax_rate          => 12,
        },
    },
    {
        year    => 2024,
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
        year    => 2024,
        isa     => 'Finance::Tax::Aruba::Income::2023',
        income  => 9000,
        results => {
            tax_fixed => 9577.5,
            tax_rate  => 42,
        },
    },
    {
        year    => 2024,
        isa     => 'Finance::Tax::Aruba::Income::2023',
        income  => 15000,
        results => {
            tax_fixed => 39659.20,
            tax_rate  => 52,
        },
    },
    {
        year   => 2024,
        isa    => 'Finance::Tax::Aruba::Income::2023',
        income => 7000,
        label  => "One child policy",

        children              => 1,    # 700
        dependents            => 0,    # 1200
        children_study_abroad => 0,    # 3800

        results => {
            wervingskosten    => 1500,
            aov_yearly_income => 79980,
            azv_yearly_income => 79980,

            child_deductions  => 700,
            net_yearly_income => 74001.32,

            tax_fixed => 3493,
            tax_rate  => 21,

        },
    },
    {
        year   => 2024,
        isa    => 'Finance::Tax::Aruba::Income::2023',
        income => 7000,
        label  => "Test with all kinds of kids",

        children              => 2,    # 700
        dependents            => 2,    # 1200
        children_study_abroad => 2,    # 3800

        results => {
            wervingskosten    => 1500,
            aov_yearly_income => 79980,
            azv_yearly_income => 79980,

            child_deductions  => 5700 * 2,
            net_yearly_income => 63301.32,

            tax_fixed => 0,
            tax_rate  => 12,

        },
    },
    {
        year              => 2023,
        isa               => 'Finance::Tax::Aruba::Income::2023',
        income            => 6250,
        label             => "Test premiums paid by employer and no pension",
        fringe            => 40,
        no_pension        => 1,
        premiums_employer => 1,

        results => {
            wervingskosten    => 1500,
            yearly_income     => 73980,
            net_yearly_income => 73980,

            azv_percentage_employer => 10.5,
            aov_percentage_employer => 15.5,

            tax_fixed => 3493,
            tax_rate  => 21,

        },
    },
    {
        year                  => 2024,
        isa                   => 'Finance::Tax::Aruba::Income::2023',
        income                => 6250,
        label                 => "Pension 1% by employee",
        pension_employee_perc => 1,

        results => {
            wervingskosten        => 1500,
            pension_employer_perc => 5,

            tax_fixed => 3493,
            tax_rate  => 21,

        },
    },
    {
        year   => 2024,
        isa    => 'Finance::Tax::Aruba::Income::2023',
        income => 5000,
        label  => "Company cost test",

        pension_employee_perc => 0,
        premiums_employer     => 1,

        results => {
            tax_fixed        => 0,
            tax_rate         => 12,
            company_costs    => 78810,
            government_costs => 18630,
            social_costs     => 22230,
        },
    },
);

foreach (@tests) {
    my $name = delete $_->{label};
    $name //= sprintf("Running test for year %s with monthly income of %d",
        $_->{year}, $_->{income});
    subtest $name => sub {
        test_yearly_income(%{$_});
    }
}


done_testing;
