use strict;
use warnings;
use Test::More;
use Finance::Tax::Aruba::BBO;

subtest 'tax_year dispatches to the right year class' => sub {
    for my $year (2020 .. 2025) {
        my $calc = Finance::Tax::Aruba::BBO->tax_year($year);
        isa_ok($calc, "Finance::Tax::Aruba::BBO::$year");
    }

    # Same catch-all convention as Finance::Tax::Aruba::Income::2025.
    isa_ok(Finance::Tax::Aruba::BBO->tax_year(2026), 'Finance::Tax::Aruba::BBO::2025');
};

subtest 'tax_year dies for an unsupported year' => sub {
    eval { Finance::Tax::Aruba::BBO->tax_year(1999) };
    like($@, qr/Unable to find module for year 1999/, 'a year with no matching class dies clearly');
};

subtest 'domestic sale -- tax is a percentage OF the billed amount, not added on top' => sub {
    my $calc = Finance::Tax::Aruba::BBO->tax_year(2025);
    is($calc->domestic_tax(100), 7, 'billing 100 owes 7 in BBO (7%)');
    is($calc->domestic_net(100), 93, 'and 93 is kept -- not 100, the way exclusive-priced VAT would leave it');
};

subtest 'import -- taxed at the border, same rate' => sub {
    my $calc = Finance::Tax::Aruba::BBO->tax_year(2025);
    is($calc->import_tax(1000), 70, 'importing 1000 worth of goods owes 70 in BBO at the border');
};

subtest 'the 7% is BAZV 3% plus BBO 2.5% plus BAVP 1.5%' => sub {
    for my $year (2020 .. 2022) {
        my $calc = Finance::Tax::Aruba::BBO->tax_year($year);
        is($calc->bbo_rate, 0.015, "$year: BBO is 1.5%");
        is($calc->bavp_rate, 0.015, "$year: BAVP is 1.5%");
        is($calc->bazv_rate, 0.03, "$year: BAZV is 3%");
        is($calc->rate, 0.06, "$year: total rate is 6%");
    }
    for my $year (2023 .. 2025) {
        my $calc = Finance::Tax::Aruba::BBO->tax_year($year);
        is($calc->bbo_rate, 0.025, "$year: BBO is 2.5%");
        is($calc->bavp_rate, 0.015, "$year: BAVP is 1.5%");
        is($calc->bazv_rate, 0.03, "$year: BAZV is 3%");
        is($calc->rate, 0.07, "$year: total rate is 7%");
    }
    my $calc = Finance::Tax::Aruba::BBO->tax_year(2025);
    is($calc->domestic_tax_bazv(100), 3, 'BAZV is 3 of 100');
    is($calc->domestic_tax_bbo(1000), 25, 'BBO is 25 of 1000');
    is($calc->domestic_tax_bavp(1000), 15, 'BAVP is 15 of 1000');
    is($calc->domestic_tax_bazv(333.33) + $calc->domestic_tax_bbo(333.33)
        + $calc->domestic_tax_bavp(333.33),
        $calc->domestic_tax(333.33), 'the parts add up to the total after rounding');
};

subtest 'export -- zero-rated regardless of amount' => sub {
    my $calc = Finance::Tax::Aruba::BBO->tax_year(2025);
    is($calc->export_tax(5000), 0, 'billing a foreign client is zero-rated');
    is($calc->export_tax(0), 0, 'zero-rated even for a zero amount');
};

my @held = ({ amount => 70, held => 1 });
my @mixed = ({ amount => 70, held => 1 }, { amount => 35, held => 0 });

subtest 'net_payable -- held customs invoices offset domestic BBO' => sub {
    my $calc = Finance::Tax::Aruba::BBO->tax_year(2025);
    ok($calc->bbo_at_border, 'sanity check: this tax year has the border-credit mechanism');

    is($calc->net_payable(domestic => 2000, customs => \@held), 70,
        'domestic tax 140 minus the 70 held customs invoice');
    is($calc->net_payable(domestic => 2000), 140, 'no customs invoices, full liability');
    is($calc->net_payable(customs => \@held), -70,
        'a credit is negative, not clamped to 0');
    is($calc->net_payable(), 0, 'no args at all is a no-op');
};

subtest 'customs invoices not held cannot be offset' => sub {
    my $calc = Finance::Tax::Aruba::BBO->tax_year(2025);
    is($calc->net_payable(domestic => 2000, customs => \@mixed), 70,
        'only the held 70 offsets, the unforwarded 35 does not');
    is($calc->customs_offset(\@mixed), 70, 'offset is the held total');
    is($calc->customs_not_forwarded(\@mixed), 35, 'not forwarded is the unheld total');
    is($calc->net_payable(domestic => 2000,
            customs => [{ amount => 35, held => 0 }]), 140,
        'an unheld invoice alone offsets nothing');
};

subtest 'net_payable does NOT offset for a tax year without the border-credit mechanism' => sub {
    my $calc = Finance::Tax::Aruba::BBO->tax_year(2020);
    ok(!$calc->bbo_at_border, 'sanity check: this tax year has no border-credit mechanism');

    is($calc->net_payable(domestic => 2000, customs => \@held), 120,
        'held invoices are ignored, the full domestic liability (6%) is owed');
};

subtest 'the border credit was introduced in 2024' => sub {
    ok(!Finance::Tax::Aruba::BBO->tax_year($_)->bbo_at_border, "$_: no border credit") for 2020 .. 2023;
    ok(Finance::Tax::Aruba::BBO->tax_year($_)->bbo_at_border, "$_: border credit") for 2024, 2025;
};

subtest 'a non-default rate is honored everywhere' => sub {
    my $calc10 = Finance::Tax::Aruba::BBO->tax_year(2025, rate => 0.10);
    is($calc10->domestic_tax(100), 10, 'domestic_tax uses the overridden rate');
    is($calc10->import_tax(100), 10, 'import_tax uses the overridden rate');
    is($calc10->net_payable(domestic => 2000, customs => \@held), 130,
        'net_payable (200 - 70) uses the overridden rate for the domestic part');
};

done_testing;
