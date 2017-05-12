use strict;
use warnings;
use List::Util qw/min max sum/;

use Test::More tests => 102;
BEGIN { use_ok('Math::CMA') };

sub central_moving_averages_slow {
  my ($count, $series) = @_;
  map { (sum map { $series->[$_] } @$_) / @$_ }
  map { [ max(0, $_ - $count) .. min(@$series - 1, $_ + $count) ] }
  0 .. @$series - 1
}

for (0 .. 100) {
  my $count = int(rand 100);
  my $items = int(rand 100);
  my @array = map { int(rand 100) - 50 } 0 .. $items;
  my @vers1 = Math::CMA::central_moving_averages($count, \@array);
  my @vers2 = central_moving_averages_slow($count, \@array);
  is_deeply \@vers1, \@vers2, "randomized test $_";
}
