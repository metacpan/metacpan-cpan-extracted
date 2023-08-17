package    # no indexing
    Test::TestFinanceAW;
use warnings;
use strict;
use Finance::Tax::Aruba::Income;
use Test::More 0.96;
use Math::BigInt;

# ABSTRACT: Testing module for Finance::Tax::Aruba

use Exporter qw(import);
our @EXPORT_OK = qw(test_yearly_income);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

my %mapping = (
  aov_yearly_income   => "AOV yearly income",
  azv_yearly_income   => "AZV yearly income",
  child_deductions    => "Child deductions",
  company_costs       => "Company costs",
  government_costs    => "Government premiums",
  net_income          => "Net income",
  net_yearly_income   => "Yearly income (net)",
  pension_employee    => "Employee pension amount",
  pension_employer    => "Employer pension amount",
  social_costs        => "Social costs",
  tax_fixed           => "Income tax (fixed)",
  tax_free_wage       => "Income after taxes",
  tax_rate            => "Tax rate",
  tax_variable        => "Income tax (variable)",
  taxable_wage        => "Taxeable income",
  taxfree_max         => "Tax free amount",
  wervingskosten      => "Wervingskosten",
  yearly_income_gross => "Yearly gross income",
);

sub test_yearly_income {
    my %args    = @_;
    my $year    = delete $args{year};
    my $isa     = delete $args{isa};
    my $monthly = $args{income};
    my $results = delete $args{results};

    my $calc = Finance::Tax::Aruba::Income->tax_year($year, %args);
    isa_ok($calc, $isa);

    # Aruban income taxes are determined as such:
    # There are wervingskosten, in the years 2020-2023, these are 3% with a max
    # of 1500.
    # The pension of the employee is deducted
    # The bonus is added
    #

    my $yearly_income_gross = $monthly * 12;

    $args{$_} //= 0 foreach qw(fringe bonus);

    my $pension_income = $yearly_income_gross;

    $yearly_income_gross += $args{fringe} * 12;
    $yearly_income_gross += $args{bonus};


    if (!check_optional_results($calc, $results, 'yearly_income_gross')) {
        is($calc->yearly_income_gross,
            $yearly_income_gross, "Yearly gross income: $yearly_income_gross");
    }


    if (!check_optional_results($calc, $results, 'wervingskosten')) {
        my $amount = get_perc_for($yearly_income_gross / 100 * $calc->pension_employer_perc);
        $amount = $calc->wervingskosten_max if $amount > $calc->wervingskosten_max;
        is($calc->wervingskosten, $amount, "Wervingskosten: $amount");
    }

    if (!check_optional_results($calc, $results, 'pension_employer')) {
        my $amount
          = get_perc_for($pension_income / 100 * $calc->pension_employer_perc);
        is($calc->pension_employer, $amount,
          "Pension employer: $amount");
    }

    if (!check_optional_results($calc, $results, 'pension_employee')) {
        my $amount = get_perc_for($pension_income / 100 * $calc->pension_employee_perc);
        is($calc->pension_employee, $amount, "Pension employee: $amount");
    }

    if (!check_optional_results($calc, $results, 'yearly_income')) {
        my $yearly_income
            = $yearly_income_gross
            - $calc->wervingskosten
            - $calc->pension_employee;

        is($calc->yearly_income, $yearly_income,
            "Yearly income: $yearly_income");
    }

    # Now you have the gross income and this becomes "zuiver jaarloon".
    # Zuiver jaarloon is the income minus the AOV (pension) and the AZV (health
    # care) premiums. These premiums are all paid by the employer/employee,
    # they have a maxium limited at 85000 for the years 2020-2023. For the
    # jaarloon, only the employee parts are removed. So let's compute the
    # AOV/AZV premiums here
    check_optional_results($calc, $results, 'aov_yearly_income');

    if (!check_optional_results($calc, $results, 'aov_employer')) {
        my $aov_employer
            = $calc->aov_yearly_income / 100 * $calc->aov_percentage_employer;
        is($calc->aov_employer, $aov_employer, "AOV employer: $aov_employer");
    }

    if (!check_optional_results($calc, $results, 'aov_employee')) {
        my $aov_employee
            = $calc->aov_yearly_income / 100 * $calc->aov_percentage_employee;
        is($calc->aov_employee, $aov_employee, "AOV employee: $aov_employee");
    }

    check_optional_results($calc, $results, 'azv_yearly_income');

    if (!check_optional_results($calc, $results, 'azv_employer')) {
        my $azv_employer
            = $calc->azv_yearly_income / 100 * $calc->azv_percentage_employer;
        is($calc->azv_employer, $azv_employer, "AZV employer: $azv_employer");
    }

    if (!check_optional_results($calc, $results, 'azv_employee')) {
        my $azv_employee
            = $calc->azv_yearly_income / 100 * $calc->azv_percentage_employee;
        is($calc->azv_employee, $azv_employee, "AZV employee: $azv_employee");
    }

    # This is the actual zuiver jaarloon, aka net yearly income
    if (!check_optional_results($calc, $results, 'net_yearly_income')) {
        my $amount = $calc->yearly_income - $calc->aov_employee - $calc->azv_employee;

        is($calc->net_yearly_income, $amount, "Net yearly income: $amount");
    }

    check_optional_results($calc, $results, 'taxfree_max');

    # If the taxable income is the net income minus the tax free amount
    if (!check_optional_results($calc, $results, 'taxable_wage')) {
        my $amount = $calc->net_yearly_income - $calc->taxfree_amount;
        $amount = 0 if $amount < 0;
        is($calc->taxable_wage, $amount, "Taxable income: $amount");
    }

    # taxable amount is the taxeable wage minus the minimum of the tax bracket
    # Over difference the tax rate is applied
    if (!check_optional_results($calc, $results, 'taxable_amount')) {
        my $amount = get_perc_for($calc->taxable_wage - $calc->tax_minimum);
        is($calc->taxable_amount, $amount, "Taxable amount: $amount");
    }

    if (!check_optional_results($calc, $results, 'tax_variable')) {
        my $amount = get_perc_for($calc->taxable_amount / 100 * $calc->tax_rate);

        is(Math::BigInt->new($calc->tax_variable),
          Math::BigInt->new($amount), "Income tax (variable): $amount");
    }

    {
        check_required_results($calc, $results, 'tax_fixed');
        my $amount = int($calc->tax_variable + $calc->tax_fixed);
        is($calc->income_tax, $amount, "Income tax (total): $amount");
    }

    check_required_results($calc, $results, 'tax_rate');

    if (!check_optional_results($calc, $results, 'employee_income_deductions'))
    {
        my $amount
            = $calc->aov_employee + $calc->azv_employee + $calc->income_tax;
        is($calc->employee_income_deductions,
            $amount, "Employee income deducations: $amount");
    }


    if (!check_optional_results($calc, $results, 'tax_free_wage')) {
        my $amount
            = $calc->yearly_income
            - $calc->employee_income_deductions
            - $calc->taxfree_amount
            - $calc->fringe;
        is($calc->tax_free_wage, $amount, "Tax free wages: $amount");
    }

    foreach (sort keys %$results) {
        check_required_results($calc, $results, $_);
    }
}

sub get_perc_for {
    return sprintf("%.02f", shift) +0
}

sub check_required_results {
    my $calc    = shift;
    my $results = shift;
    my $key     = shift;

    return check_optional_results($calc, $results, $key)
        if exists $results->{$key};

    return fail("Unable to check $key");
}

sub check_optional_results {
    my $calc    = shift;
    my $results = shift;
    my $key     = shift;

    if (exists $results->{$key}) {
        my $val = delete $results->{$key};
        my $res = $calc->$key;

        if (my $m = $mapping{$key}) {
            $key = $m;
        }
        return is($res, $val, "$key: $val");
    }

    return 0;
}

1;

__END__

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS
