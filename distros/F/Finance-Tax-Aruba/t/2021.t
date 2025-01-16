use strict;
use warnings;
use Test::More;
use Test::Lib;
use Test::TestFinanceAW qw(:all);

my @tests = (
  {
    year    => 2021,
    isa     => 'Finance::Tax::Aruba::Income::2021',
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

      tax_fixed => 0,
      tax_rate  => 12,
    },
  },
  {
    year    => 2021,
    isa     => 'Finance::Tax::Aruba::Income::2021',
    income  => 6000,
    results => {
      wervingskosten    => 1500,
      aov_yearly_income => 68340,
      azv_yearly_income => 68340,

      tax_fixed => 4191.60,
      tax_rate  => 23,
    },
  },
  {
    year    => 2021,
    isa     => 'Finance::Tax::Aruba::Income::2021',
    income  => 9000,
    results => {
      tax_fixed => 11315.62,
      tax_rate  => 42,
    },
  },
  {
    year    => 2021,
    isa     => 'Finance::Tax::Aruba::Income::2021',
    income  => 16000,
    results => {
      tax_fixed => 45566.62,
      tax_rate  => 52,
    },
  },
  {
    year                  => 2021,
    isa                   => 'Finance::Tax::Aruba::Income::2021',
    label                 => "Test fringe and tax benefits",
    income                => 7812.50,
    fringe                => 40,
    tax_free              => 600 * 12,
    pension_employee_perc => 0,
    results               => {

      pension_employee_perc => 0,
      pension_employer_perc => 6,

      pension_employee => 0,
      pension_employer => 5625,

      tax_fixed     => 4191.60,
      tax_rate      => 23,
      net_income    => 85783,
      tax_free_wage => 48222,
    },
  },
  {
    year    => 2021,
    isa     => 'Finance::Tax::Aruba::Income::2021',
    label   => "Test random salary",
    income  => 7812.50,
    results => {
      tax_fixed    => 4191.60,
      tax_rate     => 23,
      taxable_wage => 54966.5,
    },
  },
  {
    year    => 2021,
    isa     => 'Finance::Tax::Aruba::Income::2021',
    label   => "Test bonus on salary",
    income  => 7812.50,
    bonus   => 7812.50,
    results => {
      tax_fixed    => 4191.60,
      tax_rate     => 23,
      taxable_wage => 62779,
    },
  },
  {
    # This implemenation maybe incorrect.
    year    => 2021,
    isa     => 'Finance::Tax::Aruba::Income::2021',
    label   => "Test bonus on low salary",
    income  => 1000,
    bonus   => 89562.5,
    results => {
      yearly_income_gross => 101562.50,
      aov_yearly_income   => 85000,
      azv_yearly_income   => 85000,

      pension_employee => 360,
      pension_employer => 360,

      tax_fixed    => 4191.60,
      tax_rate     => 23,

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

1;
