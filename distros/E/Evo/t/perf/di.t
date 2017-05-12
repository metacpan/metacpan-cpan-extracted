package main;
use Evo -Di;
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 1000_000 * $ENV{TEST_EVO_PERF};

my $N = 500_000;

my $k = 0;

{

  package My::S1;
  use Evo -Class, -Loaded;
  has 's2', inject 'My::S2';

  package My::S2;
  use Evo -Class, -Loaded;

}

my $di = Evo::Di->new();

my $fn = sub {
  my $s = $di->single('My::S1')->s2;
  $k++;
};


faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);
is $k, $N, "$k = $N";

done_testing;
