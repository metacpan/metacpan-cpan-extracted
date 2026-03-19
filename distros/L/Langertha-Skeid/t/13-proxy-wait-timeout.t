use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use Mojo::IOLoop;
use Langertha::Skeid;
use Langertha::Skeid::Proxy;

{
  package Local::FakeController;
  sub new { bless { skeid => $_[1] }, $_[0] }
  sub skeid { $_[0]{skeid} }
  sub render {
    my ($self, %args) = @_;
    $self->{rendered} = \%args;
    return;
  }
  sub rendered { $_[0]{rendered} }
}

{
  my $skeid = Langertha::Skeid->new(
    route_wait_timeout_ms => 120,
    route_wait_poll_ms    => 20,
  );

  ok $skeid->add_node(
    id        => 'sat-1',
    url       => 'http://127.0.0.1:21001/v1',
    model     => 'qwen2.5',
    healthy   => 1,
    max_conns => 1,
  ), 'saturated test node added';
  ok $skeid->start_request('sat-1'), 'pre-saturate node';

  my $c = Local::FakeController->new($skeid);
  my $start = time;
  my @res = Langertha::Skeid::Proxy::_begin_route($c, 'qwen2.5');
  my $elapsed_ms = int((time - $start) * 1000);

  is scalar(@res), 0, 'no route returned when saturated';
  is $c->rendered->{status}, 429, 'returns 429 after timeout';
  ok $elapsed_ms >= 100, "waited before 429 ($elapsed_ms ms)";

  $skeid->finish_request('sat-1', ok => 1);
}

{
  my $skeid = Langertha::Skeid->new(
    route_wait_timeout_ms => 200,
    route_wait_poll_ms    => 20,
  );
  my $c = Local::FakeController->new($skeid);

  my $start = time;
  my @res = Langertha::Skeid::Proxy::_begin_route($c, 'unknown-model');
  my $elapsed_ms = int((time - $start) * 1000);

  is scalar(@res), 0, 'no route returned for unknown model';
  is $c->rendered->{status}, 503, 'returns 503 for model-not-found';
  ok $elapsed_ms < 100, "fails fast for model-not-found ($elapsed_ms ms)";
}

{
  my $skeid = Langertha::Skeid->new(
    route_wait_timeout_ms => 220,
    route_wait_poll_ms    => 20,
  );

  ok $skeid->add_node(
    id        => 'async-1',
    url       => 'http://127.0.0.1:21002/v1',
    model     => 'qwen2.5',
    healthy   => 1,
    max_conns => 1,
  ), 'async test node added';
  ok $skeid->start_request('async-1'), 'pre-saturate async node';

  my $c = Local::FakeController->new($skeid);
  my ($route, $node_id, $done);
  my $start = time;

  Mojo::IOLoop->timer(0.06 => sub {
    $skeid->finish_request('async-1', ok => 1);
  });

  Mojo::IOLoop->timer(0.5 => sub {
    Mojo::IOLoop->stop if Mojo::IOLoop->is_running;
  });

  Langertha::Skeid::Proxy::_begin_route_async($c, 'qwen2.5', sub {
    ($route, $node_id) = @_;
    $done = 1;
    Mojo::IOLoop->stop if Mojo::IOLoop->is_running;
  });

  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
  my $elapsed_ms = int((time - $start) * 1000);

  ok $done, 'async callback executed';
  ok ref($route) eq 'HASH', 'async route eventually acquired';
  is $node_id, 'async-1', 'async route picked expected node';
  ok $elapsed_ms >= 50, "async wait respected saturation window ($elapsed_ms ms)";
  ok !$c->rendered, 'no error rendered for async acquisition';

  $skeid->finish_request($node_id, ok => 1) if defined $node_id && length $node_id;
}

done_testing;
