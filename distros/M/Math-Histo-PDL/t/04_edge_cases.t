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

subtest 'Empty piddles' => sub {
    my $h = Math::Histo->new(bins => 10, min => 0, max => 10);
    my $empty = pdl([]);
    $h->fill_pdl($empty);
    is $h->num_entries, 0, 'empty 1D piddle does nothing';

    my $h_builder = hist1d($empty, bins => 10, min => 0, max => 10);
    is $h_builder->num_entries, 0, 'hist1d with empty piddle has 0 entries';

    my $h2 = Math::Histo::2D->new(xbins => 5, xmin => 0, xmax => 5, ybins => 5, ymin => 0, ymax => 5);
    $h2->fill_pdl($empty, $empty);
    is $h2->num_entries, 0, 'empty 2D piddles do nothing';
};

subtest 'Single element piddle' => sub {
    my $h = Math::Histo->new(bins => 10, min => 0, max => 10, exact_moments => 1);
    $h->fill_pdl(pdl(double, [5.5]));
    is $h->num_entries, 1, '1 entry filled';
    is $h->bin_content(5), 1.0, 'bin 5 filled';
    is $h->mean, 5.5, 'mean is 5.5';
};

subtest 'Mismatched lengths exception handling' => sub {
    my $h = Math::Histo->new(bins => 10, min => 0, max => 10);
    my $x = pdl(double, [1, 2, 3]);
    my $w_bad = pdl(double, [1, 2]);

    like dies { $h->fill_pdl($x, $w_bad) },
        qr/weights length .* must match data length/,
        'mismatched weights throws croak exception';

    my $h2 = Math::Histo::2D->new(xbins => 5, xmin => 0, xmax => 5, ybins => 5, ymin => 0, ymax => 5);
    my $y_bad = pdl(double, [1, 2, 3, 4]);

    like dies { $h2->fill_pdl($x, $y_bad) },
        qr/X length .* and Y length .* must match/,
        'mismatched 2D X and Y throws croak exception';

    like dies { $h2->fill_pdl($x, $x, $w_bad) },
        qr/weights length .* must match data length/,
        'mismatched 2D weights throws croak exception';
};

subtest 'Invalid 2D coordinate matrix dimensions' => sub {
    my $h2 = Math::Histo::2D->new(xbins => 5, xmin => 0, xmax => 5, ybins => 5, ymin => 0, ymax => 5);
    my $bad_matrix = sequence(double, 4, 5); # 4x5, neither axis is 2

    like dies { $h2->fill_pdl($bad_matrix) },
        qr/coordinate matrix must have dimension 2/,
        'bad matrix shape throws error in fill2d_pdl';

    like dies { hist2d($bad_matrix) },
        qr/coordinate matrix must have 2 columns or 2 rows/,
        'bad matrix shape throws error in hist2d';
};

subtest 'Transposed and non-contiguous piddles' => sub {
    my $mat = pdl(double, [
        [1.0, 2.0, 3.0],
        [10.0, 20.0, 30.0],
    ]); # dims (3, 2)
    my $transposed = $mat->xchg(0, 1); # dims (2, 3)

    my $h2 = hist2d($transposed, xbins => 5, xmin => 0, xmax => 5, ybins => 4, ymin => 0, ymax => 40, exact_moments => 1);
    is $h2->num_entries, 3, 'transposed matrix successfully ingested';
    is $h2->mean_x, 2.0, 'mean_x is 2.0';
    is $h2->mean_y, 20.0, 'mean_y is 20.0';
};

subtest 'Variable binning with PDL edges' => sub {
    my $edges = pdl(double, [0.0, 1.0, 5.0, 10.0, 100.0]);
    my $data = pdl(double, [0.5, 2.0, 3.0, 8.0, 50.0]);

    my $h = hist1d($data, edges => $edges);
    is $h->nbins, 4, 'variable 4 bins';
    is $h->num_entries, 5, '5 entries';
    is $h->bin_content(0), 1.0, 'bin 0 ([0, 1))';
    is $h->bin_content(1), 2.0, 'bin 1 ([1, 5))';
    is $h->bin_content(2), 1.0, 'bin 2 ([5, 10))';
    is $h->bin_content(3), 1.0, 'bin 3 ([10, 100))';

    my $xedges = pdl(double, [0.0, 2.0, 10.0]);
    my $yedges = pdl(double, [0.0, 5.0, 20.0, 100.0]);
    my $h2 = hist2d(pdl(double, [1.0, 5.0]), pdl(double, [2.0, 50.0]), xedges => $xedges, yedges => $yedges);
    is $h2->nx, 2, 'nx is 2';
    is $h2->ny, 3, 'ny is 3';
    is $h2->num_entries, 2, '2 entries in 2D variable histo';
};

done_testing;
