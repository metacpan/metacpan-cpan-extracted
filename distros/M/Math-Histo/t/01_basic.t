use Test2::V0;
use Math::Histo;

subtest 'Uniform 1D histogram lifecycle' => sub {
    my $h = Math::Histo->new(bins => 20, min => 0.0, max => 100.0, sumw2 => 1);
    isa_ok $h, 'Math::Histo';
    is $h->nbins, 20, '20 bins';
    is $h->min, 0.0, 'min is 0.0';
    is $h->max, 100.0, 'max is 100.0';
    is $h->is_uniform, 1, 'is uniform';
    is $h->num_entries, 0, 'empty entries';
    is $h->total_weight, 0.0, 'empty weight';

    # Ingestion
    ok $h->fill(25.0), 'fill 25.0';
    ok $h->fill(75.0, 2.5), 'fill 75.0 with weight 2.5';
    is $h->num_entries, 2, '2 entries';
    is $h->total_weight, 3.5, 'total weight 3.5';

    # Bin checks
    is $h->find_bin(25.0), 5, 'bin 5 for 25.0';
    is $h->bin_content(5), 1.0, 'bin 5 content 1.0';
    is $h->find_bin(75.0), 15, 'bin 15 for 75.0';
    is $h->bin_content(15), 2.5, 'bin 15 content 2.5';

    # Batch fill_n
    ok $h->fill_n([10.0, 20.0, 30.0], [1.0, 2.0, 3.0]), 'fill_n';
    is $h->num_entries, 5, '5 entries';

    # Packed binary fill
    my $packed_x = pack('d*', 5.0, 15.0, 45.0, 55.0);
    my $packed_w = pack('d*', 1.0, 1.0,  1.0,  1.0);
    ok $h->fill_packed_f64($packed_x, $packed_w), 'fill_packed_f64';
    is $h->num_entries, 9, '9 entries';

    # Clone
    my $c = $h->clone;
    isa_ok $c, 'Math::Histo';
    is $c->num_entries, 9, 'clone has 9 entries';
    is $c->total_weight, $h->total_weight, 'clone has matching weight';
};

subtest 'Variable 1D histogram' => sub {
    my $h_var = Math::Histo->new(edges => [0.0, 10.0, 25.0, 50.0, 100.0]);
    isa_ok $h_var, 'Math::Histo';
    is $h_var->nbins, 4, '4 bins';
    is $h_var->is_uniform, 0, 'not uniform';
    is $h_var->min, 0.0, 'min 0.0';
    is $h_var->max, 100.0, 'max 100.0';

    ok $h_var->fill(5.0), 'fill bin 0';
    ok $h_var->fill(15.0), 'fill bin 1';
    ok $h_var->fill(30.0), 'fill bin 2';
    ok $h_var->fill(80.0), 'fill bin 3';
    is $h_var->num_entries, 4, '4 entries';

    my $edges = $h_var->bin_edges;
    is $edges, [0.0, 10.0, 25.0, 50.0, 100.0], 'bin_edges match';
};

subtest 'Scale, normalize and rebin' => sub {
    my $h = Math::Histo->new(bins => 10, min => 0.0, max => 100.0);
    $h->fill_n([10, 20, 30, 40, 50, 60, 70, 80, 90]);
    is $h->total_weight, 9.0, 'weight 9';

    ok $h->scale(2.0), 'scale by 2';
    is $h->total_weight, 18.0, 'weight 18';

    ok $h->normalize(1.0), 'normalize to 1.0';
    is $h->integral, 1.0, 'integral is 1.0';

    my $rebinned = $h->rebin(2);
    is $rebinned->nbins, 5, 'rebinned to 5 bins';
};

subtest 'Plot and sparkline' => sub {
    use Math::Histo::Constants qw(@PALETTES);
    is scalar(@PALETTES), 8, '8 palettes exported';
    is $PALETTES[0], 'viridis', 'first palette is viridis';

    my $h = Math::Histo->new(bins => 10, min => 0.0, max => 100.0);
    $h->fill_n([10, 20, 20, 30, 40, 50, 60, 70, 80, 90]);

    my $spk = $h->sparkline(show => 0);
    ok length($spk) > 0, 'sparkline produced';

    my $plot = $h->plot(style => 'ascii', color => 0, show => 0);
    ok length($plot) > 0, 'plot produced';
};

done_testing;
