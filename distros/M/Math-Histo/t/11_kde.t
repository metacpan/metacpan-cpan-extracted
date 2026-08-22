use strict;
use warnings;
use Test::More;
use Math::Histo;
use Math::Histo::KDE;
use Math::Histo::Constants qw(:kde);

my @data = (1.0..10.0);
my $kde = Math::Histo::KDE->new(
    samples   => \@data,
    kernel    => 'gaussian',
    bw_method => 'silverman',
);

ok(defined $kde, "Math::Histo::KDE object created");
is($kde->n_points, 10, "10 sample points");
cmp_ok($kde->bandwidth, '>', 0, "positive bandwidth");

my $pdf_5 = $kde->eval(5.5);
cmp_ok($pdf_5, '>', 0, "PDF evaluated > 0");

my $cdf_5 = $kde->cdf(5.5);
cmp_ok($cdf_5, '>=', 0.40, "CDF >= 0.40");
cmp_ok($cdf_5, '<=', 0.60, "CDF <= 0.60");

my $q50 = $kde->quantile(0.50);
cmp_ok($q50, '>=', 4.5, "median >= 4.5");
cmp_ok($q50, '<=', 6.5, "median <= 6.5");

my @samples = $kde->sample(25, 42);
is(scalar(@samples), 25, "sampled 25 points");

# Test all kernels
for my $k (qw(gaussian epanechnikov boxcar triangular biweight cosine)) {
    my $m = Math::Histo::KDE->new(samples => \@data, kernel => $k, bandwidth => 1.0, bw_method => 'manual');
    ok(defined $m, "Kernel $k initialized");
    cmp_ok($m->eval(5.5), '>', 0, "Kernel $k evaluated");
}

# Test from_histogram
my $h = Math::Histo->new(bins => 20, min => 0, max => 20);
$h->fill($_) for (1..19);
my $h_kde = Math::Histo::KDE->from_histogram($h);
ok(defined $h_kde, "KDE from histogram");
cmp_ok($h_kde->eval(10.0), '>', 0, "PDF from histogram KDE > 0");

done_testing();
