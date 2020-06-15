use strict;
use warnings;
use Test::More 0.96;
use Test::Deep;

use Finance::Tax::Aruba::Income;

my $tax_brackets = [
    { min => 0, max => 34930, fixed => 0, rate => 14 },
    {
        min   => 34930,
        max   => 65904,
        fixed => 4890.2,
        rate  => 25
    },
    {
        min   => 65904,
        max   => 147454,
        fixed => 12633.7,
        rate  => 42
    },
    {
        min   => 147454,
        max   => 'inf' * 1,
        fixed => 46884.7,
        rate  => 52
    },
];

my %tests = (
    1000 => {
        wervingskosten  => 360,
        aov_employee    => 582,
        azv_employee    => 186.24,
        zuiver_jaarloon => 10_871.76,
        taxable_wage    => 0,

        aov_employer => 1222.2,
        azv_employer => 1035.96,

        azv_yearly_income => 11640,
        aov_yearly_income => 11640,

        taxfree_amount => 10871.76,

        tax_bracket => 0,
        tax_rate    => 14,
    },
    6000 => {
        wervingskosten => 1500,

        aov_employee      => 3525,
        aov_employer      => 7402.5,
        aov_yearly_income => 70500,

        azv_employee      => 1128,
        azv_employer      => 6274.5,
        azv_yearly_income => 70500,

        zuiver_jaarloon => 65847,
        tax_bracket     => 1,
        tax_rate        => 25,
    },
    9000 => {
        wervingskosten => 1500,

        aov_employee      => 4250,
        aov_employer      => 8925,
        aov_yearly_income => 85000,

        azv_employee      => 1360,
        azv_employer      => 7565,
        azv_yearly_income => 85000,

        zuiver_jaarloon => 100890,
        taxable_wage   => 72029,
        tax_bracket     => 2,
        tax_rate        => 42,
    },
    16000 => {
        wervingskosten => 1500,

        aov_employee      => 4250,
        aov_employer      => 8925,
        aov_yearly_income => 85000,

        azv_employee      => 1360,
        azv_employer      => 7565,
        azv_yearly_income => 85000,

        zuiver_jaarloon => 184890,
        tax_bracket     => 3,
        tax_rate        => 52,
    }
);

my @amounts = sort { $a <=> $b } keys %tests;

foreach (@amounts) {

    my $t = $tests{$_};

    $t->{yearly_income_gross} //= $_ * 12;
    $t->{yearly_income} //= $t->{yearly_income_gross} - $t->{wervingskosten};

    $t->{taxfree_amount} //= 28_861;

    foreach (qw(azv aov)) {
        $t->{$_ . '_premium'} = $t->{$_ . '_employee'} + $t->{$_ .'_employer'};
    }

    $t->{taxable_wage} //= $t->{zuiver_jaarloon} - $t->{taxfree_amount};

    my $tax_bracket = $tax_brackets->[delete $t->{tax_bracket}];

    if (defined $tax_bracket) {
        $t->{tax_minimum} = $tax_bracket->{min};
        $t->{tax_maximum} = $tax_bracket->{max} ;
        $t->{tax_fixed} = $tax_bracket->{fixed};

        $t->{taxable_amount} //= $t->{taxable_wage} - $tax_bracket->{min};
        $t->{tax_variable}   //= $t->{taxable_amount} * ($t->{tax_rate} / 100);
        $t->{income_tax}     //= $t->{tax_variable} + $tax_bracket->{fixed};
    }


    if (defined $tax_bracket) {
        $t->{tax_bracket} = $tax_bracket;
        $t->{taxable_amount} //= $t->{taxable_wage} - $tax_bracket->{min};
        $t->{tax_variable}   //= $t->{taxable_amount} * ($t->{tax_rate} / 100);
        $t->{income_tax}     //= $t->{tax_variable} + $tax_bracket->{fixed};
    }

    subtest "Test income level $_" => sub {
        test_income_taxes($_, $tests{$_});
    };

}

sub test_income_taxes {
    my ($income, $expected) = @_;


    my $calc = Finance::Tax::Aruba::Income->tax_year(2020, income => $income);
    isa_ok($calc, 'Finance::Tax::Aruba::Income::2020');

    my $failure = 0;

    foreach (sort keys %$expected) {
        my $default_msg = "$_ yields correct results: ";
        my $ok;
        if ($calc->can($_)) {
            my $result = $expected->{$_};
            if (ref $result) {
                $ok = cmp_deeply($calc->$_, $result, $default_msg);
                if (!$ok) {
                    diag explain $result;
                }
            }
            else {
                $ok = is($calc->$_, $result, $default_msg . $result);
            }
        }
        else {
            $ok = fail("$_ is an unsupported action");
        }

        $failure++ if !$ok;
    }

    if ($failure) {
        diag explain $expected;
        BAIL_OUT("Test failure, bailing out");
    }
    return;
}

done_testing;
