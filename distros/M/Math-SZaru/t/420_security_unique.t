use strict;
use warnings;
use lib 't/lib', 'lib';

use Test::More;
use Math::SZaru;
use Math::SZaru::UniqueEstimator;
use SecTest qw(isolated);

# SZARU-02 / SZARU-07: the estimate must be well defined (no uninitialised
# reads, no shift UB), never exceed the number of added elements, and be
# reasonably close to the truth once the heap is full.
for my $max (1, 2, 3, 10, 100, 1000) {
  my $r = isolated(sub {
    my $e = Math::SZaru::UniqueEstimator->new($max);
    my @res;
    for my $step (1, 5, 50, 20000) {
      $e->add_elem("elem" . scalar(@res) . "_$_") for 1..$step;
      push @res, $e->estimate() . "/" . $e->tot_elems();
    }
    return join(" ", @res);
  });
  ok($r->{ok}, "SZARU-02: UniqueEstimator($max) estimate does not crash (signal=$r->{signal})");
  my $bad = 0;
  for my $pair (split / /, ($r->{result} || '')) {
    my ($est, $tot) = split m{/}, $pair;
    $bad++ if $est < 0 || $est > $tot;
  }
  is($bad, 0, "SZARU-02: UniqueEstimator($max) estimates are within [0, tot_elems]");
}

SCOPE: {
  my $e = Math::SZaru::UniqueEstimator->new(1000);
  $e->add_elem("u$_") for 1..100_000;
  my $est = $e->estimate;
  cmp_ok($est, '>', 70_000, "SZARU-02: estimate for 100000 uniques is plausible (low bound): $est");
  cmp_ok($est, '<', 130_000, "SZARU-02: estimate for 100000 uniques is plausible (high bound): $est");
  is($e->tot_elems, 100_000, "tot_elems");
}

# determinism: same input, same estimate (uninitialised reads would vary)
SCOPE: {
  my %seen;
  for (1..5) {
    my $e = Math::SZaru::UniqueEstimator->new(500);
    $e->add_elems(map "d$_", 1..20_000);
    $seen{$e->estimate}++;
  }
  is(scalar(keys %seen), 1, "SZARU-02: estimate is deterministic");
}

# SZARU-08: constructor validation
for my $bad (0, -1, -2147483648, 10_000_001, 2**33, 2**63) {
  my $r = isolated(sub { my $e = Math::SZaru::UniqueEstimator->new($bad); return ref($e) });
  ok(!$r->{signal} && $r->{died}, "SZARU-08: UniqueEstimator->new($bad) croaks cleanly")
    or diag("signal=$r->{signal} ok=$r->{ok} result=" . ($r->{result} // 'undef'));
}
for my $good (1, 1000, 10_000_000) {
  my $r = isolated(sub { my $e = Math::SZaru::UniqueEstimator->new($good); return ref($e) });
  ok($r->{ok} && $r->{result} eq 'Math::SZaru::UniqueEstimator', "SZARU-08: UniqueEstimator->new($good) works");
}

# SZARU-10: methods invoked on non-objects must not dereference NULL
SCOPE: {
  for my $m (qw(add_elems add_elem estimate tot_elems)) {
    my @args = $m =~ /^add/ ? ("x") : ();
    my $fake = bless \(my $zero = 0), 'Math::SZaru::UniqueEstimator';
    my $r = isolated(sub {
      no strict 'refs';
      my $code = "Math::SZaru::UniqueEstimator::$m";
      eval { $code->($fake, @args); 1 };
      return "survived";
    });
    ok($r->{ok}, "SZARU-10: UniqueEstimator::$m on object with NULL pointer does not crash (signal=$r->{signal})");
    $r = isolated(sub {
      no strict 'refs';
      my $code = "Math::SZaru::UniqueEstimator::$m";
      eval { $code->(undef, @args); 1 };
      eval { $code->("Math::SZaru::UniqueEstimator", @args); 1 };
      return "survived";
    });
    ok($r->{ok}, "SZARU-10: UniqueEstimator::$m on non-object does not crash (signal=$r->{signal})");
  }
}

done_testing();
