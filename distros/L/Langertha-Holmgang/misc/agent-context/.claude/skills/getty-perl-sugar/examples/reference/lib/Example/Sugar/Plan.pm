package Example::Sugar::Plan;
use strict;
use warnings;
use Example::Sugar::Registry ();
use Example::Sugar::Predicate ();

# Owners arrive in an explicit order; we never infer execution order from a hash.
sub compile {
  my ($owners) = @_;
  die "Owners must be an arrayref\n" unless ref($owners) eq 'ARRAY';
  my (%seen_owner, %by_key, @steps, @unique);
  for my $owner (@$owners) {
    next if $seen_owner{$owner}++;
    push @unique, $owner;
    for my $step (@{Example::Sugar::Registry::entries($owner)}) {
      my $key = $step->{key};
      die "Step key '$key' collides between $by_key{$key}{owner} and $owner\n" if exists $by_key{$key};
      $step->{ordinal} = scalar @steps;
      $by_key{$key} = $step;
      push @steps, $step;
    }
  }
  my (%indegree, %out);
  for my $step (@steps) {
    my $key = $step->{key};
    $indegree{$key} = scalar @{$step->{requires}};
    for my $dep (@{$step->{requires}}) {
      die "Unknown dependency '$dep' required by '$key'\n" unless exists $by_key{$dep};
      die "Phase inversion: '$key' requires later-phase '$dep'\n"
        if Example::Sugar::Registry::phase_rank($by_key{$dep}{phase})
          > Example::Sugar::Registry::phase_rank($step->{phase});
      push @{$out{$dep}}, $key;
    }
  }
  my @ready = grep { !$indegree{$_->{key}} } @steps;
  my @ordered;
  while (@ready) {
    @ready = sort {
      Example::Sugar::Registry::phase_rank($a->{phase}) <=> Example::Sugar::Registry::phase_rank($b->{phase})
      || $a->{ordinal} <=> $b->{ordinal}
    } @ready;
    my $step = shift @ready;
    push @ordered, $step;
    for my $key (@{$out{$step->{key}} // []}) {
      push @ready, $by_key{$key} if --$indegree{$key} == 0;
    }
  }
  die "Dependency cycle involving: " . join(', ', sort grep { $indegree{$_} } keys %indegree) . "\n"
    if @ordered != @steps;
  return { schema_version => 1, owners => \@unique, steps => \@ordered };
}
sub bind {
  my ($plan, $subject) = @_;
  my (@steps, %active);
  for my $step (@{$plan->{steps}}) {
    my $enabled = Example::Sugar::Predicate::evaluate($step->{predicate}, $subject);
    $active{$step->{key}} = $enabled;
    push @steps, { %$step, requires => [@{$step->{requires}}], active => $enabled };
  }
  # Missing active prerequisites are an error before any step body is invoked.
  for my $step (grep { $_->{active} } @steps) {
    for my $dep (@{$step->{requires}}) {
      die "Active step '$step->{key}' requires disabled step '$dep'\n" unless $active{$dep};
    }
  }
  return { %$plan, owners => [@{$plan->{owners}}], steps => \@steps,
    active_total => scalar(grep { $_->{active} } @steps) };
}
sub manifest {
  my ($plan) = @_;
  return {
    schema_version => $plan->{schema_version}, owners => [@{$plan->{owners}}],
    (exists($plan->{active_total}) ? (active_total => $plan->{active_total}) : ()),
    steps => [map { my $s = $_; +{
      (map { $_ => $s->{$_} } qw(owner index key label phase revision)),
      requires => [@{$s->{requires}}],
      predicate => Example::Sugar::Predicate::describe($s->{predicate}),
      (exists($s->{active}) ? (active => $s->{active}) : ()),
    }} @{$plan->{steps}}],
  };
}
1;
