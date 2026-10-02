use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Langertha::Skeid;

# These probes use a ten-minute interval so the timer never fires during the test; the warning
# about an interval longer than capacity_max_age_ms (ADR 0017) is expected here and only noise.
$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /must be below capacity_max_age_ms/ };
use Langertha::Skeid::Proxy;
use Langertha::Skeid::CapacityProbe;

# Capacity probes follow the probed node set, not the inventory generation (skeid #40). The
# generation also moves on a health flip, because health is part of eligibility and the route
# cache has to drop -- but restarting every probe on a flip forgot every reading, and admission
# fell back to inflight for a node whose load had not changed at all. A probe restarts only when
# what it polls changes: a probed node added or removed, its capacity block, its URL.

my $ADMIN = { Authorization => 'Bearer adm' };

sub probed_skeid {
  my (%args) = @_;
  my $starts = $args{starts};
  my $skeid = Langertha::Skeid->new(admin_api_key => 'adm', capacity_max_age_ms => 600_000);
  for my $id (qw(p1 p2)) {
    # One callback per node, reused, so an unchanged capacity block digests alike.
    $skeid->add_node(
      id => $id, url => "http://$id/v1", model => 'm',
      capacity => { probe => 'custom', interval_ms => 600_000, code => $args{code}{$id} },
    );
  }
  return $skeid;
}

# --- health flips: no restart, readings kept ---
{
  my %polls = (p1 => 0, p2 => 0);
  my %code = map {
    my $id = $_;
    # Every poll reports a new number, so a restart (stop forgets, start polls) is visible in
    # the reading even though a restart also leaves one behind.
    ($id => sub { my ($probe) = @_; $polls{$id}++;
      $probe->skeid->set_capacity_reading($id, source => 'custom', used => $polls{$id}, limit => 8) })
  } qw(p1 p2);
  my $skeid = probed_skeid(code => \%code);
  my $t = Test::Mojo->new(Langertha::Skeid::Proxy->build_app(skeid => $skeid));
  is_deeply \%polls, { p1 => 1, p2 => 1 }, 'each probe polled once on start';

  my $generation = $skeid->_inventory_generation;
  for my $i (1 .. 10) {
    $t->post_ok('/skeid/nodes/p1/health' => $ADMIN => json => { healthy => $i % 2 ? 0 : 1 })
      ->status_is(200);
    $t->get_ok('/skeid/nodes' => $ADMIN)->status_is(200);
  }
  isnt $skeid->_inventory_generation, $generation, 'the flips did move the inventory generation';
  is_deeply \%polls, { p1 => 1, p2 => 1 }, '10 health flips restart no probe';
  is $skeid->capacity_reading('p1')->{used}, 1, 'the flipped node keeps its reading';
  is $skeid->capacity_reading('p2')->{used}, 1, 'and so does the other one';

  # Health is still honoured: the route cache dropped even though the probes did not restart.
  is $skeid->route_state(model => 'm')->{eligible_count}, 2, 'both nodes route (and the route is cached)';
  $t->post_ok('/skeid/nodes/p1/health' => $ADMIN => json => { healthy => 0 })->status_is(200);
  is $skeid->route_state(model => 'm')->{eligible_count}, 1, 'an unhealthy node leaves the cached route';
  $t->post_ok('/skeid/nodes/p1/health' => $ADMIN => json => { healthy => 1 })->status_is(200);
  is $skeid->route_state(model => 'm')->{eligible_count}, 2, 'and comes back';

  # A node without a probe changes nothing a probe polls either.
  $skeid->add_node(id => 'plain', url => 'http://plain/v1', model => 'm');
  $t->get_ok('/skeid/nodes' => $ADMIN)->status_is(200);
  is_deeply \%polls, { p1 => 1, p2 => 1 }, 'adding an unprobed node restarts no probe';

  # --- the probed node set changes: probes restart ---
  $skeid->add_node(
    id => 'p3', url => 'http://p3/v1', model => 'm',
    capacity => { probe => 'custom', interval_ms => 600_000,
      code => sub { $polls{p3}++ } },
  );
  $t->get_ok('/skeid/nodes' => $ADMIN)->status_is(200);
  is_deeply \%polls, { p1 => 2, p2 => 2, p3 => 1 }, 'adding a probed node restarts the probes once';
  $t->get_ok('/skeid/nodes' => $ADMIN)->status_is(200);
  is $polls{p1}, 2, 'and not again on the next request';

  $skeid->remove_node('p3');
  $t->get_ok('/skeid/nodes' => $ADMIN)->status_is(200);
  is_deeply \%polls, { p1 => 3, p2 => 3, p3 => 1 }, 'removing a probed node restarts the others once';
  ok !$skeid->capacity_reading('p3'), 'and the removed node has no reading';

  # Same id, different machine: a reading about the old URL must not carry over.
  $skeid->add_node(
    id => 'p2', url => 'http://p2-moved/v1', model => 'm',
    capacity => { probe => 'custom', interval_ms => 600_000, code => $code{p2} },
  );
  $t->get_ok('/skeid/nodes' => $ADMIN)->status_is(200);
  is $polls{p2}, 4, 'a probed node moved to a new URL restarts the probes';

  $skeid->worker_count(2);
  $t->get_ok('/skeid/nodes' => $ADMIN)->status_is(200);
  is $polls{p1}, 5, 'a worker count change restarts them, because it sets the poll interval';
}

# --- a stopped probe does not report from a poll still in flight ---
{
  my $release;    # the metrics answer is held until the probe has been stopped
  my $engine = Mojolicious->new;
  $engine->log->level('fatal');
  $engine->routes->get('/metrics' => sub {
    my ($c) = @_;
    $c->render_later;
    $release = sub { $c->render(text => "vllm:num_requests_running 3\n") };
  });
  my $daemon = Mojo::Server::Daemon->new(app => $engine, listen => ['http://127.0.0.1'], silent => 1);
  $daemon->start;
  my $port = $daemon->ports->[0];

  my $skeid = Langertha::Skeid->new(capacity_max_age_ms => 600_000);
  $skeid->add_node(
    id => 'gpu-1', url => "http://127.0.0.1:$port/v1", model => 'm', max_conns => 8,
    capacity => { probe => 'prometheus', url => "http://127.0.0.1:$port/metrics", interval_ms => 600_000 },
  );
  my $probe = Langertha::Skeid::CapacityProbe->for_node($skeid, $skeid->nodes->[0]);
  $probe->start;

  my $guard = Mojo::IOLoop->timer(5 => sub { Mojo::IOLoop->stop });
  my $wait = Mojo::IOLoop->recurring(0.01 => sub { Mojo::IOLoop->stop if $release });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($wait);
  ok $release, 'the poll reached the metrics endpoint';

  $probe->stop;
  $release->();
  Mojo::IOLoop->timer(0.3 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($guard);
  ok !$skeid->capacity_reading('gpu-1'),
    'the answer to a poll sent before stop is dropped, not recorded for a probe that no longer runs';
}

done_testing;
