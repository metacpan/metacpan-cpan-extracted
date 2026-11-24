use strict;
use warnings;
use Test::More;
use Finance::Tax::Aruba::Income;

sub calc {
    return Finance::Tax::Aruba::Income->tax_year(2026, income => shift, @_);
}

isa_ok(calc(1000), 'Finance::Tax::Aruba::Income::2026');
isa_ok(Finance::Tax::Aruba::Income->tax_year(2025, income => 1000),
    'Finance::Tax::Aruba::Income::2025');

my @tests = (
    [ 2007.04, 0 ],
    [ 2007.05, 175 ],
    [ 2257.99, 175 ],
    [ 2258,    170 ],
    [ 2350,    160 ],
    [ 2450,    150 ],
    [ 2500,    150 ],
    [ 2500.01, 0 ],
    [ 7000,    0 ],
);

foreach (@tests) {
    my ($income, $monthly) = @$_;
    my $c = calc($income);
    is($c->reparatietoeslag_monthly, $monthly, "monthly credit at $income");
    is($c->reparatietoeslag, $monthly * 12, "yearly credit at $income");
}

my $c = calc(2300);
is($c->income_tax, 0, 'no wage tax at this income');
is($c->reparatietoeslag_tax, 0, 'nothing offset against tax');
is($c->reparatietoeslag_aov_employer, $c->reparatietoeslag, 'employer AOV next');
is($c->reparatietoeslag_azv_employer, 0, 'no AZV needed');

my $nocred = Finance::Tax::Aruba::Income::2026->new(
    income => 2300, reparatietoeslag_table => []);
is($c->net_income - $nocred->net_income, $c->reparatietoeslag,
    'net income up by the full credit');
is($c->aov_employee, $nocred->aov_employee, 'employee AOV unchanged');
is($c->azv_employee, $nocred->azv_employee, 'employee AZV unchanged');
is($nocred->government_costs - $c->government_costs, $c->reparatietoeslag,
    'government receives the credit less');
is($c->company_costs, $nocred->company_costs, 'company costs unchanged');

my $y25 = sub { Finance::Tax::Aruba::Income->tax_year(2025, income => shift) };
is($y25->(1986.19)->reparatietoeslag_monthly, 0,   '2025: below range');
is($y25->(1986.20)->reparatietoeslag_monthly, 125, '2025: lowest tier');
is($y25->(2250)->reparatietoeslag_monthly,    110, '2025: 2250 tier');
is($y25->(2500)->reparatietoeslag_monthly,    100, '2025: top tier');
is($y25->(2500.01)->reparatietoeslag_monthly, 0,   '2025: above range');

my $hi = calc(7000);
is($hi->reparatietoeslag, 0, 'no credit above range');
is($hi->net_income, Finance::Tax::Aruba::Income::2026->new(
    income => 7000, reparatietoeslag_table => [])->net_income, 'same net');

is($c->reparatie_kosten, $c->reparatietoeslag, 'reparatie_kosten is the total');
is(calc(7000)->reparatie_kosten, 0, 'zero outside the range');

done_testing;
