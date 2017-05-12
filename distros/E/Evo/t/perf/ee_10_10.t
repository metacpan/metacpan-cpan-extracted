package main;
use Evo;
use Test::Evo::Benchmark;
use Test::More;

plan skip_all => 'set TEST_EVO_PERF env to enable this test' unless $ENV{TEST_EVO_PERF};

my $EXPECT = 9_000 * $ENV{TEST_EVO_PERF};

my $N = 20_000;

my $N_EVENTS     = 10;
my $N_EMIT_COUNT = 10;
my $k            = 0;

{

  package My::Obj;
  use Evo '-Class *';
  with 'Evo::Ee';
  sub ee_events { 'event', 'ev2', 'ev3', 'ev4' }
}

my $fn = sub {
  my $obj = My::Obj->new();
  $obj->on(event => sub { $k += $_[1] }) for 1 .. $N_EVENTS;
  $obj->emit(event => 1) for 1 .. $N_EMIT_COUNT;
};


faster_ok(fn => $fn, iters => $N, expect => $EXPECT, diag => 1);

is $k, $N * $N_EVENTS * $N_EMIT_COUNT, "$k = $N * $N_EVENTS * $N_EMIT_COUNT";

done_testing;
