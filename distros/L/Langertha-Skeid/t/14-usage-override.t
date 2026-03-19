use strict;
use warnings;
use Test::More;

# --- Subclass that overrides _store_usage_event with an arrayref collector ---
{
  package Langertha::Skeid::TestCollector;
  use Moo;
  extends 'Langertha::Skeid';

  has collected_events => (
    is      => 'ro',
    default => sub { [] },
  );

  sub _store_usage_event {
    my ($self, $event) = @_;
    push @{$self->collected_events}, $event;
    return { ok => 1, id => scalar(@{$self->collected_events}) };
  }
}

# --- Subclass that overrides _query_usage_report ---
{
  package Langertha::Skeid::TestReporter;
  use Moo;
  extends 'Langertha::Skeid';

  has collected_events => (
    is      => 'ro',
    default => sub { [] },
  );

  sub _store_usage_event {
    my ($self, $event) = @_;
    push @{$self->collected_events}, $event;
    return { ok => 1, id => scalar(@{$self->collected_events}) };
  }

  sub _query_usage_report {
    my ($self, $filters) = @_;
    my @events = @{$self->collected_events};
    if (defined $filters->{model} && length $filters->{model}) {
      @events = grep { ($_->{model} // '') eq $filters->{model} } @events;
    }
    return {
      ok      => 1,
      enabled => 1,
      backend => 'test',
      totals  => { requests => scalar(@events) },
    };
  }
}

# --- Test: subclass collector receives normalized events ---
my $collector = Langertha::Skeid::TestCollector->new;

my $result = $collector->call_function('usage.record', {
  api_format  => 'openai',
  endpoint    => '/v1/chat/completions',
  api_key_id  => 'k_test',
  model       => 'gpt-4o-mini',
  node_id     => 'n1',
  status_code => 200,
  ok          => 1,
  duration_ms => 42,
  metrics     => {
    usage => { input => 100, output => 25, total => 125 },
    tool_calls => 2,
    cost_total_usd => 0.001,
  },
});
ok($result->{ok}, 'override _store_usage_event: record succeeded');
is($result->{id}, 1, 'override returned custom id');
is(scalar(@{$collector->collected_events}), 1, 'one event collected');

my $ev = $collector->collected_events->[0];
is($ev->{api_key_id}, 'k_test', 'event has api_key_id');
is($ev->{model}, 'gpt-4o-mini', 'event has model');
is($ev->{input_tokens}, 100, 'event has normalized input_tokens');
is($ev->{output_tokens}, 25, 'event has normalized output_tokens');
is($ev->{total_tokens}, 125, 'event has normalized total_tokens');
is($ev->{tool_calls}, 2, 'event has tool_calls');
is($ev->{status_code}, 200, 'event has status_code');
is($ev->{ok}, 1, 'event has ok flag');
ok(length($ev->{created_at}), 'event has created_at timestamp');

# --- Test: subclass reporter receives filters ---
my $reporter = Langertha::Skeid::TestReporter->new;

$reporter->call_function('usage.record', {
  model   => 'gpt-4o-mini',
  metrics => { usage => { input => 50, output => 10, total => 60 } },
});
$reporter->call_function('usage.record', {
  model   => 'claude-3-haiku',
  metrics => { usage => { input => 80, output => 20, total => 100 } },
});

my $report_all = $reporter->call_function('usage.report', {});
ok($report_all->{ok}, 'override _query_usage_report: report succeeded');
is($report_all->{backend}, 'test', 'custom backend name');
is($report_all->{totals}{requests}, 2, 'all events reported');

my $report_filtered = $reporter->call_function('usage.report', { model => 'gpt-4o-mini' });
is($report_filtered->{totals}{requests}, 1, 'filtered report correct');

# --- Test: callback parameter (no subclass needed) ---
my @cb_events;
my $cb_skeid = Langertha::Skeid->new(
  store_usage_event => sub {
    my ($self, $event) = @_;
    push @cb_events, $event;
    return { ok => 1, id => scalar(@cb_events) };
  },
);

my $cb_result = $cb_skeid->call_function('usage.record', {
  api_format  => 'openai',
  api_key_id  => 'k_cb',
  model       => 'test-model',
  status_code => 200,
  ok          => 1,
  metrics     => { usage => { input => 50, output => 10, total => 60 } },
});
ok($cb_result->{ok}, 'callback store: record succeeded');
is(scalar(@cb_events), 1, 'callback received event');
is($cb_events[0]{api_key_id}, 'k_cb', 'callback event has api_key_id');
is($cb_events[0]{input_tokens}, 50, 'callback event has normalized tokens');

# --- Test: callback for query_usage_report ---
my $cb_report_skeid = Langertha::Skeid->new(
  query_usage_report => sub {
    my ($self, $filters) = @_;
    return {
      ok      => 1,
      enabled => 1,
      backend => 'callback',
      totals  => { requests => 99 },
      since   => ($filters->{since} // ''),
    };
  },
);

my $cb_report = $cb_report_skeid->call_function('usage.report', { since => '2025-01-01' });
ok($cb_report->{ok}, 'callback report: succeeded');
is($cb_report->{backend}, 'callback', 'callback report backend');
is($cb_report->{totals}{requests}, 99, 'callback report returns custom data');
is($cb_report->{since}, '2025-01-01', 'callback report receives filters');

done_testing;
