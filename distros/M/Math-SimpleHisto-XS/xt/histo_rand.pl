use strict;
use warnings;
use Math::SimpleHisto::XS;
use SOOT qw/:all/;
use Math::Random::OO::Normal;

my $variable_bins = 0;
my $rnd = Math::Random::OO::Normal->new(30, 10);
my $h = Math::SimpleHisto::XS->new(
  $variable_bins
  ? (bins => [0..100])
  : (nbins => 100, min => 0., max => 100.)
);
$h->fill($rnd->next) for 1..20000;

my $h2 = $h->new_alike;
$h2->fill($h->rand) for 1..20000;

#$h2->normalize(1);
#$h->normalize(1);

# FIXME: For testing REALLY variable bins, this needs to be passed on to SOOT:
my $rh = TH1D->new("orig", "orig", $h->nbins, 0, 100);
$rh->SetBinContent($_+1, $h->bin_content($_)) for 0..$h->nbins-1;

my $regen = TH1D->new("regen", "regen", $h->nbins, 0, 100);
$regen->SetBinContent($_+1, $h2->bin_content($_)) for 0..$h2->nbins-1;

our $canvas = TCanvas->new;
$rh->SetFillColor(kRed);
$rh->SetFillStyle(1001);
$rh->SetLineColor(kRed);
$rh->Draw();
$regen->Draw("SAME");
$canvas->BuildLegend;
$gApplication->Run();
