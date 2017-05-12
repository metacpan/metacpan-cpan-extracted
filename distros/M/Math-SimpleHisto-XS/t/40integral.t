use strict;
use warnings;
use Test::More tests => 39;
BEGIN { use_ok('Math::SimpleHisto::XS') };

use lib 't/lib', 'lib';
use Test_Functions;

# test simple integral and clone
use Math::SimpleHisto::XS qw(:all);
my $min = 11;
my $max = 102;
my $nbins = 39;
my $h = Math::SimpleHisto::XS->new(min => $min, max => $max, nbins => $nbins);
# make it so that for each 1 on the x axis, we get 1 in the integral!
$h->set_bin_content($_, $_+0.1) for 0..$nbins-1;

my $binsize = $h->binsize;
my $h2 = $h->clone;
for my $ht ($h, $h2) {
  is_approx($ht->integral($ht->min, $ht->max), $h->total, 'Check total integral', 1e-6);
  is_approx($ht->integral($ht->min, $ht->max, INTEGRAL_CONSTANT), $h->total, 'Check total integral', 1e-6);
  my $sum = (1-0.32857142857143)*$ht->bin_content(1);
  $sum += $ht->bin_content($_) for 2..$nbins-1;
  is_approx($ht->integral($ht->min+3.1, $ht->max), $sum, 'Check fractional start bin', 1e-6);
  $sum = (1-0.32857142857143)*$ht->bin_content(1);
  $sum += $ht->bin_content($_) for 2..$nbins-4;
  $sum -= (0.2)*$ht->bin_content(35);
  is_approx($ht->integral($ht->min+3.1, $ht->max-(3.2*($max-$min)/$nbins)), $sum, 'Check fractional start and end bin', 1e-4);
  is_approx($ht->integral($ht->min+3.1, $ht->max-(3.2*($max-$min)/$nbins), INTEGRAL_CONSTANT), $sum, 'Check fractional start and end bin', 1e-4);
  my $bin = $ht->find_bin(50.1);
  is($bin, $ht->find_bin(50.2));
  is_approx($ht->integral(50.1, 50.2), $ht->bin_content($bin)*0.1/$binsize, 'Check fractional start and end bin', 1e-4);
}

SCOPE: {
  my $hs = Math::SimpleHisto::XS->new(nbins => 2, min => 3, max => 4);
  $hs->fill(3.2, 1000);
  is_approx($hs->integral(-100, 100), 1000, 'Full integral');
  is_approx($hs->integral(100, -100), -1000, 'Full integral inverted');
  is_approx($hs->integral(3.25, 100), 500, 'Fractional integral');
  is_approx($hs->integral(-.1, 3.25), 500, 'Fractional integral 2');
}


# Now, test with variable bin sizes
SCOPE: {
  my $bins = [13, 15, 19, 25, 100];
  my $h = Math::SimpleHisto::XS->new(bins => $bins);
  $h->set_bin_content(0, 2);
  $h->set_bin_content(1, 4);
  $h->set_bin_content(2, 6);
  $h->set_bin_content(3, 75);

  my $h2 = $h->clone;
  for my $ht ($h, $h2) {
    is_approx($ht->integral($ht->min, $ht->max), $ht->total, 'Check total integral (variable bins)', 1e-6);
    is_approx($ht->integral($ht->bin_center(0), $ht->max), $ht->total-$ht->bin_content(0)/2., 'Check fractional integral (variable bins)', 1e-6);
    is_approx($ht->integral($ht->bin_center(0), $ht->bin_upper_boundary(2)-1e-9), $ht->total-$ht->bin_content(0)/2.-$ht->bin_content(3), 'Check fractional integral 2 (variable bins)', 1e-6);
    is_approx($ht->integral($ht->bin_center(0), $ht->bin_upper_boundary(2)), $ht->total-$ht->bin_content(0)/2.-$ht->bin_content(3), 'Check fractional integral 3 (variable bins)', 1e-6);
    is_approx($ht->integral($ht->bin_center(0), $ht->bin_upper_boundary(2)+1e-9), $ht->total-$ht->bin_content(0)/2.-$ht->bin_content(3), 'Check fractional integral 4 (variable bins)', 1e-6);
    is_approx($ht->integral($ht->bin_center(0), $ht->bin_center(2)), $ht->total-$ht->bin_content(0)/2.-$ht->bin_content(3)-$ht->bin_content(2)/2, 'Check fractional integral 5 (variable bins)', 1e-6);
    
    is_approx($ht->integral($ht->bin_lower_boundary(1), $ht->bin_upper_boundary(1)), $ht->bin_content(1), 'Single full bin (variable bins)', 1e-6);
    is_approx($ht->integral($ht->bin_lower_boundary(1)-1e-9, $ht->bin_upper_boundary(1)+1e-9), $ht->bin_content(1), 'Single full bin extended (variable bins)', 1e-6);
    is_approx($ht->integral($ht->bin_lower_boundary(1)+1e-9, $ht->bin_upper_boundary(1)-1e-9), $ht->bin_content(1), 'Single full bin contracted (variable bins)', 1e-6);
    is_approx($ht->integral($ht->bin_lower_boundary(3)+1e-9, $ht->bin_center(3)), $ht->bin_content(3)/2, 'Single half bin contracted (variable bins)', 1e-6);
  }
}
