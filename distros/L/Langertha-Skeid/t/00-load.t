use strict;
use warnings;
use Test::More;

my @modules = qw(
  Langertha::Skeid
  Langertha::Skeid::Proxy
);

for my $mod (@modules) {
  require_ok($mod);
}

done_testing;
