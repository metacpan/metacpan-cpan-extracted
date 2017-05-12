package main;
use Evo;
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 380_000 * $ENV{TEST_EVO_PERF};

my $N = 500_000;
my $k = 0;

{

  package My::Obj;
  use Evo '-Class *';
  with 'Evo::Ee';
  sub ee_events {'event'}
}

my $obj = My::Obj->new();
$obj->on(event => sub { $k += $_[1] });

my $fn = sub {
  $obj->emit(event => 1);
};


faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);
is $k, $N, "$k = $N";

done_testing;
