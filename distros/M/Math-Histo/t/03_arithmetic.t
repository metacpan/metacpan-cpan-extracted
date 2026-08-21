use Test2::V0;
use Math::Histo;

subtest 'Arithmetic operators and overloading' => sub {
    my $h1 = Math::Histo->new(bins => 10, min => 0.0, max => 100.0);
    my $h2 = Math::Histo->new(bins => 10, min => 0.0, max => 100.0);

    $h1->fill_n([15.0, 25.0, 35.0]);
    $h2->fill_n([15.0, 25.0, 45.0]);

    # Addition
    my $h_add = $h1 + $h2;
    isa_ok $h_add, 'Math::Histo';
    is $h_add->total_weight, 6.0, '3 + 3 = 6';
    is $h_add->bin_content(1), 2.0, 'bin 1 has 2.0';

    # Subtraction
    my $h_sub = $h_add - $h1;
    is $h_sub->total_weight, 3.0, '6 - 3 = 3';

    # Scalar multiplication and division
    my $h_mul = $h1 * 2.0;
    is $h_mul->total_weight, 6.0, 'scaled 3 * 2 = 6';

    my $h_div = $h_mul / 2.0;
    is $h_div->total_weight, 3.0, 'divided 6 / 2 = 3';

    # Stringification
    my $str = "$h1";
    like $str, qr/Math::Histo\[bins=10/, "stringification matches: $str";
};

subtest 'Distance and comparison metrics' => sub {
    my $h1 = Math::Histo->new(bins => 20, min => 0.0, max => 100.0);
    my $h2 = Math::Histo->new(bins => 20, min => 0.0, max => 100.0);

    $h1->fill_n([10, 20, 30, 40, 50]);
    $h2->fill_n([10, 20, 30, 40, 50]);

    # Identical histograms
    my $ks = $h1->kolmogorov_smirnov($h2);
    is $ks, 0.0, 'KS distance is 0 for identical histograms';

    my $w1 = $h1->wasserstein_distance($h2);
    is $w1, 0.0, 'Wasserstein distance is 0 for identical histograms';

    my $bhat = $h1->bhattacharyya_distance($h2);
    is $bhat, 0.0, 'Bhattacharyya distance is 0 for identical histograms';

    # Chi-square test
    my ($chi2, $ndf) = $h1->chi2_test($h2);
    is $chi2, 0.0, 'chi2 is 0 for identical histograms';
    ok $ndf > 0, 'ndf > 0';

};

done_testing;
