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
use Math::Histo::2D;
use Math::Histo::PDL qw(:all);

subtest '2D ingestion from (x, y) piddles' => sub {
    my $x = pdl(double, [1.5, 2.5, 3.5]);
    my $y = pdl(double, [10.5, 20.5, 30.5]);

    my $h2 = hist2d($x, $y, xbins => 5, xmin => 0, xmax => 5, ybins => 4, ymin => 0, ymax => 40, exact_moments => 1);
    is $h2->num_entries, 3, '3 entries';
    is $h2->mean_x, 2.5, 'mean_x is 2.5';
    is $h2->mean_y, 20.5, 'mean_y is 20.5';

    is $h2->bin_content(1, 1), 1.0, 'bin (1,1) has 1';
    is $h2->bin_content(2, 2), 1.0, 'bin (2,2) has 1';
    is $h2->bin_content(3, 3), 1.0, 'bin (3,3) has 1';
};

subtest '2D ingestion from (2, N) coordinate matrix' => sub {
    # dims (2, 3) in PDL
    my $coords = pdl(double, [
        [1.0, 10.0],
        [2.0, 20.0],
        [3.0, 30.0]
    ]);
    is $coords->dim(0), 2, 'coord matrix dim 0 is 2';
    is $coords->dim(1), 3, 'coord matrix dim 1 is 3';

    my $h2 = hist2d($coords, xbins => 5, xmin => 0, xmax => 5, ybins => 4, ymin => 0, ymax => 40, exact_moments => 1);
    is $h2->num_entries, 3, '3 entries';
    is $h2->mean_x, 2.0, 'mean_x is 2.0';
    is $h2->mean_y, 20.0, 'mean_y is 20.0';
};

subtest '2D ingestion from (N, 2) coordinate matrix' => sub {
    # dims (3, 2) in PDL
    my $coords = pdl(double, [
        [1.0, 2.0, 3.0],
        [10.0, 20.0, 30.0]
    ]);
    is $coords->dim(0), 3, 'coord matrix dim 0 is 3';
    is $coords->dim(1), 2, 'coord matrix dim 1 is 2';

    my $h2 = hist2d($coords, xbins => 5, xmin => 0, xmax => 5, ybins => 4, ymin => 0, ymax => 40, exact_moments => 1);
    is $h2->num_entries, 3, '3 entries';
    is $h2->mean_x, 2.0, 'mean_x is 2.0';
    is $h2->mean_y, 20.0, 'mean_y is 20.0';
};

subtest '2D weighted ingestion' => sub {
    my $x = pdl(double, [1.5, 2.5]);
    my $y = pdl(double, [2.5, 3.5]);
    my $w = pdl(double, [5.0, 15.0]);

    my $h2 = Math::Histo::2D->new(xbins => 5, xmin => 0, xmax => 5, ybins => 5, ymin => 0, ymax => 5, sumw2 => 1);
    $h2->fill_pdl($x, $y, $w);

    is $h2->num_entries, 2, '2 entries';
    is $h2->total_weight, 20.0, 'total weight 20.0';
    is $h2->bin_content(1, 2), 5.0, 'bin (1,2) content is 5.0';
    is $h2->bin_content(2, 3), 15.0, 'bin (2,3) content is 15.0';
};

subtest '2D weighted ingestion with coordinate matrix' => sub {
    my $coords = pdl(double, [
        [1.0, 10.0],
        [2.0, 20.0],
    ]);
    my $w = pdl(double, [100.0, 200.0]);

    my $h2 = Math::Histo::2D->new(xbins => 5, xmin => 0, xmax => 5, ybins => 4, ymin => 0, ymax => 40, sumw2 => 1);
    $h2->fill_pdl($coords, $w);

    is $h2->num_entries, 2, '2 entries';
    is $h2->total_weight, 300.0, 'total weight 300.0';
};

subtest '2D type coercion and slicing' => sub {
    my $x_raw = sequence(long, 20);
    my $y_raw = sequence(long, 20) * 2;
    my $x_slice = $x_raw->slice('0:8:2'); # 0, 2, 4, 6, 8 (long)
    my $y_slice = $y_raw->slice('0:8:2'); # 0, 4, 8, 12, 16 (long)

    my $h2 = hist2d($x_slice, $y_slice, xbins => 10, xmin => 0, xmax => 10, ybins => 20, ymin => 0, ymax => 20, exact_moments => 1);
    is $h2->num_entries, 5, '5 sliced coerced entries';
    is $h2->mean_x, 4.0, 'mean_x is 4.0';
    is $h2->mean_y, 8.0, 'mean_y is 8.0';
};

subtest '2D auto range detection' => sub {
    my $x = pdl(double, [5.0, 15.0]);
    my $y = pdl(double, [50.0, 150.0]);
    my $h2 = hist2d($x, $y, bins => 10);
    is $h2->xmin, 5.0, 'xmin auto detected';
    cmp_ok $h2->xmax, '>=', 15.0, 'xmax auto detected';
    is $h2->ymin, 50.0, 'ymin auto detected';
    cmp_ok $h2->ymax, '>=', 150.0, 'ymax auto detected';
    is $h2->num_entries, 2, '2 entries';
};

done_testing;
