use strict;
use warnings;
use lib 't/lib', 'lib';

use Test::More;
use Math::SZaru;
use Math::SZaru::QuantileEstimator;
use SecTest qw(isolated);

my $nan = 9**9**9 / 9**9**9;
my $inf = 9**9**9;

# SZARU-04 / SZARU-07: ComputeQuantiles over many elements (multi-level
# buffers) must terminate, return numQuantiles values and be monotonic.
SCOPE: {
  for my $q (2, 3, 10, 100) {
    my $r = isolated(sub {
      my $e = Math::SZaru::QuantileEstimator->new($q);
      my $n = 200_000;
      $e->add_elem($_ % 1000) for 1..$n;
      my $est = $e->estimate();
      my $mono = 1;
      for (1..$#$est) { $mono = 0 if $est->[$_] < $est->[$_ - 1] }
      return scalar(@$est) . ":" . $mono . ":" . $est->[0] . ":" . $est->[-1];
    }, 120);
    ok($r->{ok}, "SZARU-04: quantile($q) with many elements terminates (signal=$r->{signal})");
    is($r->{result}, "$q:1:0:999", "SZARU-04: quantile($q) sane result");
  }
}

# All-equal elements and tiny quantile counts
SCOPE: {
  my $r = isolated(sub {
    my $e = Math::SZaru::QuantileEstimator->new(1);
    $e->add_elems((5) x 1000);
    my $est = $e->estimate();
    return join(",", @$est);
  });
  ok($r->{ok}, "SZARU-04: quantile(1) with equal elements terminates");
}

# empty
SCOPE: {
  my $r = isolated(sub { my $e = Math::SZaru::QuantileEstimator->new(10); return scalar @{$e->estimate()} });
  ok($r->{ok} && $r->{result} == 1, "SZARU-05: empty quantile estimate returns one element");
}

# SZARU-08: constructor validation
for my $bad (0, -1, -2147483648, 1000001, 2**33, 2**63) {
  my $r = isolated(sub { my $e = Math::SZaru::QuantileEstimator->new($bad); return ref($e) });
  ok(!$r->{signal} && $r->{died}, "SZARU-08: QuantileEstimator->new($bad) croaks cleanly")
    or diag("signal=$r->{signal} ok=$r->{ok} result=" . ($r->{result} // 'undef'));
}
for my $good (1, 2, 100, 1000) {
  my $r = isolated(sub { my $e = Math::SZaru::QuantileEstimator->new($good); return ref($e) });
  ok($r->{ok} && $r->{result} eq 'Math::SZaru::QuantileEstimator', "SZARU-08: QuantileEstimator->new($good) works");
}

# SZARU-09: NaN / Inf are rejected
for my $pair ([NaN => $nan], [Inf => $inf], ['-Inf' => -$inf]) {
  my ($name, $v) = @$pair;
  my %cases = (
    add_elem  => sub { $_[0]->add_elem($v) },
    add_elems => sub { $_[0]->add_elems(1, 2, $v, 3) },
  );
  for my $c (sort keys %cases) {
    my $r = isolated(sub {
      my $e = Math::SZaru::QuantileEstimator->new(5);
      $e->add_elem($_) for 1..20;
      eval { $cases{$c}->($e); 1 } or die $@;
      my $x = $e->estimate();
      return scalar(@$x);
    });
    ok(!$r->{signal} && $r->{died} && $r->{error} =~ /finite|NaN|Inf/i,
       "SZARU-09: QuantileEstimator $c($name) croaks")
      or diag("signal=$r->{signal} exit=$r->{exit} err=" . ($r->{error} // $r->{result} // 'undef'));
  }
}
# NaN in the middle of a long run must not wreck sorting / estimates
SCOPE: {
  my $r = isolated(sub {
    my $e = Math::SZaru::QuantileEstimator->new(5);
    for (1..5000) {
      $e->add_elem($_);
      eval { $e->add_elem($nan) } if $_ % 7 == 0;
    }
    my $x = $e->estimate();
    return scalar(@$x);
  }, 120);
  ok($r->{ok} && $r->{result} == 5, "SZARU-09: interleaved NaN does not break quantiles (signal=$r->{signal})");
}

# SZARU-10: methods invoked on non-objects must not dereference NULL
SCOPE: {
  for my $m (qw(add_elems add_elem estimate tot_elems)) {
    my @args = $m =~ /^add/ ? (1) : ();
    my $fake = bless \(my $zero = 0), 'Math::SZaru::QuantileEstimator';
    my $r = isolated(sub {
      no strict 'refs';
      my $code = "Math::SZaru::QuantileEstimator::$m";
      eval { $code->($fake, @args); 1 };
      return "survived";
    });
    ok($r->{ok}, "SZARU-10: QuantileEstimator::$m on object with NULL pointer does not crash (signal=$r->{signal})");
    $r = isolated(sub {
      no strict 'refs';
      my $code = "Math::SZaru::QuantileEstimator::$m";
      eval { $code->(undef, @args); 1 };
      eval { $code->("Math::SZaru::QuantileEstimator", @args); 1 };
      return "survived";
    });
    ok($r->{ok}, "SZARU-10: QuantileEstimator::$m on non-object does not crash (signal=$r->{signal})");
  }
}

done_testing();
