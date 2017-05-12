use strict;
use warnings;
use Test::More tests => 439;
BEGIN { use_ok('Math::SimpleHisto::XS') };

use lib 't/lib', 'lib';
use Test_Functions;

my $hf = Math::SimpleHisto::XS->new(
  nbins => 200, min => 123.1, max => 255.9
);
my $hv = Math::SimpleHisto::XS->new(
  bins => [12000, 12001, 12001.1, 13000, 15000, 100000],
);

for my $h ($hf, $hv) {
  $h->fill($h->min + rand($h->width), rand(100)) for 1..1000;
}

foreach ([$hf, 'fixed bin size'], [$hv, 'variable bin size']) {
  my ($h, $name) = @$_;
  my $cum = $h->cumulative;

  # test simple properties
  isa_ok($cum, 'Math::SimpleHisto::XS');
  is($cum->nfills, $h->nfills, "nfills same ($name)");
  is_approx($cum->underflow, $h->underflow, "underflow same ($name)");
  is_approx($cum->overflow, $h->overflow, "overflow same ($name)");
  is_approx($cum->min, $h->min, "min same ($name)");
  is_approx($cum->max, $h->max, "max same ($name)");
  is_approx($cum->width, $h->width, "width same ($name)");
  is($cum->nbins, $h->nbins, "nbins same ($name)");
  is_approx($cum->binsize, $h->binsize, "binsize(0) same ($name)");
  is_approx($cum->binsize(3), $h->binsize(3), "binsize(3) same ($name)");

  my $sum = 0;
  my $prev = 0;
  foreach my $i (0..$h->nbins-1) {
    ok($cum->bin_content($i) >= $prev, "Bin content in bin $i monotonically increasing ($name)");
    $prev = $h->bin_content($i);
    $sum += $prev;
    is_approx($cum->bin_content($i), $sum, "Cumulative bin content bin $i ($name)");
  }

  my $norm_cum = $h->cumulative(12.3);
  is_approx($norm_cum->bin_content($norm_cum->nbins-1), 12.3, "Normalized cumulative histo ($name)");
  $norm_cum->multiply_constant(1/12.3);
  is_approx($norm_cum->bin_content($norm_cum->nbins-1), 1., "Normalized cumulative histo after rescaling ($name)");

  $norm_cum = $h->cumulative(1);
  my $rng = Math::SimpleHisto::XS::RNG->new(time);
  my @rand = map $norm_cum->rand($rng), 1..100;
  my $ref = $rand[0];
  ok((grep $ref == $_, @rand) != 100, 'Sad random number test using new RNG');

  @rand = map $norm_cum->rand(), 1..100;
  $ref = $rand[0];
  ok((grep $ref == $_, @rand) != 100, 'Sad random number test!');
}

