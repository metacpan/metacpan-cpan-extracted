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

subtest 'Log-Normal fitting' => sub {
    my $h = Math::Histo->new(bins => 50, min => 0.1, max => 15.0);
    for (my $x = 0.2; $x < 15.0; $x += 0.3) {
        my $lx = log($x);
        my $val = (500.0 / ($x * 0.4 * sqrt(2 * 3.14159265))) * exp(-0.5 * (($lx - 1.5) / 0.4) ** 2);
        $h->fill($x, $val);
    }

    my $res = $h->fit(model => 'lognormal');
    isa_ok $res, 'Math::Histo::Fit::Result';
    ok $res->status <= 2, 'lognormal fit converged';
    is $res->n_params, 3, '3 params (A, mu, sigma)';
    my $p = $res->params;
    is $p->[0], within(500.0, 50.0), 'A near 500';
    is $p->[1], within(1.5, 0.2), 'mu near 1.5';
    is $p->[2], within(0.4, 0.2), 'sigma near 0.4';
};

subtest 'Poisson fitting' => sub {
    my $h = Math::Histo->new(bins => 20, min => 0.0, max => 15.0);
    # Continuous gamma approx
    for (my $x = 0.5; $x < 15.0; $x += 0.5) {
        my $val = 100.0 * exp($x * log(4.5) - 4.5); # unnormalized approx
        $h->fill($x, $val);
    }

    my $res = $h->fit(model => 'poisson');
    isa_ok $res, 'Math::Histo::Fit::Result';
    ok $res->status <= 2, 'poisson fit converged';
    is $res->n_params, 2, '2 params (A, lambda)';
};

subtest 'Laplace fitting' => sub {
    my $h = Math::Histo->new(bins => 50, min => 0.0, max => 10.0);
    for (my $x = 0.1; $x < 10.0; $x += 0.2) {
        my $val = (150.0 / (2 * 1.2)) * exp(-abs($x - 5.0) / 1.2);
        $h->fill($x, $val);
    }

    my $res = $h->fit(model => 'laplace');
    isa_ok $res, 'Math::Histo::Fit::Result';
    ok $res->status <= 2, 'laplace fit converged';
    is $res->n_params, 3, '3 params (A, mu, b)';
    my $p = $res->params;
    is $p->[0], within(150.0, 20.0), 'A near 150';
    is $p->[1], within(5.0, 0.3), 'mu near 5.0';
    is $p->[2], within(1.2, 0.3), 'b near 1.2';
};

subtest 'Direct model evaluation and analytical gradient evaluation' => sub {
    my $val = Math::Histo::Fit->eval('gaussian', [100.0, 5.0, 2.0], 5.0);
    is $val, within(100.0, 1e-6), 'Gaussian eval at peak is amplitude';

    my $grad = Math::Histo::Fit->eval_grad('gaussian', [100.0, 5.0, 2.0], 5.0);
    is ref($grad), 'ARRAY', 'grad is arrayref';
    is scalar(@$grad), 3, 'grad has 3 components';
    is $grad->[0], within(1.0, 1e-6), 'df/dA = 1 at peak';
    is $grad->[1], within(0.0, 1e-6), 'df/dmu = 0 at peak';
};

done_testing;
