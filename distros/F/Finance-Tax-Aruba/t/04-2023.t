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

            net_yearly_income => 10535.52,
            tax_fixed         => 0,
            tax_rate          => 12,
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
    {
        year   => 2023,
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
        year   => 2023,
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

            child_deductions  => 5700 *2,
            net_yearly_income => 63301.32,

            tax_fixed => 0,
            tax_rate  => 12,

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
