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

done_testing;
