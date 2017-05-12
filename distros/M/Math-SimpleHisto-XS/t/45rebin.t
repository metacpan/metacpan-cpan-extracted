use strict;
use warnings;
use Test::More;
BEGIN { use_ok('Math::SimpleHisto::XS') };

use lib 't/lib', 'lib';
use Test_Functions;

my $hf = Math::SimpleHisto::XS->new(
  nbins => 200, min => 123.1, max => 255.9
);
my $hv = Math::SimpleHisto::XS->new(
  bins => [-1., 12000, 12001, 12001.1, 13000, 15000, 100000],
);

srand(0);
for my $h ($hf, $hv) {
  $h->fill($h->min + rand($h->width), rand(100)) for 1..1000;
}

SCOPE: {
  my $rebinned = $hf->rebin(2);
  isa_ok($rebinned, 'Math::SimpleHisto::XS');
  is_approx($rebinned->min, $hf->min, "minimum stayed the same");
  is_approx($rebinned->max, $hf->max, "maximum stayed the same");
  is($rebinned->total, $hf->total);
  is($rebinned->nbins, 100);
  my $sum = 0;
  $sum += $_ for @{ $rebinned->all_bin_contents };
  is_approx($sum, $hf->total);
  is_approx($rebinned->binsize, $hf->binsize*2);
  $rebinned = $rebinned->rebin(10);
  is_approx($rebinned->binsize, $hf->binsize*20);
  $sum = 0;
  $sum += $_ for @{ $rebinned->all_bin_contents };
  is_approx($sum, $hf->total);
  ok(!eval{$hf->rebin(7); 1});
}

SCOPE: {
  my $rebinned = $hv->rebin(3);
  isa_ok($rebinned, 'Math::SimpleHisto::XS');
  is_approx($rebinned->min, $hv->min, "minimum stayed the same");
  is_approx($rebinned->max, $hv->max, "maximum stayed the same");
  is($rebinned->total, $hv->total);
  is($rebinned->nbins, 2);
  my $sum = 0;
  $sum += $_ for @{ $rebinned->all_bin_contents };
  is_approx($sum, $hv->total);
  ok(!eval{$hv->rebin(7); 1});
}


done_testing();
