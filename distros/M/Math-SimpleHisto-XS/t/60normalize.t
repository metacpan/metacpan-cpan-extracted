use strict;
use warnings;
use Test::More tests => 14;
BEGIN { use_ok('Math::SimpleHisto::XS') };

use lib 't/lib', 'lib';
use Test_Functions;

# normalize
my $h = Math::SimpleHisto::XS->new(min => 0, max => 10, nbins => 10);
$h->fill(1);
$h->fill(2, 2);
$h->fill(3, 3);
$h->normalize;
is_approx($h->bin_content(1), 1/6, 'normalization bin 1', 1e-6);
is_approx($h->bin_content(2), 2/6, 'normalization bin 2', 1e-6);
is_approx($h->bin_content(3), 3/6, 'normalization bin 3', 1e-6);
is_approx($h->bin_content(4), 0, 'normalization bin 4', 1e-6);
is_approx($h->total, 1., 'normalization total', 1e-6);
is_approx($h->integral($h->min, $h->max), 1, 'normalization integral', 1e-6);
my $clone = $h->clone;
{
  $clone->fill(3, 3);
  is_approx($clone->bin_content(3), 3+3/6, 'normalization, fill bin 3', 1e-6);
}
$h->normalize(2.5);
is_approx($h->total, 2.5, 'renormalization total', 1e-6);
is_approx($h->integral($h->min, $h->max), 2.5, 'renormalization integral', 1e-6);
is_approx($h->bin_content(1), 2.5*1/6, 'renormalization bin 1', 1e-6);
is_approx($h->bin_content(2), 2.5*2/6, 'renormalization bin 2', 1e-6);
is_approx($h->bin_content(3), 2.5*3/6, 'renormalization bin 3', 1e-6);
is_approx($h->bin_content(4), 0, 'renormalization bin 4', 1e-6);

