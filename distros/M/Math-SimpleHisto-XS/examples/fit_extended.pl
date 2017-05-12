use strict;
use warnings;

# Note: This isn't statistically correct if you're going to use
#       weights when filling the histogram.
# Note2: The fitting isn't working *very* well, but the trivial case
#        as below is just fine.
# Note3: For heavy-duty fitting, try the Minuit library which is used
#        by ROOT (and thus the SOOT module).

use Algorithm::CurveFit;
use Math::SimpleHisto::XS;
use Math::Random::OO::Normal;
use Math::SymbolicX::Statistics::Distributions ':functions';
use Data::Dumper;
use List::Util qw(max);
use SOOT qw/:all/; # You probably do not have this module, sorry.

my $rnd = Math::Random::OO::Normal->new(30, 10);
my $h = Math::SimpleHisto::XS->new(nbins => 100, min => 0., max => 100.);

print "Filling histogram with randomized data...\n";
$h->fill($rnd->next) for 1..100000;
$h->normalize;

print "Fitting histogram...\n";
my @params = (
  # name, guess, desired precision
  [mu    => 28.1, 0.001],
  [sigma => 1.8, 0.01],
);
my $residual = Algorithm::CurveFit->curve_fit(
  formula => normal_distribution('mu', 'sigma'), # our assumption
  xdata   => $h->bin_centers,
  ydata   => $h->all_bin_contents,
  params  => \@params,
);

print "Fit result:\n";
print "$_->[0] = $_->[1]\n" for @params;

# Draw the histogram and the fit using SOOT
my $hs = TH1D->new("gauss", "gauss", $h->nbins, $h->min, $h->max);
$hs->SetBinContent($_+1, $h->bin_content($_)) for 0..$h->nbins-1;
$hs->Draw;

$formula =~ s/mu/[0]/g;
$formula =~ s/sigma/[1]/g;
my $fun = TF1->new("fit", $formula, $h->min, $h->max);
$fun->SetParameter($_, $params[$_][1]) for 0..1;
$fun->SetLineColor(kRed);
$fun->Draw("SAME");

$gApplication->Run();

