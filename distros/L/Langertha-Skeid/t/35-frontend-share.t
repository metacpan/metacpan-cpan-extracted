use strict;
use warnings;
use Test::More;
use Langertha::Skeid;

# Multiple Skeid FRONTENDS in front of one node, no probe (ADR 0009, ADR 0012). Each frontend is
# a separate process on a separate host, so nothing can count the others' inflight -- the
# operator declares how many there are (frontend_count) and each takes its share of max_conns.
# Same arithmetic and warning as worker_count (ADR 0010), and the two compose: max_conns is
# partitioned across frontends first, then across this process's prefork workers.

# --- default: no divisor, today's behaviour unchanged ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'n1', url => 'http://x/v1', model => 'm', max_conns => 8);
  my $node = $skeid->nodes->[0];

  is $skeid->frontend_count, 1, 'one frontend by default -- an existing deployment is unchanged';
  is $skeid->worker_max_conns($node), 8, 'and it gets the whole allowance';
  is_deeply $skeid->worker_share_warnings, [], 'nothing to warn about';
}

# --- a frontend divisor partitions max_conns, same as worker_count ---
{
  my $skeid = Langertha::Skeid->new;
  $skeid->add_node(id => 'n1', url => 'http://x/v1', model => 'm', max_conns => 8);
  my $node = $skeid->nodes->[0];

  $skeid->frontend_count(2);
  is $skeid->worker_max_conns($node), 4, 'two frontends take half each';
  is_deeply $skeid->worker_share_warnings, [], 'which divides cleanly, so nothing to say';

  $skeid->frontend_count(3);
  is $skeid->worker_max_conns($node), 2,
    'an uneven split rounds down: the group of frontends must never exceed what was configured';

  $skeid->add_node(id => 'unlimited', url => 'http://x/v1', model => 'm', max_conns => 0);
  is $skeid->worker_max_conns($skeid->nodes->[-1]), 0, 'unlimited stays unlimited';
}

# --- what cannot be honoured has to be said out loud at startup ---
{
  my $skeid = Langertha::Skeid->new(frontend_count => 4);
  $skeid->add_node(id => 'tiny', url => 'http://x/v1', model => 'm', max_conns => 2);

  is $skeid->worker_max_conns($skeid->nodes->[0]), 1,
    'a frontend that may admit nothing is a frontend that does nothing, so the floor is 1';

  my $warnings = $skeid->worker_share_warnings;
  is scalar(@$warnings), 1, 'and max_conns below the frontend count produces a warning';
  like $warnings->[0], qr/tiny/, 'naming the node';
  like $warnings->[0], qr/frontend/, 'saying it is the frontends the split cannot honour';
  like $warnings->[0], qr/\b4\b/, 'and what the node will actually see across the group';
  like $warnings->[0], qr/max_conns/, 'pointing at raising max_conns as a fix';
}

# --- admission actually uses the frontend share ---
{
  my $skeid = Langertha::Skeid->new(frontend_count => 4);
  $skeid->add_node(id => 'n1', url => 'http://x/v1', model => 'm', max_conns => 8, healthy => 1);

  ok $skeid->start_request('n1'), 'first request admitted';
  ok $skeid->start_request('n1'), 'second admitted';
  is $skeid->start_request('n1'), 0,
    'third refused at this frontend\'s share of 2, not at the configured 8 -- the other three '
    . 'frontends hold the rest';
  $skeid->finish_request('n1', ok => 1) for 1 .. 2;
  is $skeid->node_metrics('n1')->{inflight}, 0, 'no leak';
}

# --- the two divisors compose: first frontends, then workers ---
{
  my $skeid = Langertha::Skeid->new(frontend_count => 2, worker_count => 2);
  $skeid->add_node(id => 'gpu', url => 'http://x/v1', model => 'm', max_conns => 8, healthy => 1);
  my $node = $skeid->nodes->[0];

  is $skeid->worker_max_conns($node), 2,
    'max_conns 8 across 2 frontends x 2 workers = 4 processes, so 2 each';

  ok $skeid->start_request('gpu'), 'first admitted';
  ok $skeid->start_request('gpu'), 'second admitted';
  is $skeid->start_request('gpu'), 0, 'third refused at the combined share of 2';
  $skeid->finish_request('gpu', ok => 1) for 1 .. 2;

  # The combined divisor is what the warning reports, too.
  $skeid->remove_node('gpu');
  $skeid->add_node(id => 'tiny', url => 'http://x/v1', model => 'm', max_conns => 3, healthy => 1);
  my $warnings = $skeid->worker_share_warnings;
  is scalar(@$warnings), 1, 'max_conns 3 under 2 x 2 = 4 processes cannot be honoured';
  like $warnings->[0], qr/frontend/, 'and the message names the frontends';
  like $warnings->[0], qr/worker/,   'and the workers';
  like $warnings->[0], qr/\b4\b/,    'and the combined process count the node will see';
}

# --- composition equals a single combined divisor, floor and all ---
{
  # floor(floor(max/F)/N) == floor(max/(F*N)): partitioning across frontends then workers gives
  # the same share as one combined divisor, so neither order over- nor under-admits.
  for my $case (
    [12, 3, 2, 2],   # 12 / (3*2) = 2
    [10, 2, 3, 1],   # 10 / 6     = 1
    [7,  1, 4, 1],   # 7  / 4     = 1, floored, min 1
    [24, 2, 4, 3],   # 24 / 8     = 3
  ) {
    my ($max, $f, $w, $want) = @$case;
    my $skeid = Langertha::Skeid->new(frontend_count => $f, worker_count => $w);
    $skeid->add_node(id => 'n', url => 'http://x/v1', model => 'm', max_conns => $max);
    is $skeid->worker_max_conns($skeid->nodes->[0]), $want,
      "max_conns $max across $f frontends x $w workers = $want per process";
  }
}

# --- frontend_count comes from config, and follows a reload ---
{
  my $frontends = 2;
  my $skeid = Langertha::Skeid->new(
    config_reload_interval => 0,   # every dispatch re-reads the loader here
    config_loader => sub {
      return {
        routing => { frontend_count => $frontends },
        nodes   => [ { id => 'n1', url => 'http://x/v1', model => 'm', max_conns => 8, healthy => 1 } ],
      };
    },
  );

  is $skeid->frontend_count, 2, 'routing.frontend_count is read from config at load';
  is $skeid->worker_max_conns($skeid->nodes->[0]), 4, 'and drives the share';

  $frontends = 4;
  $skeid->call_function('nodes.list', {});
  is $skeid->frontend_count, 4, 'a reload picks up a changed frontend_count';
  is $skeid->worker_max_conns($skeid->nodes->[0]), 2, 'and the share follows it';

  $frontends = 0;
  $skeid->call_function('nodes.list', {});
  is $skeid->frontend_count, 1, 'a nonsensical count floors to one frontend, not zero';
}

done_testing;
