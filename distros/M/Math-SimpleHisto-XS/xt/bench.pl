use strict;
use warnings;
use Test::More tests => 1;
pass(); # Just in case somebody wants to run this through some TAP thingy

use Math::SimpleHisto::XS;
use Benchmark qw(:hireswallclock timethis);

our $Hist = Math::SimpleHisto::XS->new(min => 123, max => 890, nbins => 10000);
timethis(-2, q{
  $::Hist->fill(312, 51)
});

our $Data = [map 123+rand(890-123), 0..4999];
our $Weight = [map 123+rand(890-123), 0..4999];
timethis(-2, q{
  $::Hist->fill($::Data, $::Weight)
});

timethis(-2, q{
  $::Hist->fill($::Data)
});

