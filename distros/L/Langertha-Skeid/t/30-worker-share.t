use strict;
use warnings;
use Test::More;
use Langertha::Skeid;
use Langertha::Skeid::CapacityProbe;
use Langertha::Skeid::CapacityProbe::Custom;

# Workers and admission (ADR 0010). inflight and max_conns are per-process, so N workers would
# each admit up to max_conns to a node that can only serve one number -- max_conns 8 across 4
# workers permits 32, silently. Each worker takes its share instead.

# --- the arithmetic ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'n1', url => 'http://x/v1', model => 'm', max_conns => 8);
  my $node = $skeid->nodes->[0];

  is $skeid->worker_count, 1, 'one worker by default -- an existing deployment is unchanged';
  is $skeid->worker_max_conns($node), 8, 'and it gets the whole allowance';

  $skeid->worker_count(4);
  is $skeid->worker_max_conns($node), 2, 'four workers take a quarter each';
  is_deeply $skeid->worker_share_warnings, [], 'which divides cleanly, so nothing to say';

  $skeid->worker_count(3);
  is $skeid->worker_max_conns($node), 2,
    'an uneven split rounds down: the group must never exceed what was configured, and idle '
    . 'capacity is cheaper than a queued GPU';

  $skeid->add_node(id => 'unlimited', url => 'http://x/v1', model => 'm', max_conns => 0);
  is $skeid->worker_max_conns($skeid->nodes->[-1]), 0, 'unlimited stays unlimited';
}

# --- what cannot be honoured has to be said out loud ---
{
  my $skeid = Langertha::Skeid->new(worker_count => 4);
  $skeid->add_node(id => 'tiny', url => 'http://x/v1', model => 'm', max_conns => 2);

  is $skeid->worker_max_conns($skeid->nodes->[0]), 1,
    'a worker that may admit nothing is a worker that does nothing, so the floor is 1';

  my $warnings = $skeid->worker_share_warnings;
  is scalar(@$warnings), 1, 'and max_conns below the worker count produces a warning';
  like $warnings->[0], qr/tiny/, 'naming the node';
  like $warnings->[0], qr/\b4\b/, 'and what the node will actually see';
  like $warnings->[0], qr/fewer workers or raise max_conns/,
    'with the only two fixes, because only the operator can choose between them';
}

# --- admission actually uses the share ---
{
  my $skeid = Langertha::Skeid->new(worker_count => 4);
  $skeid->add_node(id => 'n1', url => 'http://x/v1', model => 'm', max_conns => 8, healthy => 1);

  ok $skeid->start_request('n1'), 'first request admitted';
  ok $skeid->start_request('n1'), 'second admitted';
  is $skeid->start_request('n1'), 0,
    'third refused at this worker\'s share of 2, not at the configured 8 -- the other three '
    . 'workers hold the rest';
  is $skeid->route_state(model => 'm')->{has_available}, 0, 'and the node reads as unavailable here';
  is $skeid->route_state(model => 'm')->{has_eligible}, 1, 'while staying eligible';

  $skeid->finish_request('n1', ok => 1);
  ok $skeid->start_request('n1'), 'a finish frees a slot again';
  $skeid->finish_request('n1', ok => 1) for 1 .. 2;
  is $skeid->node_metrics('n1')->{inflight}, 0, 'no leak';
}

# --- a probe still only narrows, and is not divided ---
{
  # A probe reads the node itself, so it already includes the other workers' traffic. Dividing
  # it too would count them twice.
  my $skeid = Langertha::Skeid->new(worker_count => 4, capacity_max_age_ms => 60_000);
  $skeid->add_node(id => 'gpu', url => 'http://x/v1', model => 'm', max_conns => 32, healthy => 1);

  $skeid->set_capacity_reading('gpu', used => 4, limit => 32, source => 'prometheus');
  is $skeid->route_state(model => 'm')->{has_available}, 1, 'room on the node, room in the share';

  $skeid->set_capacity_reading('gpu', used => 32, limit => 32, source => 'prometheus');
  is $skeid->route_state(model => 'm')->{has_available}, 0,
    'a full node blocks every worker at once, which is the case per-process counting gets wrong';

  $skeid->set_capacity_reading('gpu', used => 0, limit => 32, source => 'prometheus');
  $skeid->start_request('gpu') for 1 .. 8;
  is $skeid->node_metrics('gpu')->{inflight}, 8, 'this worker admitted its share of 32/4';
  is $skeid->start_request('gpu'), 0,
    'and no more, however empty the node reports -- a probe narrows the share, never widens it';
  $skeid->finish_request('gpu', ok => 1) for 1 .. 8;
}

# --- background work is spread, so the node sees the configured rate from the group ---
{
  my $skeid = Langertha::Skeid->new(worker_count => 4);
  $skeid->add_node(id => 'gpu', url => 'http://x:8000/v1', model => 'm',
    capacity => { probe => 'custom', interval_ms => 2000, code => sub { } });

  my $probe = Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[0]);
  is $probe->interval_ms, 2000, 'the configured interval is what the operator wrote';
  is $probe->poll_interval_seconds, 8,
    'but each of four workers polls every 8s, so the node still sees one poll per 2s. Without '
    . 'this the metrics endpoint is hit every 500ms and the probe becomes the load it measures';

  $skeid->worker_count(1);
  is $probe->poll_interval_seconds, 2, 'one worker polls at the configured rate';

  # A very short interval must not become a busy loop just because someone typed a small number.
  $skeid->worker_count(1);
  my $fast = Langertha::Skeid::CapacityProbe::Custom->new(
    skeid => $skeid, node_id => 'gpu', interval_ms => 1, code => sub { });
  is $fast->poll_interval_seconds, 0.1, 'and there is a floor';
}

done_testing;
