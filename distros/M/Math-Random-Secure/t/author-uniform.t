#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;
use Test::More;
use Math::Random::Secure qw(rand irand);
use Statistics::Test::RandomWalk 0.02;

# 2% variation is acceptable.
our $ACCEPTABLE = 0.02;
our $BINS = 20;
our $NUM_RUNS = 500_000;

# We want a number that's more than half of 2^32 but doesn't
# divide evenly into it.
our $LARGE_LIMIT = 3_000_893_649;

plan tests => (20 * $BINS) - (8 + 20 + 36 + 34);

sub test_uniform {
  my ($name, $limit, $rng) = @_;
  $rng ||= \&rand;

  my $num_runs = $NUM_RUNS;
  if (defined $limit and $limit > $num_runs) {

    # Uncomment this line for more extensive testing.
    #$num_runs = $limit * 2;
  }

  my $tester = Statistics::Test::RandomWalk->new();
  if ($rng == \&irand) {
    $tester->set_rescale_factor($limit || 2**32);
    $tester->set_data(sub { $rng->($limit) }, $num_runs);
  } else {
    my $divide_by;
    $divide_by = $limit - (1 / (2**32)) if $limit;
    $tester->set_data(sub { $limit ? $rng->($limit) / $divide_by : $rng->() },
      $num_runs);
  }

  my $bins = $BINS;
  if (defined $limit and $limit == 64) {
    $bins = 16;
  }
  if (defined $limit and $limit < $bins and $limit > 1) {
    $bins = $limit;
  }

  my ($quant, $got, $expected) = $tester->test($bins);

  foreach my $i (0 .. scalar(@$got) - 1) {
    cmp_ok(
      abs($got->[$i] - $expected->[$i]) / $expected->[$i],
      '<',
      $ACCEPTABLE,
      "$name: Quantile $quant->[$i] is within 2% of the expected "
        . $expected->[$i]);
  }

  if ($ENV{TEST_VERBOSE}) {
    diag $tester->data_to_report($quant, $got, $expected);
  }
}

test_uniform('rand no limit');
test_uniform('rand limit .3', .3);
test_uniform('rand limit .9', .9);
test_uniform('rand limit 2', 2);
test_uniform('rand limit 3', 3);
test_uniform('rand limit 10', 10);
test_uniform('rand limit 40', 40);
test_uniform('rand limit 64', 64);
test_uniform('rand limit 200', 200);
test_uniform('rand limit 1_000_000', 1_000_000);
test_uniform("rand limit $LARGE_LIMIT", $LARGE_LIMIT);

test_uniform('irand no limit', undef, \&irand);
test_uniform('irand limit 2', 2, \&irand);
test_uniform('irand limit 3', 3, \&irand);
test_uniform('irand limit 10', 10, \&irand);
test_uniform('irand limit 40', 40, \&irand);
test_uniform('irand limit 64', 64, \&irand);
test_uniform('irand limit 200', 200, \&irand);
test_uniform('irand limit 1_000_000', 1_000_000, \&irand);
test_uniform("irand limit $LARGE_LIMIT", $LARGE_LIMIT, \&irand);
