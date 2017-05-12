use strict;
use warnings;

if ($ENV{TEST_MEMORY}) {
  my $count = $ENV{TEST_MEMORY} > 1 ? $ENV{TEST_MEMORY} : 10_000;
  my $limit = 1_000_000;
  diag "Test memory by running this $count times; Make sure Memory::Stats is installed";
  require Memory::Stats;
  my $stats = Memory::Stats->new;
  {
    eval 'package MockB; sub AUTOLOAD { }';    ## no critic
    diag "*Test::More::builder";
    local *Test::More::builder = sub { bless {}, 'MockB' };
    run_tests();
    $stats->start;
    do { run_tests(); }
      for 1 .. $count;
  }
  $stats->stop;
  my $consumed = $stats->usage;
  diag "consumed $consumed bytes";
  ok $stats->usage < $limit, "consumed $consumed bytes, threshold is: $limit";
}
else {
  diag("provide TEST_MEMORY ENV to do extra tests");
}
