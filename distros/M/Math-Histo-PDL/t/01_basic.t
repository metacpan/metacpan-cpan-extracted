use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/../../Math-Histo/blib/lib", "$Bin/../../Math-Histo/blib/arch", "$Bin/../../Alien-libhisto/blib/lib", "$Bin/../../Alien-libhisto/blib/arch";
use Test2::V0 '!float';

BEGIN {
    eval { require PDL; PDL->import; 1 }
        or plan skip_all => 'PDL is required for this test';
}

use Math::Histo;
use Math::Histo::PDL qw(:all);

subtest '1D basic ingestion' => sub {
    my $data = pdl(double, [1.5, 2.5, 3.5, 4.5, 5.5]);
    my $h = hist1d($data, bins => 10, min => 0, max => 10);

    is $h->num_entries, 5, '5 entries in 1D histo';
    is $h->bin_content(1), 1.0, 'bin 1 has 1.0';
    is $h->bin_content(2), 1.0, 'bin 2 has 1.0';
    is $h->bin_content(3), 1.0, 'bin 3 has 1.0';
    is $h->bin_content(4), 1.0, 'bin 4 has 1.0';
    is $h->bin_content(5), 1.0, 'bin 5 has 1.0';
    is $h->mean, 3.5, 'mean is 3.5';
};

subtest '1D type coercion (long, float, byte, short)' => sub {
    my $types = [
        pdl(long, [1, 2, 3, 4]),
        pdl(float, [1.0, 2.0, 3.0, 4.0]),
        pdl(byte, [1, 2, 3, 4]),
        pdl(short, [1, 2, 3, 4]),
    ];

    for my $p (@$types) {
        my $h = Math::Histo->new(bins => 10, min => 0, max => 10, exact_moments => 1);
        $h->fill_pdl($p);
        is $h->num_entries, 4, "coerced type " . $p->type . " filled 4 entries";
        is $h->mean, 2.5, "coerced type " . $p->type . " mean is 2.5";
    }
};

subtest '1D weighted ingestion' => sub {
    my $data = pdl(double, [1.5, 2.5, 3.5]);
    my $weights = pdl(double, [10.0, 20.0, 30.0]);

    my $h = Math::Histo->new(bins => 10, min => 0, max => 10, sumw2 => 1);
    $h->fill_pdl($data, $weights);

    is $h->num_entries, 3, '3 entries';
    is $h->total_weight, 60.0, 'total weight 60.0';
    is $h->bin_content(1), 10.0, 'bin 1 has weight 10.0';
    is $h->bin_content(2), 20.0, 'bin 2 has weight 20.0';
    is $h->bin_content(3), 30.0, 'bin 3 has weight 30.0';

    # Weighted coercion
    my $w_int = pdl(long, [2, 3, 5]);
    my $h_w = hist1d($data, weights => $w_int, bins => 10, min => 0, max => 10);
    is $h_w->total_weight, 10.0, 'weighted integer total weight 10.0';
};

subtest '1D non-contiguous slices and strides' => sub {
    my $p = sequence(double, 20); # 0..19
    my $slice = $p->slice('1:9:2'); # 1, 3, 5, 7, 9

    my $h = hist1d($slice, bins => 20, min => 0, max => 20, exact_moments => 1);
    is $h->num_entries, 5, '5 sliced entries';
    is $h->mean, 5.0, 'mean is 5.0';
};

subtest '1D multidimensional flattening' => sub {
    my $mat = sequence(double, 3, 4); # 12 elements 0..11
    my $h = hist1d($mat, bins => 12, min => 0, max => 12, exact_moments => 1);
    is $h->num_entries, 12, '12 entries from 2D piddle';
    is $h->mean, 5.5, 'mean is 5.5';
};

subtest '1D auto min/max range detection' => sub {
    my $data = pdl(double, [10.0, 20.0, 30.0, 40.0, 50.0]);
    my $h = hist1d($data, bins => 5);
    is $h->min, 10.0, 'min auto-detected';
    cmp_ok $h->max, '>=', 50.0, 'max auto-detected and covers upper bound';
    is $h->num_entries, 5, '5 entries all captured in bins';
};

subtest '1D auto bin estimation rule' => sub {
    my $data = sequence(double, 100);
    my $h = hist1d($data, rule => 'fd');
    cmp_ok $h->nbins, '>=', 2, 'auto bins >= 2';
    is $h->num_entries, 100, '100 entries filled';
};

done_testing;
