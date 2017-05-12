use strict;
use warnings;
use Test::More tests => 19;
BEGIN { use_ok('Math::SimpleHisto::XS') };

use lib 't/lib', 'lib';
use Test_Functions;

# mean
my $h = Math::SimpleHisto::XS->new(min => 0, max => 10, nbins => 100000);
$h->fill(1);
$h->fill(2);
$h->fill(3);
is_approx($h->mean(), 2, "mean test 1", 1e-4);
is_approx($h->median, 2, "median test 1", 1e-4);
is_approx($h->standard_deviation, 0.816496580928543, "std. dev. test 1", 1e-2);
is_approx($h->median_absolute_deviation, 1, "mad test 1", 1e-2);
is_approx($h->median_absolute_deviation($h->median), $h->median_absolute_deviation, "mad consistency test 1", 1e-4);

{
  my $hclone = $h->clone;
  $hclone->fill(2, 10);
  is_approx($hclone->mean(), 2, "mean test 2", 1e-4);
  is_approx($hclone->median, 2, "median test 2", 1e-3);
  is_approx($hclone->standard_deviation, sqrt(2/13), "std. dev. test 2", 1e-2);
  is_approx($hclone->median_absolute_deviation, 0., "mad test 2", 1e-2); # TODO debug and review
  is_approx($hclone->median_absolute_deviation($hclone->median), $hclone->median_absolute_deviation, "mad consistency test 2", 1e-4);
}

$h->fill(5,2);
is_approx($h->mean(), 3.2, "mean test 3", 1e-4);
is_approx($h->median, 3.005, "median test 3", 1e-2);
is_approx($h->standard_deviation, 1.60000000000077, "std. dev. test 3", 1e-2);

$h->fill(8, 10000000);
is_approx($h->mean(), 8, "mean test 4", 1e-4);
is_approx($h->median(), 8, "median test 4", 1e-2);
is_approx($h->standard_deviation, 0.00357770706458479, "std. dev. test 4", 1e-2);

$h->set_nfills(0);
is_approx($h->mean(), 8, "mean test 5", 1e-4);
is_approx($h->median(), 8, "median test 5", 1e-2);
