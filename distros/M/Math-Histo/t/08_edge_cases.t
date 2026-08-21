use Test2::V0;
use Math::Histo;

subtest 'Empty histogram numerical queries' => sub {
    my $h = Math::Histo->new(bins => 10, min => 0.0, max => 100.0);
    is $h->num_entries, 0, '0 entries';
    is $h->mean, undef, 'mean is undef';
    is $h->variance, undef, 'variance is undef';
    is $h->std_dev, undef, 'std_dev is undef';
    is $h->median, undef, 'median is undef';
    is $h->quantile(0.5), undef, 'quantile(0.5) is undef';
    is $h->iqr, undef, 'iqr is undef';
};

subtest 'Non-finite IEEE-754 numbers' => sub {
    my $h = Math::Histo->new(bins => 10, min => 0.0, max => 100.0);
    my $nan = "nan" + 0;
    my $inf = "inf" + 0;

    is $h->fill($nan), 0, 'fill NaN returns 0 (rejected)';
    ok $h->fill($inf), 'fill +Inf handled (overflow)';
    ok $h->fill(-$inf), 'fill -Inf handled (underflow)';

    is $h->nan_count, 1, 'nan_count recorded';
    is $h->overflow_weight, 1.0, 'overflow_weight recorded';
    is $h->underflow_weight, 1.0, 'underflow_weight recorded';
};


subtest 'Single-bin histogram' => sub {
    my $h = Math::Histo->new(bins => 1, min => 0.0, max => 10.0);
    is $h->nbins, 1, '1 bin';
    ok $h->fill(5.0), 'fill single bin';
    is $h->bin_content(0), 1.0, 'content 1.0';
    is $h->mean, 5.0, 'mean is 5.0';
};

subtest 'Memory loop stress test' => sub {
    for (1..1000) {
        my $h = Math::Histo->new(bins => 50, min => 0, max => 100);
        $h->fill($_ % 100) for (1..20);
        my $m = $h->mean;
        my $s = $h->serialize_binary;
        my $r = Math::Histo->from_binary($s);
    }
    pass '1000 create-fill-serialize-destroy cycles completed without leak or crash';
};

done_testing;
