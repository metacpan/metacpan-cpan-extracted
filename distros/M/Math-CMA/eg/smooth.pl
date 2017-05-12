#!perl -w
use strict;
use warnings;
use Math::CMA 'central_moving_averages';

die "Usage: $0 <smoothing distance>;\n" .
    "reads white-space separated numbers from stdin\n"
  unless @ARGV;

my $count = shift @ARGV;
local $/;
my $slurp = <>;

my @averaged = central_moving_averages($count, [
  split/\s+/, $slurp
]);

print join "\n", @averaged;
