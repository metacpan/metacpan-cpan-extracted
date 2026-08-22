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

subtest '1D export to PDL' => sub {
    my $h = Math::Histo->new(bins => 4, min => 0, max => 4, sumw2 => 1);
    $h->fill_pdl(pdl(double, [0.5, 1.5, 1.5, 2.5, 2.5, 2.5, 3.5, 3.5, 3.5, 3.5]));

    # Counts
    my $counts = $h->counts_pdl;
    is $counts->dim(0), 4, 'counts dim is 4';
    is [$counts->list], [1.0, 2.0, 3.0, 4.0], 'counts values match';

    # Edges
    my $edges = $h->edges_pdl;
    is $edges->dim(0), 5, 'edges dim is 5';
    is [$edges->list], [0.0, 1.0, 2.0, 3.0, 4.0], 'edges values match';

    # Centers
    my $centers = $h->centers_pdl;
    is $centers->dim(0), 4, 'centers dim is 4';
    is [$centers->list], [0.5, 1.5, 2.5, 3.5], 'centers values match';

    # Errors (Poisson sqrt(N) for unweighted entries)
    my $errors = $h->errors_pdl;
    is $errors->dim(0), 4, 'errors dim is 4';
    my @err_list = $errors->list;
    is $err_list[0], 1.0, 'sqrt(1) = 1.0';
    is sprintf("%.4f", $err_list[1]), sprintf("%.4f", sqrt(2)), 'sqrt(2)';
    is sprintf("%.4f", $err_list[2]), sprintf("%.4f", sqrt(3)), 'sqrt(3)';
    is $err_list[3], 2.0, 'sqrt(4) = 2.0';

    # to_pdl contexts
    my $scalar_export = $h->to_pdl;
    is [$scalar_export->list], [1.0, 2.0, 3.0, 4.0], 'to_pdl in scalar context returns counts';

    my ($c, $e, $err) = $h->to_pdl;
    is [$c->list], [1.0, 2.0, 3.0, 4.0], 'to_pdl in list context counts';
    is [$e->list], [0.0, 1.0, 2.0, 3.0, 4.0], 'to_pdl in list context edges';
    is $err->dim(0), 4, 'to_pdl in list context errors';

    my $all = $h->to_pdl(all => 1);
    is ref($all), 'HASH', 'to_pdl(all => 1) returns hashref';
    is [$all->{counts}->list], [1.0, 2.0, 3.0, 4.0], 'hashref counts';
    is [$all->{edges}->list], [0.0, 1.0, 2.0, 3.0, 4.0], 'hashref edges';
    is [$all->{centers}->list], [0.5, 1.5, 2.5, 3.5], 'hashref centers';
};

subtest '2D export to PDL' => sub {
    my $h2 = Math::Histo::2D->new(xbins => 3, xmin => 0, xmax => 3, ybins => 2, ymin => 0, ymax => 2, sumw2 => 1);
    $h2->fill_pdl(pdl(double, [0.5, 1.5, 2.5]), pdl(double, [0.5, 0.5, 1.5]));

    my $mat = $h2->matrix_pdl;
    is [$mat->dims], [3, 2], 'matrix dims are (3, 2)';
    is $mat->at(0, 0), 1.0, 'mat(0,0) is 1.0';
    is $mat->at(1, 0), 1.0, 'mat(1,0) is 1.0';
    is $mat->at(2, 0), 0.0, 'mat(2,0) is 0.0';
    is $mat->at(2, 1), 1.0, 'mat(2,1) is 1.0';

    my $xe = $h2->x_edges_pdl;
    is [$xe->list], [0.0, 1.0, 2.0, 3.0], 'x edges match';

    my $ye = $h2->y_edges_pdl;
    is [$ye->list], [0.0, 1.0, 2.0], 'y edges match';

    my $xc = $h2->x_centers_pdl;
    is [$xc->list], [0.5, 1.5, 2.5], 'x centers match';

    my $yc = $h2->y_centers_pdl;
    is [$yc->list], [0.5, 1.5], 'y centers match';

    my $err2d = $h2->errors_pdl;
    is [$err2d->dims], [3, 2], '2D errors dims (3, 2)';
    is $err2d->at(0, 0), 1.0, 'error(0,0) is 1.0';

    # 2D to_pdl
    my $m_scalar = $h2->to_pdl;
    is [$m_scalar->dims], [3, 2], 'to_pdl in scalar context returns matrix';

    my ($m, $x_edges, $y_edges) = $h2->to_pdl;
    is [$m->dims], [3, 2], 'list context matrix';
    is [$x_edges->list], [0.0, 1.0, 2.0, 3.0], 'list context x_edges';
    is [$y_edges->list], [0.0, 1.0, 2.0], 'list context y_edges';

    my $all2d = $h2->to_pdl(all => 1);
    is ref($all2d), 'HASH', 'to_pdl(all => 1) hashref';
    is [$all2d->{matrix}->dims], [3, 2], 'all matrix';
};

subtest 'Convenience functions pdl_to_histo and histo_to_pdl' => sub {
    my $data1d = pdl(double, [1, 2, 3, 4, 5]);
    my $h1 = pdl_to_histo($data1d, bins => 5, min => 0, max => 6);
    isa_ok $h1, ['Math::Histo'];
    is $h1->num_entries, 5, '5 entries in 1D';

    my $exp1 = histo_to_pdl($h1);
    is [$exp1->list], [1.0, 1.0, 1.0, 1.0, 1.0], '1D exported properly';

    my $coords = pdl(double, [[1, 2], [2, 3], [3, 4]]); # (2, 3)
    my $h2 = pdl_to_histo($coords, xbins => 5, xmin => 0, xmax => 5, ybins => 5, ymin => 0, ymax => 5);
    isa_ok $h2, ['Math::Histo::2D'];
    is $h2->num_entries, 3, '3 entries in 2D';

    my $exp2 = histo_to_pdl($h2);
    is [$exp2->dims], [5, 5], '2D exported properly';
};

done_testing;
