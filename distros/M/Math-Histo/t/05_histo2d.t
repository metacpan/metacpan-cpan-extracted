use Test2::V0;
use Math::Histo;
use Math::Histo::2D;

subtest 'Uniform 2D histogram' => sub {
    my $h2 = Math::Histo::2D->new(
        xbins => 10, xmin => 0.0, xmax => 10.0,
        ybins => 5,  ymin => 0.0, ymax => 5.0,
        sumw2 => 1,
    );
    isa_ok $h2, 'Math::Histo::2D';
    is $h2->nx, 10, 'nx is 10';
    is $h2->ny, 5,  'ny is 5';
    is $h2->xmin, 0.0, 'xmin is 0.0';
    is $h2->xmax, 10.0, 'xmax is 10.0';
    is $h2->ymin, 0.0, 'ymin is 0.0';
    is $h2->ymax, 5.0, 'ymax is 5.0';

    # Ingestion
    ok $h2->fill(2.5, 1.5), 'fill (2.5, 1.5)';
    ok $h2->fill(7.5, 3.5, 2.0), 'fill (7.5, 3.5) with weight 2.0';
    is $h2->num_entries, 2, '2 entries';
    is $h2->total_weight, 3.0, 'total weight 3.0';

    # Batch ingestion
    ok $h2->fill_n([1.0, 2.0, 3.0], [1.0, 2.0, 3.0], [1.0, 1.0, 1.0]), 'fill_n';
    is $h2->num_entries, 5, '5 entries';

    # Packed binary ingestion
    my $px_bin = pack('d*', 4.0, 5.0);
    my $py_bin = pack('d*', 2.0, 3.0);
    ok $h2->fill_packed_f64($px_bin, $py_bin), 'fill_packed_f64';
    is $h2->num_entries, 7, '7 entries';


    # 2D Covariance and correlation
    my $cov = $h2->covariance;
    my $corr = $h2->correlation;
    ok defined($cov), 'covariance defined';
    ok defined($corr), 'correlation defined';

    # Projections
    my $px = $h2->project_x;
    isa_ok $px, 'Math::Histo';
    is $px->nbins, 10, 'project_x has 10 bins';
    is $px->total_weight, $h2->total_weight, 'project_x weight matches 2D total';

    my $py = $h2->project_y;
    isa_ok $py, 'Math::Histo';
    is $py->nbins, 5, 'project_y has 5 bins';

    # Profile
    my $prof_x = $h2->profile_x;
    isa_ok $prof_x, 'Math::Histo';
    is $prof_x->nbins, 10, 'profile_x has 10 bins';

    # Serialization
    my $blob = $h2->serialize_binary;
    ok defined($blob) && length($blob) > 0, '2D binary serialization';
    my $restored = Math::Histo::2D->from_binary($blob);
    isa_ok $restored, 'Math::Histo::2D';
    is $restored->nx, 10, 'restored nx';
    is $restored->ny, 5, 'restored ny';
    is $restored->num_entries, 7, 'restored num_entries';
};


subtest 'Variable 2D histogram' => sub {
    my $h2_var = Math::Histo::2D->new(
        xedges => [0.0, 5.0, 10.0],
        yedges => [0.0, 2.0, 4.0, 6.0],
    );
    isa_ok $h2_var, 'Math::Histo::2D';
    is $h2_var->nx, 2, 'nx is 2';
    is $h2_var->ny, 3, 'ny is 3';
};

