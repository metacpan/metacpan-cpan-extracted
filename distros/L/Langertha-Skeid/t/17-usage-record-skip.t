use strict;
use warnings;
use Test::More;

# record_usage runs once per forwarded request. When nothing can store the
# event, building the normalized event is wasted work, so record_usage skips it
# and returns the not-configured result straight away (karr #15).
#
# The subtlety this file pins down: "no sink" is not just "no usage_store and no
# store_usage_event callback". A subclass that overrides _store_usage_event is a
# sink too (README documents it, t/14 relies on it), so the skip must not
# swallow that case. A naive `return unless has_store_usage_event ||
# _usage_store_obj` guard would silently drop every event such a subclass meant
# to collect -- these tests fail loudly if the guard regresses to that.

use Langertha::Skeid;

# --- No sink at all: skip and report not-configured ---
{
  my $skeid = Langertha::Skeid->new;
  my $rec = $skeid->call_function('usage.record', {
    model   => 'm',
    metrics => { usage => { input => 10, output => 5, total => 15 } },
  });
  ok(!$rec->{ok}, 'no sink: record_usage returns not-ok');
  like($rec->{error}, qr/not configured/, 'no sink: says not configured');
}

# --- A store_usage_event callback IS a sink: do NOT skip ---
{
  my @events;
  my $skeid = Langertha::Skeid->new(
    store_usage_event => sub {
      my ($self, $event) = @_;
      push @events, $event;
      return { ok => 1, id => scalar(@events) };
    },
  );
  my $rec = $skeid->call_function('usage.record', {
    model   => 'm',
    metrics => { usage => { input => 10, output => 5, total => 15 } },
  });
  ok($rec->{ok}, 'callback sink: record_usage still records');
  is(scalar(@events), 1, 'callback sink: the event was built and delivered');
  is($events[0]{input_tokens}, 10, 'callback sink: event is the normalized one, not skipped');
}

# --- A subclass overriding _store_usage_event IS a sink: do NOT skip ---
{
  package Langertha::Skeid::SkipTestCollector;
  use Moo;
  extends 'Langertha::Skeid';
  has collected => (is => 'ro', default => sub { [] });
  sub _store_usage_event {
    my ($self, $event) = @_;
    push @{$self->collected}, $event;
    return { ok => 1, id => scalar(@{$self->collected}) };
  }
}

{
  # No usage_store, no store_usage_event callback -- the override is the only sink.
  my $skeid = Langertha::Skeid::SkipTestCollector->new;
  my $rec = $skeid->call_function('usage.record', {
    model   => 'm',
    metrics => { usage => { input => 7, output => 3, total => 10 } },
  });
  ok($rec->{ok}, 'override sink: record_usage does not skip a _store_usage_event override');
  is(scalar(@{$skeid->collected}), 1, 'override sink: the event reached the override');
  is($skeid->collected->[0]{output_tokens}, 3, 'override sink: event was built, not skipped');
}

done_testing;
