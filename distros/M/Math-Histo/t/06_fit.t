use Test2::V0;
use Math::Histo;
use Math::Histo::Fit;

subtest 'Gaussian curve fitting' => sub {
    my $h = Math::Histo->new(bins => 50, min => -5.0, max => 5.0);

    # Generate synthetic Gaussian: A=100, mu=0.0, sigma=1.0
    for (my $x = -4.5; $x <= 4.5; $x += 0.2) {
        my $val = 100.0 * exp(-($x * $x) / 2.0);
        $h->fill($x, $val);
    }

    my $res = $h->fit(model => 'gaussian');
    isa_ok $res, 'Math::Histo::Fit::Result';
    ok $res->status <= 2, 'fit converged';
    is $res->n_params, 3, '3 params (A, mu, sigma)';

    my $p = $res->params;
    my $e = $res->errors;
    is ref($p), 'ARRAY', 'params is arrayref';
    is ref($e), 'ARRAY', 'errors is arrayref';

    # Check fitted parameters: A ~ 100, mu ~ 0, sigma ~ 1
    is $p->[0], within(100.0, 10.0), 'fitted amplitude A near 100';
    is $p->[1], within(0.0, 0.2), 'fitted mean mu near 0';
    is $p->[2], within(1.0, 0.2), 'fitted sigma near 1';

    ok defined($res->chi2), 'chi2 defined';
    ok defined($res->reduced_chi2), 'reduced chi2 defined';
    ok defined($res->p_value), 'p-value defined';

    my $summary = $res->summary;
    like $summary, qr/Fit Status:/, 'summary string generated';
};

subtest 'Polynomial fitting' => sub {
    my $h = Math::Histo->new(bins => 20, min => 0.0, max => 10.0);
    # Linear slope: y = 2 * x + 5
    for (my $x = 0.5; $x < 10.0; $x += 0.5) {
        $h->fill($x, 2.0 * $x + 5.0);
    }

    my $res = $h->fit(
        model => 'polynomial',
        initial => [5.0, 2.0],
    );
    isa_ok $res, 'Math::Histo::Fit::Result';
    ok $res->status >= 0, 'polynomial fit converged';
};


done_testing;
