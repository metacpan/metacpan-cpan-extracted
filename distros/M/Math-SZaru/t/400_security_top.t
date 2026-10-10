use strict;
use warnings;
use lib 't/lib', 'lib';

use Test::More;
use Math::SZaru;
use Math::SZaru::TopEstimator;
use SecTest qw(isolated);

# SZARU-01: estimate() must return a plain RV to an AV that is owned only by
# that RV (refcount 1); an additional sv_2mortal() double-frees it.
SCOPE: {
  my $e = Math::SZaru::TopEstimator->new(10);
  $e->add_elems(qw(a b c a b a));
  my $est = $e->estimate();
  is(Internals::SvREFCNT(@$est), 1, "SZARU-01: result AV has refcount 1");
  my $r = isolated(sub {
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    my $t = Math::SZaru::TopEstimator->new(10);
    $t->add_elems(1..50);
    for (1..2000) {
      my $x = $t->estimate();
      my @copy = map { [@$_] } @$x;
      $x = undef;
    }
    return scalar(@warn);
  });
  ok($r->{ok}, "SZARU-01: repeated estimate() does not crash (signal=$r->{signal})")
    and is($r->{result}, 0, "SZARU-01: no perl warnings (double free)");
}

# SZARU-05: estimate() of empty estimator works
SCOPE: {
  my $r = isolated(sub {
    my $e = Math::SZaru::TopEstimator->new(5);
    my $x = $e->estimate();
    return ref($x) . ":" . scalar(@$x);
  });
  ok($r->{ok}, "SZARU-05: empty estimate does not crash");
  is($r->{result}, "ARRAY:0", "SZARU-05: empty estimate is empty array");
}

# SZARU-03 / SZARU-06: top-N must return the heaviest hitters even when far
# more distinct elements than the heap capacity (10 * numTops) are added.
SCOPE: {
  my $r = isolated(sub {
    my $n = 10;
    my $e = Math::SZaru::TopEstimator->new($n);
    my @heavy = map {"heavy$_"} 1..$n;
    my %w = map { ($heavy[$_ - 1] => 1000 * $_) } 1..$n;
    # interleave light noise with the heavy hitters
    my $noise = 0;
    for my $round (1..10) {
      for my $h (@heavy) {
        $e->add_weighted_elem($h, $w{$h} / 10);
        $e->add_elem("noise" . $noise++) for 1..30;
      }
    }
    my $est = $e->estimate();
    return join("|", scalar(@$est), map { $_->[0] } @$est);
  });
  ok($r->{ok}, "SZARU-06: many elements beyond capacity does not crash (signal=$r->{signal})")
    or diag($r->{error} || '');
  my @got = split /\|/, ($r->{result} || '');
  my $cnt = shift @got;
  is($cnt, 10, "SZARU-06: returns numTops elements");
  my @expect = map {"heavy$_"} reverse 1..10;
  is_deeply(\@got, \@expect, "SZARU-06: heaviest hitters returned, in order");
}

# Same, with a larger set (sketch is heavily exercised)
SCOPE: {
  my $r = isolated(sub {
    my $e = Math::SZaru::TopEstimator->new(20);
    my %w;
    for my $i (1..20000) { $e->add_elem("k" . ($i % 5000)); }
    $e->add_weighted_elem("winner$_", 100000 * $_) for 1..5;
    for my $i (1..20000) { $e->add_elem("z$i"); }
    my $est = $e->estimate();
    return join("|", map { $_->[0] } @$est[0..4]);
  });
  ok($r->{ok}, "SZARU-06: large run does not crash");
  is($r->{result}, join("|", map {"winner$_"} reverse 1..5), "SZARU-06: winners on top");
}

# SZARU-08: constructor validation
for my $bad (0, -1, -2147483648, 1000001, 2**33, 2**63, "abc") {
  my $r = isolated(sub { my $e = Math::SZaru::TopEstimator->new($bad); return ref($e) });
  ok(!$r->{signal} && $r->{died}, "SZARU-08: TopEstimator->new($bad) croaks cleanly")
    or diag("signal=$r->{signal} ok=$r->{ok} result=" . ($r->{result} // 'undef'));
}
for my $good (1, 10, 1000000) {
  my $r = isolated(sub { my $e = Math::SZaru::TopEstimator->new($good); return ref($e) });
  ok($r->{ok} && $r->{result} eq 'Math::SZaru::TopEstimator', "SZARU-08: TopEstimator->new($good) works");
}

# SZARU-09: NaN / Inf are rejected
my $nan = 9**9**9 / 9**9**9;
my $inf = 9**9**9;
for my $pair ([NaN => $nan], [Inf => $inf], ['-Inf' => -$inf]) {
  my ($name, $v) = @$pair;
  my %cases = (
    add_weighted_elem  => sub { $_[0]->add_weighted_elem("x", $v) },
    add_weighted_elems => sub { $_[0]->add_weighted_elems("a", 1, "b", $v, "c", 2) },
  );
  for my $c (sort keys %cases) {
    my $r = isolated(sub {
      my $e = Math::SZaru::TopEstimator->new(5);
      $e->add_elem("seed$_") for 1..3;
      eval { $cases{$c}->($e); 1 } or die $@;
      # whatever happened, the estimator must still work
      my $x = $e->estimate();
      return scalar(@$x);
    });
    ok(!$r->{signal} && $r->{died} && $r->{error} =~ /finite|NaN|Inf/i,
       "SZARU-09: TopEstimator $c($name) croaks")
      or diag("signal=$r->{signal} exit=$r->{exit} err=" . ($r->{error} // $r->{result} // 'undef'));
  }
}
# Also with a full heap (heap invariants matter most there)
SCOPE: {
  my $r = isolated(sub {
    my $e = Math::SZaru::TopEstimator->new(2);
    $e->add_elem("e$_") for 1..40;
    eval { $e->add_weighted_elem("e1", $nan); 1 };
    eval { $e->add_weighted_elem("new", $nan); 1 };
    my $x = $e->estimate();
    return scalar(@$x);
  });
  ok($r->{ok}, "SZARU-09: NaN on full heap does not abort (signal=$r->{signal})");
}

# SZARU-10: methods invoked on non-objects must not dereference NULL
SCOPE: {
  for my $m (qw(add_elems add_weighted_elems add_elem add_weighted_elem estimate tot_elems)) {
    my @args = $m =~ /^add_weighted/ ? ("x", 1) : $m =~ /^add/ ? ("x") : ();
    my $fake = bless \(my $zero = 0), 'Math::SZaru::TopEstimator';
    my $r = isolated(sub {
      no strict 'refs';
      my $code = "Math::SZaru::TopEstimator::$m";
      eval { $code->($fake, @args); 1 };
      return "survived";
    });
    ok($r->{ok}, "SZARU-10: TopEstimator::$m on object with NULL pointer does not crash (signal=$r->{signal})");
    $r = isolated(sub {
      no strict 'refs';
      my $code = "Math::SZaru::TopEstimator::$m";
      eval { $code->(undef, @args); 1 };
      eval { $code->("Math::SZaru::TopEstimator", @args); 1 };
      return "survived";
    });
    ok($r->{ok}, "SZARU-10: TopEstimator::$m on non-object does not crash (signal=$r->{signal})");
  }
}

done_testing();
