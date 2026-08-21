use Test2::V0;
use Math::Histo;

subtest 'Statistical moments and metrics' => sub {
    my $h = Math::Histo->new(bins => 100, min => 0.0, max => 100.0, exact_moments => 1);
    
    # Fill standard sequence 1..100
    my @vals = map { 0.5 + $_ } (0..99); # centers of bins [0,1], [1,2], ..., [99,100]
    $h->fill_n(\@vals);

    is $h->num_entries, 100, '100 entries';
    is $h->mean, within(50.0, 0.001), 'mean is 50.0';
    is $h->median, within(50.0, 0.5), 'median is ~50.0';
    is $h->quantile(0.25), within(25.0, 0.5), 'p25 is ~25.0';
    is $h->quantile(0.75), within(75.0, 0.5), 'p75 is ~75.0';
    is $h->iqr, within(50.0, 1.0), 'IQR is ~50.0';

    # Stats structure
    my $st = $h->stats;
    is ref($st), 'HASH', 'stats returns hashref';
    is $st->{entries}, 100, 'entries in stats';
    is $st->{mean}, within(50.0, 0.001), 'mean in stats';
    is $st->{total_weight}, within(100.0, 0.001), 'total_weight in stats';
};

subtest 'Mode, FWHM, and Peak Estimation' => sub {
    my $h = Math::Histo->new(bins => 100, min => -10.0, max => 10.0);
    # Fill Gaussian centered at 0.0 with sigma 2.0
    for (my $x = -8.0; $x <= 8.0; $x += 0.1) {
        my $weight = exp(-($x * $x) / 8.0);
        $h->fill($x, $weight);
    }

    my $mode_x = $h->mode;
    is $mode_x, within(0.0, 0.2), 'mode near 0.0';

    my $fwhm = $h->fwhm;
    # FWHM for Gaussian with sigma=2 is 2 * sqrt(2 * ln 2) * 2 ≈ 4.71
    is $fwhm, within(4.71, 0.5), 'fwhm near 4.71';

    my $rms = $h->rms;
    is $rms, within(2.0, 0.5), 'rms near 2.0';
};

subtest 'Robust trimmed and winsorized mean' => sub {
    my $h = Math::Histo->new(bins => 100, min => 0.0, max => 100.0);
    $h->fill_n([map { 50.5 } (1..90)]); # 90 samples at bin center 50.5
    $h->fill_n([map { 0.5 } (1..5)]);   # 5 outliers at bin center 0.5
    $h->fill_n([map { 99.5 } (1..5)]);  # 5 outliers at bin center 99.5

    my $tm = $h->trimmed_mean(0.05);
    is $tm, within(50.5, 0.5), 'trimmed mean rejects outliers';

    my $wm = $h->winsorized_mean(0.05);
    is $wm, within(48.05, 0.5), 'winsorized mean robust';
};


done_testing;