subtest '2D Slicing, bounds, center, integral, and queries' => sub {
    my $h2 = Math::Histo::2D->new(
        xbins => 4, xmin => 0.0, xmax => 4.0,
        ybins => 4, ymin => 0.0, ymax => 4.0,
        sumw2 => 1,
    );
    $h2->fill(0.5, 0.5, 1.0);
    $h2->fill(1.5, 1.5, 2.0);
    $h2->fill(2.5, 2.5, 3.0);
    $h2->fill(3.5, 3.5, 4.0);

    # Bounds & Center
    my ($xmin, $xmax, $ymin, $ymax) = $h2->bin_bounds(0, 0);
    is $xmin, 0.0, 'bounds xmin';
    is $xmax, 1.0, 'bounds xmax';
    is $ymin, 0.0, 'bounds ymin';
    is $ymax, 1.0, 'bounds ymax';

    my ($cx, $cy) = $h2->bin_center(0, 0);
    is $cx, 0.5, 'center cx';
    is $cy, 0.5, 'center cy';

    # find_bin & find_region
    my ($ix, $iy) = $h2->find_bin(2.5, 2.5);
    is $ix, 2, 'find_bin ix';
    is $iy, 2, 'find_bin iy';
    is $h2->find_region(2.5, 2.5), 0, 'find_region in range';

    # integral & integral_range
    is $h2->integral, 10.0, 'integral total';
    is $h2->integral_range(0, 1, 0, 1), 3.0, 'integral_range [0..1]x[0..1]';

    # Slices
    my $sx = $h2->slice_x(0, 1);
    isa_ok $sx, 'Math::Histo';
    is $sx->nbins, 4, 'slice_x nbins';
    is $sx->total_weight, 3.0, 'slice_x total_weight';

    my $sy = $h2->slice_y(2, 3);
    isa_ok $sy, 'Math::Histo';
    is $sy->nbins, 4, 'slice_y nbins';
    is $sy->total_weight, 7.0, 'slice_y total_weight';

    # std_dev_x, std_dev_y
    ok $h2->std_dev_x > 0, 'std_dev_x positive';
    ok $h2->std_dev_y > 0, 'std_dev_y positive';
};

subtest '2D Arithmetic, rebin, normalize, reset' => sub {
    my $h2a = Math::Histo::2D->new(xbins => 4, xmin => 0.0, xmax => 4.0, ybins => 4, ymin => 0.0, ymax => 4.0);
    my $h2b = Math::Histo::2D->new(xbins => 4, xmin => 0.0, xmax => 4.0, ybins => 4, ymin => 0.0, ymax => 4.0);

    $h2a->fill(1.5, 1.5, 2.0);
    $h2b->fill(1.5, 1.5, 3.0);

    # Operator addition
    my $h2_sum = $h2a + $h2b;
    is $h2_sum->bin_content(1, 1), 5.0, 'overloaded +';

    # Operator subtraction
    my $h2_diff = $h2b - $h2a;
    is $h2_diff->bin_content(1, 1), 1.0, 'overloaded -';

    # Scalar multiplication & division
    my $h2_mul = $h2a * 3.0;
    is $h2_mul->bin_content(1, 1), 6.0, 'overloaded *';

    my $h2_div = $h2a / 2.0;
    is $h2_div->bin_content(1, 1), 1.0, 'overloaded /';

    # Rebin
    my $h2_reb = $h2a->rebin(2, 2);
    is $h2_reb->nx, 2, 'rebin nx';
    is $h2_reb->ny, 2, 'rebin ny';
    is $h2_reb->total_weight, 2.0, 'rebin total_weight';

    # Normalize
    $h2a->normalize(1.0);
    is $h2a->integral, 1.0, 'normalize';

    # Reset
    $h2a->reset;
    is $h2a->num_entries, 0, 'reset num_entries';
    is $h2a->total_weight, 0.0, 'reset total_weight';
};

subtest '2D Plotting' => sub {
    my $h2 = Math::Histo::2D->new(xbins => 5, xmin => 0.0, xmax => 5.0, ybins => 5, ymin => 0.0, ymax => 5.0);
    $h2->fill(1.0, 1.0);
    $h2->fill(2.0, 2.0, 2.0);
    $h2->fill(3.0, 3.0, 3.0);

    my $out = $h2->plot(palette => 'turbo', color => 0, show => 0);
    ok length($out) > 0, '2D plot output produced';
};

done_testing;
