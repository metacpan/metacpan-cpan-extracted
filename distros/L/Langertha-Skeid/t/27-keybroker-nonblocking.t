use strict;
use warnings;
use Test::More;
use Mojolicious;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Time::HiRes qw(time);
use Langertha::Skeid;
use Langertha::Skeid::KeyBroker;
use Langertha::Skeid::Proxy;

# Key resolution sits between routing and the upstream call, and it can mean a round-trip to a
# vault. Done synchronously it stalls the whole process for that round-trip -- invisible in a
# single-request test, and the reason karr #3 existed (ADR 0005).
#
# The proof is not a timing comparison, which would be a coin flip on a loaded box: while one
# request's key is still being resolved, the process must still be answering other requests.
# A blocking resolve cannot pass this, because nothing else runs at all until it returns.

{
  package HoldingBroker;
  use Moo;
  extends 'Langertha::Skeid::KeyBroker';
  # Never answers on its own -- the test decides when the vault replies.
  has held    => (is => 'ro', default => sub { [] });
  has on_hold => (is => 'rw', default => sub { sub { } });
  sub resolve_key { die 'the request path must not call the blocking resolve_key' }
  sub resolve_key_async {
    my ($self, $ref, $cb) = @_;
    push @{$self->held}, $cb;
    $self->on_hold->($self);
    return;
  }
  sub release {
    my ($self, $key) = @_;
    my @cbs = splice @{$self->held};
    $_->($key, undef) for @cbs;
    return scalar @cbs;
  }
}

my $upstream = Mojolicious->new;
$upstream->log->level('fatal');
my $seen_auth;
$upstream->routes->post('/v1/chat/completions' => sub {
  my ($c) = @_;
  $seen_auth = $c->req->headers->authorization;
  $c->render(json => {
    id      => 'chatcmpl-1',
    object  => 'chat.completion',
    model   => 'm1',
    choices => [{ index => 0, message => { role => 'assistant', content => 'ok' }, finish_reason => 'stop' }],
    usage   => { prompt_tokens => 1, completion_tokens => 1, total_tokens => 2 },
  });
});
my $upstream_daemon = Mojo::Server::Daemon->new(app => $upstream, listen => ['http://127.0.0.1'], silent => 1);
$upstream_daemon->start;
my $upstream_port = $upstream_daemon->ports->[0];

my $broker = HoldingBroker->new;
my $skeid = Langertha::Skeid->new(key_broker => $broker);
$skeid->add_node(
  id          => 'n1',
  url         => "http://127.0.0.1:$upstream_port/v1",
  model       => 'm1',
  api_key_ref => 'secret/skeid/remote/test',
  max_conns   => 4,
);

my $proxy = Langertha::Skeid::Proxy->build_app(skeid => $skeid);
$proxy->log->level('fatal');
my $proxy_daemon = Mojo::Server::Daemon->new(app => $proxy, listen => ['http://127.0.0.1'], silent => 1);
$proxy_daemon->start;
my $proxy_port = $proxy_daemon->ports->[0];

my $ua = Mojo::UserAgent->new;
my $base = "http://127.0.0.1:$proxy_port";

my ($chat_tx, $health_tx);
my $health_answered_while_held = 0;

# When the broker is asked, the key is not available yet -- exactly the cold-cache case. While
# that is outstanding, ask the proxy for something else.
$broker->on_hold(sub {
  my ($b) = @_;
  $ua->get("$base/health" => sub {
    my (undef, $tx) = @_;
    $health_tx = $tx;
    $health_answered_while_held = scalar(@{$b->held}) ? 1 : 0;
    $b->release('sk-test-vault-key');
  });
});

my $guard = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
$ua->post("$base/v1/chat/completions" => json => {
  model    => 'm1',
  messages => [{ role => 'user', content => 'hi' }],
} => sub {
  (undef, $chat_tx) = @_;
  Mojo::IOLoop->stop;
});
Mojo::IOLoop->start;
Mojo::IOLoop->remove($guard);

ok $health_tx, 'the proxy answered a second request while a key resolution was outstanding';
is(($health_tx ? $health_tx->res->code : 0), 200, 'and answered it correctly');
ok $health_answered_while_held,
  'the first request really was still waiting on its key at that moment -- so the process was '
  . 'serving other traffic during the vault round-trip, not stalled in it';

ok $chat_tx, 'the held request completed once the key arrived';
is(($chat_tx ? $chat_tx->res->code : 0), 200, 'with a 200');
is $seen_auth, 'Bearer sk-test-vault-key', 'and the upstream got the resolved key';

# The second request takes the cached key, so a warm proxy never asks the vault at all.
{
  my $before = scalar @{$broker->held};
  my $done;
  my $g = Mojo::IOLoop->timer(10 => sub { Mojo::IOLoop->stop });
  $ua->post("$base/v1/chat/completions" => json => {
    model    => 'm1',
    messages => [{ role => 'user', content => 'again' }],
  } => sub { $done = $_[1]; Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($g);

  is(($done ? $done->res->code : 0), 200, 'a second request succeeds');
  is scalar(@{$broker->held}), $before,
    'without asking the broker again -- the cache is what keeps the round-trip off the request path';
  is $seen_auth, 'Bearer sk-test-vault-key', 'and still sends the right key';
}

is $skeid->node_metrics('n1')->{inflight}, 0, 'no admission leaked';

done_testing;
